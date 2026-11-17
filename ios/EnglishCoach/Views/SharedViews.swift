import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI
import Vision

struct TokenSelection: Equatable {
    var paragraph = -1
    var anchor = -1
    var focus = -1
    var active = false

    static let empty = TokenSelection()

    func contains(_ paragraphIndex: Int, _ tokenIndex: Int) -> Bool {
        guard active, paragraph == paragraphIndex else { return false }
        let low = min(anchor, focus)
        let high = max(anchor, focus)
        return tokenIndex >= low && tokenIndex <= high
    }
}

struct TokenItem: Identifiable, Hashable {
    let index: Int
    let text: String
    let lookupKey: String?

    var id: Int { index }
    var isWord: Bool { lookupKey != nil }

    static func parse(_ paragraph: String) -> [TokenItem] {
        let pieces = paragraph.split(whereSeparator: { $0.isWhitespace })
        return pieces.enumerated().map { offset, piece in
            let text = String(piece)
            let stripped = text.trimmingCharacters(
                in: CharacterSet(charactersIn: "\"“”'‘’()[]{}<>.,!?;:—–-…·•*_/")
            )
            let isWord = !stripped.isEmpty
                && stripped.contains(where: { $0.isLetter })
                && stripped.allSatisfy { $0.isLetter || $0 == "-" || $0 == "'" || $0 == "’" }
            return TokenItem(
                index: offset,
                text: text,
                lookupKey: isWord ? TextProcessing.normalize(stripped) : nil
            )
        }
    }
}

struct WordTokensView: View {
    let tokens: [TokenItem]
    let paragraphIndex: Int
    let selection: TokenSelection
    let readMode: Bool
    let fontSize: Double
    let onTap: (Int) -> Void
    let onLongPress: (Int) -> Void

    var body: some View {
        FlowLayout(spacing: 4, lineSpacing: 8) {
            ForEach(tokens) { token in
                tokenView(token)
            }
        }
    }

    private func tokenView(_ token: TokenItem) -> some View {
        Text(token.text)
            .font(.system(size: fontSize, design: .serif))
            .foregroundStyle(token.isWord ? .primary : .secondary)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(selection.contains(paragraphIndex, token.index)
                          ? Brand.accent.opacity(0.18)
                          : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard !readMode, token.isWord else { return }
                onTap(token.index)
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                guard !readMode, token.isWord else { return }
                onLongPress(token.index)
            }
    }
}

struct WordCardSelection: Identifiable {
    let id = UUID()
    let word: String
}

struct WordCardSheet: View {
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore
    @Environment(\.dismiss) private var dismiss

    let word: String

