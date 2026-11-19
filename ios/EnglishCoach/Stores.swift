import Foundation
import Combine
import UIKit
import AVFoundation

enum TranslationError: LocalizedError {
    case serviceUnavailable
    case network(String)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "在线翻译服务暂时不可用，请检查网络后重试。"
        case .network(let message):
            return message
        }
    }
}

final class TranslationService {
    static let shared = TranslationService()

    private let session: URLSession
    private var cache: [String: String] = [:]
    private let lock = NSLock()
    private let writeQueue = DispatchQueue(label: "com.englishcoach.translation-cache")
    private let cacheURL: URL

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 40
        session = URLSession(configuration: configuration)

        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = directory.appendingPathComponent("translation-cache.json")

        if let data = try? Data(contentsOf: cacheURL),
           let stored = try? JSONDecoder().decode([String: String].self, from: data) {
            cache = stored
        }
    }

    func translate(_ text: String, from source: String = "en", to target: String = "zh-CN") async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let hit = cached(trimmed) { return hit }

        let translated: String
        do {
            translated = try await google(trimmed, from: source, to: target)
        } catch {
            translated = try await myMemory(trimmed, from: source, to: target)
        }

        let result = translated.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw TranslationError.serviceUnavailable }
        store(trimmed, result)
        return result
    }

    func translateWord(_ word: String) async throws -> String {
        let result = try await translate(word)
        return result.trimmingCharacters(in: CharacterSet(charactersIn: "。."))
    }

    func translateParagraph(_ paragraph: String) async throws -> String {
        let chunks = Self.chunk(paragraph, limit: 900)
        var parts: [String] = []
        for chunk in chunks {
            parts.append(try await translate(chunk))
        }
        return parts.joined(separator: " ")
    }

    static func chunk(_ text: String, limit: Int) -> [String] {
        let sentences = TextProcessing.sentences(in: text)
        var chunks: [String] = []
        var current = ""

        for sentence in sentences {
            if current.isEmpty {
                current = sentence
            } else if current.count + sentence.count + 1 <= limit {
                current += " " + sentence
            } else {
                chunks.append(current)
                current = sentence
            }

            while current.count > limit {
                let head = String(current.prefix(limit))
                chunks.append(head)
                current = String(current.dropFirst(limit))
            }
        }

        if !current.isEmpty { chunks.append(current) }
        return chunks.isEmpty ? [text] : chunks
    }

    private func google(_ text: String, from source: String, to target: String) async throws -> String {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: source),
            URLQueryItem(name: "tl", value: target),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]
        guard let url = components?.url else { throw TranslationError.serviceUnavailable }

        let (data, response) = try await session.data(from: url)
        try Self.validate(response)

        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [Any],
              let segments = root.first as? [Any] else {
            throw TranslationError.serviceUnavailable
        }

        var output = ""
        for segment in segments {
            guard let parts = segment as? [Any], let piece = parts.first as? String else { continue }
            output += piece
        }
        guard !output.isEmpty else { throw TranslationError.serviceUnavailable }
        return output
    }

    private func myMemory(_ text: String, from source: String, to target: String) async throws -> String {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: String(text.prefix(480))),
            URLQueryItem(name: "langpair", value: "\(source)|\(target)")
        ]
        guard let url = components?.url else { throw TranslationError.serviceUnavailable }

        let (data, response) = try await session.data(from: url)
        try Self.validate(response)

        struct Payload: Decodable {
            struct Body: Decodable { let translatedText: String }
            let responseData: Body
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        let result = Self.decodeEntities(payload.responseData.translatedText)
        guard !result.isEmpty else { throw TranslationError.serviceUnavailable }
        return result
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.serviceUnavailable
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TranslationError.network("翻译服务返回错误（\(http.statusCode)），请稍后重试。")
        }
    }

    private static func decodeEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    private func cached(_ key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }

    private func store(_ key: String, _ value: String) {
        lock.lock()
        cache[key] = value
        let snapshot = cache
        lock.unlock()

        let url = cacheURL
        writeQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}

@MainActor
final class ArticleStore: ObservableObject {
    static let shared = ArticleStore()