    @State private var result: WordLookupResult?
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if loading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("正在查询释义…")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Brand.cardBackground)
                        )
                    } else if let result = result {
                        meaningsCard(result)
                        favoriteButton(result)
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await load()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text(result?.word ?? word)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                if let phonetic = result?.phonetic, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button {
                SpeechService.shared.speak(result?.word ?? word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Brand.accent.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
    }

    private func meaningsCard(_ result: WordLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(result.meanings.enumerated()), id: \.offset) { _, meaning in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Brand.accent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(meaning)
                        .font(.system(size: 16))
                        .lineSpacing(4)
                    Spacer(minLength: 0)
                }
            }

            Text("释义来源：\(result.source)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    @ViewBuilder
    private func favoriteButton(_ result: WordLookupResult) -> some View {
        let saved = favorites.isFavorited(.word, text: result.word)
        Button {
            favorites.toggleWord(
                word: result.word,
                meaning: result.meanings.joined(separator: "；"),
                phonetic: result.phonetic ?? ""
            )
        } label: {
            HStack(spacing: 8) {
                Image(systemName: saved ? "star.slash" : "star")
                Text(saved ? "移出收藏夹" : "加入收藏夹")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(saved ? Color.secondary : Brand.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Brand.accent.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func load() async {
        loading = true
        result = await dictionary.lookup(word)
        loading = false
    }
}

struct ArticleRowCard: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundStyle(Brand.accent)
                .frame(width: 40, height: 40)
                .background(Brand.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(article.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(article.preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text("\(article.wordCount) 词")
                    Text("·")
                    Text("约 \(article.readingMinutes) 分钟")
                    if article.isFullyTranslated {
                        Text("·")
                        Label("已翻译", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Brand.accent)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SelectionSheetItem: Identifiable {
    let id = "selection"
    let text: String
    let analysis: SentenceAnalysis?
    let wordCount: Int
}

struct SelectionPanel: View {
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore
    @EnvironmentObject private var toast: ToastCenter

    let item: SelectionSheetItem
    let onClose: () -> Void

    @State private var translation = ""
    @State private var loading = true
    @State private var offline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("已选 \(item.wordCount) 个单词")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button {
                    SpeechService.shared.speak(item.text)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.text)
                        .font(.system(size: 15, design: .serif))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if loading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("正在翻译所选内容…")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        if offline {
                            Text("离线逐词示意")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        Text(translation)
                            .font(.system(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let analysis = item.analysis {
                        grammarCard(analysis)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 210)

            HStack(spacing: 10) {
                Button {
                    toggleSentence()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sentenceSaved ? "star.slash" : "star")
                        Text(sentenceSaved ? "已收藏句子" : "收藏句子")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Brand.accent.opacity(0.12))
                    )
                    .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)

                Button {
                    addWordsToFavorites()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "text.badge.plus")
                        Text("收藏这些单词")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Brand.accent.opacity(0.12))
                    )
                    .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
        )
        .task(id: item.text) {
            await translate()
        }
    }

    private var sentenceSaved: Bool {
        favorites.isFavorited(.sentence, text: item.text)
    }

    private func grammarCard(_ analysis: SentenceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(analysis.pattern)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Brand.accent))

            grammarRow("主语", analysis.subject)
            grammarRow("谓语", analysis.predicate)
            grammarRow(analysis.objectLabel, analysis.object)
            if !analysis.adverbial.isEmpty {
                grammarRow("状语", analysis.adverbial)
            }
            Text(analysis.note.isEmpty ? "启发式语法分析，仅供参考" : analysis.note)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func grammarRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
            Spacer(minLength: 0)
        }
    }

    @MainActor
    private func translate() async {
        loading = true
        offline = false
        do {
            translation = try await TranslationService.shared.translate(item.text)
        } catch {
            if let gloss = offlineGloss(item.text) {
                translation = gloss
                offline = true
            } else {
                translation = "在线翻译暂不可用，请稍后重试。"
            }
        }
        loading = false
    }

    private func offlineGloss(_ text: String) -> String? {
        var hits = 0
        var parts: [String] = []
        for token in TokenItem.parse(text) {
            guard let key = token.lookupKey else {
                parts.append(token.text)
                continue
            }
            if let entry = dictionary.entries(for: key).first {
                hits += 1
                let meaning = entry.meaning.replacingOccurrences(
                    of: "^[a-z]+\\.\\s*",
                    with: "",
                    options: .regularExpression
                )
                parts.append("【\(meaning)】")
            } else {
                parts.append(token.text)
            }
        }
        return hits >= 3 ? "（离线逐词示意）" + parts.joined(separator: " ") : nil
    }

    private func toggleSentence() {
        favorites.toggleSentence(
            text: item.text,
            translation: translation.isEmpty ? "（待补充译文）" : translation,
            analysis: item.analysis
        )
    }

    private func addWordsToFavorites() {
        var added = 0
        for token in TokenItem.parse(item.text) {
            guard let key = token.lookupKey else { continue }
            let entries = dictionary.entries(for: key)
            let word = entries.first?.word ?? key
            if favorites.isFavorited(.word, text: word) { continue }
            favorites.addWord(
                word: word,
                meaning: entries.first?.meaning ?? "（词库未收录）",
                phonetic: entries.first?.phonetic ?? ""
            )
            added += 1
        }
        toast.show(added > 0 ? "已收藏 \(added) 个单词" : "选中的单词已在收藏夹中")
    }
}

struct PlaybackSheet: View {
    @EnvironmentObject private var player: SpeechPlayer
    @Environment(\.dismiss) private var dismiss

    let title: String
    let items: () -> [String]

    private var itemCount: Int { items().count }

    private var startBinding: Binding<Int> {
        Binding(
            get: { min(max(0, player.startIndex), max(0, itemCount - 1)) },
            set: { player.startIndex = max(0, min($0, max(0, itemCount - 1))) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("播放内容") {
                    Text(title)
                    Text("共 \(items().count) 项")
                        .foregroundStyle(.secondary)
                }

                Section("设置") {
                    Toggle("循环播放", isOn: $player.loop)

                    Picker("播放间隔", selection: $player.interval) {
                        Text("0.5 秒").tag(0.5)
                        Text("1 秒").tag(1.0)
                        Text("2 秒").tag(2.0)
                    }

                    Picker("定时停止", selection: $player.limitMinutes) {
                        Text("不限").tag(0)
                        Text("5 分钟").tag(5)
                        Text("10 分钟").tag(10)
                        Text("20 分钟").tag(20)
                        Text("30 分钟").tag(30)
                    }
                }

                Section("起始位置") {
                    Stepper(value: startBinding, in: 0...max(0, itemCount - 1)) {
                        Text(itemCount == 0
                             ? "暂无可播放内容"
                             : "从第 \(min(max(0, player.startIndex), itemCount - 1) + 1) / \(itemCount) 项开始")
                    }
                }

                Section {
                    Button {
                        player.start(items: items(), label: title)
                        dismiss()
                    } label: {
                        Label("开始播放", systemImage: "play.fill")
                    }
                }
            }
            .navigationTitle("自动播放")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct FavoriteSentenceSheet: View {
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore
    @Environment(\.dismiss) private var dismiss

    let item: FavoriteItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("收藏的句子")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button {
                            SpeechService.shared.speak(item.text)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(Brand.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(item.text)
                        .font(.system(size: 15, design: .serif))
                        .lineSpacing(4)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Brand.cardBackground)
                        )

                    Text(item.translation.isEmpty ? "暂无译文" : item.translation)
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .foregroundStyle(.secondary)

                    if let analysis = item.analysis {
                        analysisCard(analysis)
                    }

                    Button(role: .destructive) {
                        favorites.remove(item)
                        dismiss()
                    } label: {
                        Text("移出收藏夹")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func analysisCard(_ analysis: SentenceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(analysis.pattern)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Brand.accent))
            row("主语", analysis.subject)
            row("谓语", analysis.predicate)
            row(analysis.objectLabel, analysis.object)
            if !analysis.adverbial.isEmpty {
                row("状语", analysis.adverbial)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
            Spacer(minLength: 0)
        }
    }
}

struct ImportSheet: View {
    @EnvironmentObject private var articleStore: ArticleStore
    @Environment(\.dismiss) private var dismiss

    let bank: Bool

    @State private var title = ""
    @State private var text = ""
    @State private var showFileImporter = false
    @State private var errorMessage: String?
    @State private var created: Article?
    @State private var ocrPicker: PhotosPickerItem?
    @State private var recognizing = false
    @FocusState private var focused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    TextField("文章标题（可选）", text: $title)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Brand.cardBackground)
                )
                .skinnable("import-title", radius: 14)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("粘贴或输入英语文章，建议保留段落之间的空行…")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .focused($focused)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Brand.cardBackground)
                )
                .skinnable("import-text", radius: 16)

                HStack(spacing: 12) {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("从文件导入", systemImage: "folder")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .skinnable("import-file", radius: 14)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                            text = clipboard
                        }
                    } label: {
                        Label("粘贴文本", systemImage: "doc.on.clipboard")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .skinnable("import-paste", radius: 14)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.primary)

                PhotosPicker(selection: $ocrPicker, matching: .images) {
                    HStack(spacing: 8) {
                        if recognizing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "text.viewfinder")
                        }
                        Text(recognizing ? "正在识别图片文字…" : "图片英文识别（OCR）")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.primary)
                    .skinnable("import-ocr", radius: 14)
                }
                .buttonStyle(.plain)
                .disabled(recognizing)
            }
            .padding(20)
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationTitle(bank ? "导入真题" : "导入文章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("开始阅读") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .disabled(trimmedText.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileResult(result)
            }
            .onChange(of: ocrPicker) { _, item in
                recognize(item)
            }
            .alert(
                "无法导入",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(item: $created) { article in
                ReaderView(articleID: article.id)
            }
        }
    }

    private var allowedTypes: [UTType] {
        var types: [UTType] = [.plainText, .text]
        if let markdown = UTType(filenameExtension: "md") {
            types.append(markdown)
        }
        return types
    }

    private func save() {
        guard !trimmedText.isEmpty else { return }
        let level = bank ? VocabularyLevel.cet4.rawValue : ""
        let article = articleStore.add(title: title, content: trimmedText, bank: bank, level: level)
        created = article
        focused = false
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

            let content = (try? String(contentsOf: url, encoding: .utf8))
                ?? (try? String(contentsOf: url, encoding: .utf16))
                ?? (try? String(contentsOf: url, encoding: .isoLatin1))

            guard let content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "读取失败。请确认文件是纯文本格式（.txt 或 .md），且内容不为空。"
                return
            }

            text = content
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = url.deletingPathExtension().lastPathComponent
            }
        case .failure(let error):
            errorMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func recognize(_ item: PhotosPickerItem?) {
        guard let item else { return }
        recognizing = true
        Task {
            defer { recognizing = false }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                errorMessage = "无法读取所选图片。"
                return
            }
            let recognized = await Task.detached(priority: .userInitiated) { () async -> String in
                guard let image = UIImage(data: data), let cgImage = image.cgImage else { return "" }
                return ImportSheet.performOCR(cgImage)
            }.value
            let trimmed = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                errorMessage = "未识别到英文内容，请换一张更清晰的图片试试。"
                return
            }
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = "图片识别 · \(Date().formatted(date: .numeric, time: .shortened))"
            }
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text = trimmed
            } else {
                text += "\n\n" + trimmed
            }
            ocrPicker = nil
            focused = false
        }
    }

    private static func performOCR(_ cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}