    @Published private(set) var articles: [Article] = []

    private let storageURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = directory.appendingPathComponent("articles.json")
        load()
        ensureBankSamples()
        loadExamBank()
    }

    var personalArticles: [Article] {
        articles.filter { !$0.bank }
    }

    func article(withID id: UUID) -> Article? {
        articles.first { $0.id == id }
    }

    @discardableResult
    func add(title: String, content: String, bank: Bool = false, level: String = "") -> Article {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let article = Article(
            title: trimmedTitle.isEmpty ? Self.defaultTitle(for: trimmedContent) : trimmedTitle,
            content: trimmedContent,
            bank: bank,
            kind: bank ? "imported" : "article",
            level: level
        )
        articles.insert(article, at: 0)
        save()
        return article
    }

    func update(_ article: Article) {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        articles[index] = article
        save()
    }

    func delete(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        save()
    }

    private static func defaultTitle(for content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces) ?? "未命名文章"
        let title = firstLine.isEmpty ? "未命名文章" : firstLine
        return title.count > 28 ? String(title.prefix(28)) + "…" : title
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Article].self, from: data) else {
            return
        }
        articles = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        let persistable = articles.filter { $0.kind != "exam" }
        guard let data = try? JSONEncoder().encode(persistable) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func ensureBankSamples() {
        var changed = false
        for sample in QuestionBank.sampleArticles {
            if let index = articles.firstIndex(where: { $0.id == sample.id }) {
                if articles[index].content.isEmpty,
                   let content = QuestionBank.sampleContent(for: sample.id) {
                    articles[index].content = content
                    changed = true
                }
            } else {
                var article = sample
                article.content = QuestionBank.sampleContent(for: sample.id) ?? ""
                articles.append(article)
                changed = true
            }
        }
        if changed {
            articles.sort { $0.createdAt > $1.createdAt }
            save()
        }
    }

    private func loadExamBank() {
        var titles = Set(articles.map { $0.title })
        for level in ["cet4", "cet6"] {
            guard let url = Bundle.main.url(forResource: "bank-\(level)", withExtension: "json")
                    ?? Bundle.main.url(forResource: "bank-\(level)", withExtension: "json", subdirectory: "Resources"),
                  let data = try? Data(contentsOf: url),
                  let papers = try? JSONDecoder().decode([ExamPaper].self, from: data) else {
                continue
            }
            for paper in papers {
                guard !titles.contains(paper.title) else { continue }
                titles.insert(paper.title)
                articles.append(Article(
                    title: paper.title,
                    content: paper.content,
                    createdAt: Date(),
                    bank: true,
                    kind: "exam",
                    level: paper.level,
                    answers: paper.answers
                ))
            }
        }
        articles.sort { $0.createdAt > $1.createdAt }
    }
}

@MainActor
final class DictionaryStore: ObservableObject {
    static let shared = DictionaryStore()

    @Published private(set) var entriesByLevel: [VocabularyLevel: [WordEntry]] = [:]

    private var index: [String: [WordEntry]] = [:]

    private init() {
        load()
    }

    private func load() {
        for level in VocabularyLevel.allCases {
            let entries = Self.loadEntries(for: level)
            entriesByLevel[level] = entries
            for entry in entries {
                index[entry.normalizedWord, default: []].append(entry)
            }
        }
    }

    private static func resourceURL(for fileName: String) -> URL? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "txt") {
            return url
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "txt", subdirectory: "Resources") {
            return url
        }
        return Bundle.main.url(forResource: fileName, withExtension: "txt", subdirectory: "EnglishCoach")
    }

    private static func loadEntries(for level: VocabularyLevel) -> [WordEntry] {
        guard let url = resourceURL(for: level.fileName),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        var entries: [WordEntry] = []
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine
                .replacingOccurrences(of: "\u{FEFF}", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.components(separatedBy: "|").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard fields.count >= 2, !fields[0].isEmpty else { continue }

            let word = fields[0]
            let phonetic = fields.count >= 3 ? fields[1] : ""
            let meaning = fields.count >= 3 ? fields[2] : fields[1]
            entries.append(WordEntry(word: word, phonetic: phonetic, meaning: meaning, level: level))
        }

        return entries.sorted { $0.word.lowercased() < $1.word.lowercased() }
    }

    func words(for level: VocabularyLevel) -> [WordEntry] {
        entriesByLevel[level] ?? []
    }

    func entries(for word: String) -> [WordEntry] {
        let key = TextProcessing.normalize(word)
        if let direct = index[key], !direct.isEmpty { return direct }
        for base in TextProcessing.baseForms(for: key) {
            if let hits = index[base], !hits.isEmpty { return hits }
        }
        return []
    }

    func isVerbWord(_ word: String) -> Bool {
        let entries = self.entries(for: word)
        return entries.contains { $0.meaning.range(of: "(^|\\s)v\\.", options: .regularExpression) != nil }
    }

    func lookup(_ word: String) async -> WordLookupResult {
        let normalized = TextProcessing.normalize(word)
        let local = entries(for: normalized)

        if !local.isEmpty {
            let primary = local[0]
            return WordLookupResult(
                word: primary.word,
                phonetic: primary.phonetic.isEmpty ? nil : primary.phonetic,
                meanings: local.map { entry in
                    entry.level == primary.level
                        ? entry.meaning
                        : "\(entry.level.shortTitle)：\(entry.meaning)"
                },
                source: "内置四六级词典"
            )
        }

        do {
            let translated = try await TranslationService.shared.translateWord(word)
            return WordLookupResult(
                word: normalized,
                phonetic: nil,
                meanings: [translated],
                source: "在线翻译"
            )
        } catch {
            return WordLookupResult(
                word: normalized,
                phonetic: nil,
                meanings: ["未在四六级词库中找到，在线翻译也暂时不可用。请检查网络连接后重试。"],
                source: "查询失败"
            )
        }
    }
}

@MainActor
final class FavoriteStore: ObservableObject {
    static let shared = FavoriteStore()

    @Published private(set) var items: [FavoriteItem] = []

    private let storageURL: URL
    private let legacyURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = directory.appendingPathComponent("favorites.json")
        legacyURL = directory.appendingPathComponent("wordbook.json")
        load()
        migrateLegacyIfNeeded()
    }

    func isFavorited(_ type: FavoriteType, text: String) -> Bool {
        let target = compareKey(type, text)
        return items.contains { compareKey($0.type, $0.text) == target }
    }

    func add(_ item: FavoriteItem) {
        guard !isFavorited(item.type, text: item.text) else { return }
        items.insert(item, at: 0)
        save()
    }

    func addWord(word: String, meaning: String, phonetic: String) {
        add(FavoriteItem(type: .word, text: word, translation: meaning, phonetic: phonetic))
    }

    func addSentence(text: String, translation: String, analysis: SentenceAnalysis?) {
        add(FavoriteItem(type: .sentence, text: text, translation: translation, analysis: analysis))
    }

    func toggleWord(word: String, meaning: String, phonetic: String) {
        let target = TextProcessing.normalize(word)
        if let index = items.firstIndex(where: { $0.type == .word && TextProcessing.normalize($0.text) == target }) {
            items.remove(at: index)
            save()
        } else {
            addWord(word: word, meaning: meaning, phonetic: phonetic)
        }
    }

    func toggleSentence(text: String, translation: String, analysis: SentenceAnalysis?) {
        let target = compareKey(.sentence, text)
        if let index = items.firstIndex(where: { compareKey($0.type, $0.text) == target }) {
            items.remove(at: index)
            save()
        } else {
            addSentence(text: text, translation: translation, analysis: analysis)
        }
    }

    func remove(_ item: FavoriteItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func filtered(_ query: String) -> [FavoriteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.text.lowercased().contains(trimmed) || $0.translation.lowercased().contains(trimmed)
        }
    }

    func wordCount() -> Int {
        items.filter { $0.type == .word }.count
    }

    func sentenceCount() -> Int {
        items.filter { $0.type == .sentence }.count
    }

    private func compareKey(_ type: FavoriteType, _ text: String) -> String {
        type == .word ? TextProcessing.normalize(text) : text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            return
        }
        items = decoded
    }

    private func migrateLegacyIfNeeded() {
        guard items.isEmpty,
              let data = try? Data(contentsOf: legacyURL) else { return }

        struct LegacyWord: Codable {
            var id: UUID
            var word: String
            var meaning: String
            var phonetic: String?
            var addedAt: Date
        }

        guard let legacy = try? JSONDecoder().decode([LegacyWord].self, from: data) else { return }
        items = legacy.map {
            FavoriteItem(
                id: $0.id,
                type: .word,
                text: $0.word,
                translation: $0.meaning,
                phonetic: $0.phonetic ?? "",
                addedAt: $0.addedAt
            )
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

struct SkinConfig: Codable, Hashable {
    var fileName: String
    var opacity: Double
    var brightness: Double? = nil
}

struct LaunchConfig: Codable, Hashable {
    var fileName: String?
    var originalType: String
    var size: Double
    var fit: String
    var duration: Double
    var enabled: Bool

    static let defaultConfig = LaunchConfig(
        fileName: nil,
        originalType: "",
        size: 60,
        fit: "contain",
        duration: 2.2,
        enabled: true
    )
}

struct IconConfig: Codable, Hashable {
    var type: String
    var style: String
    var fileName: String?

    static let defaultConfig = IconConfig(type: "builtin", style: "blue", fileName: nil)
}

struct AppearanceConfig: Codable {
    var wallpaperFileName: String?
    var wallpaperOpacity: Double
    var skins: [String: SkinConfig]
    var launch: LaunchConfig
    var icon: IconConfig?

    static let defaultConfig = AppearanceConfig(
        wallpaperFileName: nil,
        wallpaperOpacity: 0.3,
        skins: [:],
        launch: .defaultConfig,
        icon: nil
    )
}

@MainActor
final class AppearanceStore: ObservableObject {
    static let shared = AppearanceStore()

    @Published private(set) var config: AppearanceConfig
    @Published var isEditing = false
    @Published var editingSkinKey: String?
    @Published var launchPreviewToken = 0

    private let directory: URL
    private let configURL: URL
    private var imageCache: [String: UIImage] = [:]

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Appearance", isDirectory: true)
        configURL = directory.appendingPathComponent("appearance.json")

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        if let data = try? Data(contentsOf: configURL),
           let decoded = try? JSONDecoder().decode(AppearanceConfig.self, from: data) {
            config = decoded
        } else {
            config = .defaultConfig
        }
    }

    var wallpaperImage: UIImage? {
        image(named: config.wallpaperFileName)
    }

    var wallpaperOpacity: Double {
        config.wallpaperOpacity
    }

    var iconConfig: IconConfig {
        config.icon ?? .defaultConfig
    }

    var iconImage: UIImage? {
        image(named: iconConfig.fileName)
    }

    func currentIcon(size: CGFloat) -> UIImage {
        IconRenderer.render(style: iconConfig.style, image: iconImage, size: size)
    }

    func setIconStyle(_ style: String) {
        removeFile(config.icon?.fileName)
        config.icon = IconConfig(type: "builtin", style: style, fileName: nil)
        save()
    }

    func updateIconImage(data: Data) {
        guard let result = writeImage(data: data, maxSize: 720, keepPNG: false) else { return }
        removeFile(config.icon?.fileName)
        config.icon = IconConfig(type: "custom", style: iconConfig.style, fileName: result.name)
        save()
    }

    func clearIcon() {
        removeFile(config.icon?.fileName)
        config.icon = nil
        save()
    }

    func iconExportData() -> Data? {
        currentIcon(size: 1024).pngData()
    }

    var launchImageData: Data? {
        guard let name = config.launch.fileName else { return nil }
        return try? Data(contentsOf: directory.appendingPathComponent(name))
    }

    var launchIsGIF: Bool {
        config.launch.originalType.contains("gif")
    }

    func skinImage(_ key: String) -> UIImage? {
        guard let skin = config.skins[key] else { return nil }
        return image(named: skin.fileName)
    }

    func skinOpacity(_ key: String) -> Double {
        config.skins[key]?.opacity ?? 0.35
    }

    func skinBrightness(_ key: String) -> Double {
        config.skins[key]?.brightness ?? 1.0
    }

    func updateWallpaper(data: Data) {
        guard let result = writeImage(data: data, maxSize: 1280, keepPNG: false) else { return }
        removeFile(config.wallpaperFileName)
        config.wallpaperFileName = result.name
        save()
    }

    func setWallpaperOpacity(_ value: Double) {
        config.wallpaperOpacity = min(1, max(0, value))
        save()
    }

    func clearWallpaper() {
        removeFile(config.wallpaperFileName)
        config.wallpaperFileName = nil
        save()
    }

    func updateSkin(key: String, data: Data) {
        guard let result = writeImage(data: data, maxSize: 720, keepPNG: false) else { return }
        removeFile(config.skins[key]?.fileName)
        let opacity = config.skins[key]?.opacity ?? 0.35
        config.skins[key] = SkinConfig(fileName: result.name, opacity: opacity)
        save()
    }

    func setSkinOpacity(key: String, value: Double) {
        guard var skin = config.skins[key] else { return }
        skin.opacity = min(1, max(0, value))
        config.skins[key] = skin
        save()
    }

    func setSkinBrightness(key: String, value: Double) {
        guard var skin = config.skins[key] else { return }
        skin.brightness = min(1.8, max(0.2, value))
        config.skins[key] = skin
        save()
    }

    func clearSkin(key: String) {
        removeFile(config.skins[key]?.fileName)
        config.skins.removeValue(forKey: key)
        save()
    }

    func updateLaunch(data: Data, type: String) {
        let normalized = type.lowercased()
        if normalized.contains("gif") {
            let name = UUID().uuidString + ".gif"
            let url = directory.appendingPathComponent(name)
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                return
            }
            removeFile(config.launch.fileName)
            config.launch.fileName = name
            config.launch.originalType = "image/gif"
        } else {
            let keepPNG = normalized.contains("png")
            guard let result = writeImage(data: data, maxSize: 900, keepPNG: keepPNG) else { return }
            removeFile(config.launch.fileName)
            config.launch.fileName = result.name
            config.launch.originalType = result.type
        }
        save()
    }

    func setLaunchSize(_ value: Double) {
        config.launch.size = min(100, max(20, value))
        save()
    }

    func setLaunchFit(_ fit: String) {
        config.launch.fit = fit == "cover" ? "cover" : "contain"
        save()
    }

    func setLaunchDuration(_ value: Double) {
        config.launch.duration = min(5, max(0.5, value))
        save()
    }

    func setLaunchEnabled(_ enabled: Bool) {
        config.launch.enabled = enabled
        save()
    }

    func clearLaunch() {
        removeFile(config.launch.fileName)
        config.launch.fileName = nil
        config.launch.originalType = ""
        save()
    }

    func resetAll() {
        removeFile(config.wallpaperFileName)
        for skin in config.skins.values {
            removeFile(skin.fileName)
        }
        removeFile(config.launch.fileName)
        removeFile(config.icon?.fileName)
        config = .defaultConfig
        isEditing = false
        editingSkinKey = nil
        save()
    }

    func beginSkinEditing() {
        isEditing = true
    }

    func endSkinEditing() {
        isEditing = false
        editingSkinKey = nil
    }

    func presentSkinEditor(for key: String) {
        editingSkinKey = key
    }

    func dismissSkinEditor() {
        editingSkinKey = nil
    }

    func previewLaunch() {
        launchPreviewToken += 1
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    private func image(named name: String?) -> UIImage? {
        guard let name = name else { return nil }
        if let cached = imageCache[name] { return cached }
        let url = directory.appendingPathComponent(name)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        imageCache[name] = image
        return image
    }

    private func removeFile(_ name: String?) {
        guard let name = name else { return }
        imageCache.removeValue(forKey: name)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }

    private func writeImage(data: Data, maxSize: CGFloat, keepPNG: Bool) -> (name: String, type: String)? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide = max(image.size.width, image.size.height)
        let scale = min(1, maxSize / max(maxSide, 1))
        let size = CGSize(
            width: max(1, image.size.width * scale),
            height: max(1, image.size.height * scale)
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { context in
            if !keepPNG {
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        if keepPNG {
            guard let png = rendered.pngData() else { return nil }
            let name = UUID().uuidString + ".png"
            let url = directory.appendingPathComponent(name)
            do { try png.write(to: url, options: .atomic) } catch { return nil }
            return (name, "image/png")
        } else {
            guard let jpg = rendered.jpegData(compressionQuality: 0.82) else { return nil }
            let name = UUID().uuidString + ".jpg"
            let url = directory.appendingPathComponent(name)
            do { try jpg.write(to: url, options: .atomic) } catch { return nil }
            return (name, "image/jpeg")
        }
    }
}

@MainActor
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechPlayer()

    @Published private(set) var isActive = false
    @Published private(set) var isPaused = false
    @Published private(set) var index = 0
    @Published private(set) var total = 0
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var label = ""

    @Published var loop = true
    @Published var interval: Double = 1.0
    @Published var limitMinutes: Int = 0
    @Published var startIndex: Int = 0

    private let synthesizer = AVSpeechSynthesizer()
    private var items: [String] = []
    private var segments: [String] = []
    private var segmentIndex = 0
    private var stopDate: Date?
    private var tickTask: Task<Void, Never>?
    private var gapTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func start(items: [String], label: String) {
        let cleaned = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return }

        stop()
        self.items = cleaned
        self.label = label
        index = min(max(0, startIndex), cleaned.count - 1)
        total = cleaned.count
        isActive = true
        isPaused = false
        stopDate = limitMinutes > 0 ? Date().addingTimeInterval(Double(limitMinutes * 60)) : nil
        remainingSeconds = limitMinutes * 60
        startTick()
        speakCurrent()
    }

    func pause() {
        guard isActive, !isPaused else { return }
        isPaused = true
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        guard isActive, isPaused else { return }
        isPaused = false
        synthesizer.continueSpeaking()
    }

    func stop() {
        isActive = false
        isPaused = false
        tickTask?.cancel()
        gapTask?.cancel()
        tickTask = nil
        gapTask = nil
        stopDate = nil
        remainingSeconds = 0
        segments = []
        segmentIndex = 0
        synthesizer.stopSpeaking(at: .immediate)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSegmentFinish()
        }
    }

    private func handleFinish() {
        guard isActive, !isPaused else { return }
        index += 1
        if index >= total {
            if loop {
                index = 0
            } else {
                stop()
                return
            }
        }
        gapTask?.cancel()
        gapTask = Task { [weak self] in
            let interval = self?.interval ?? 1
            try? await Task.sleep(nanoseconds: UInt64(max(0, interval) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.speakCurrent()
        }
    }

    private func speakCurrent() {
        guard isActive, !isPaused else { return }
        guard index < items.count else { return }

        segments = items[index]
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        segmentIndex = 0
        speakSegment()
    }

    private func speakSegment() {
        guard isActive, !isPaused else { return }
        guard segmentIndex < segments.count else {
            handleFinish()
            return
        }
        let text = segments[segmentIndex]
        let isChinese = text.range(of: "\\p{Han}", options: .regularExpression) != nil
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: isChinese ? "zh-CN" : "en-US")
        utterance.rate = 0.44
        synthesizer.speak(utterance)
    }

    private func handleSegmentFinish() {
        guard isActive, !isPaused else { return }
        segmentIndex += 1
        if segmentIndex < segments.count {
            speakSegment()
        } else {
            handleFinish()
        }
    }

    private func startTick() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self = self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard isActive else { return }
        guard let stopDate = stopDate else { return }
        let remaining = Int(stopDate.timeIntervalSinceNow.rounded(.up))
        remainingSeconds = max(0, remaining)
        if remaining <= 0 {
            stop()
        }
    }
}

final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()

    private init() {}

    func speak(_ text: String, language: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audioSession.setActive(true, options: [])

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.44
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}