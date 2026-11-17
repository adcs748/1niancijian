import SwiftUI
import UIKit
import ImageIO

enum Brand {
    static let accent = Color(red: 0.24, green: 0.42, blue: 0.96)
    static let translations = Color(red: 0.36, green: 0.42, blue: 0.52)
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let heroGradient = LinearGradient(
        colors: [accent, Color(red: 0.42, green: 0.34, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum ThemeMode: String, CaseIterable {
    case light
    case dark
}

enum TextProcessing {
    struct Token: Hashable {
        let text: String
        let lookupKey: String?
        var isWord: Bool { lookupKey != nil }
    }

    private static let edgePunctuation = CharacterSet(
        charactersIn: "\"“”'‘’()[]{}<>.,!?;:—–-…·•*_/"
    )

    static func sentences(in paragraph: String) -> [String] {
        let characters = Array(paragraph)
        guard !characters.isEmpty else { return [] }

        var result: [String] = []
        var buffer = ""
        var index = 0

        while index < characters.count {
            let character = characters[index]
            buffer.append(character)

            if ".!?。！？".contains(character) {
                var next = index + 1
                while next < characters.count, "\"'”’)]".contains(characters[next]) {
                    buffer.append(characters[next])
                    next += 1
                }
                if next >= characters.count || characters[next].isWhitespace {
                    let sentence = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty { result.append(sentence) }
                    buffer = ""
                }
                index = next
                continue
            }
            index += 1
        }

        let tail = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { result.append(tail) }
        return result.isEmpty ? [paragraph] : result
    }

    static func tokens(in paragraph: String) -> [Token] {
        paragraph.split(whereSeparator: { $0.isWhitespace }).map { raw in
            let piece = String(raw)
            let stripped = piece.trimmingCharacters(in: edgePunctuation)
            let looksLikeWord = !stripped.isEmpty
                && stripped.contains(where: { $0.isLetter })
                && stripped.allSatisfy { $0.isLetter || $0 == "-" || $0 == "’" || $0 == "'" }
            return Token(text: piece, lookupKey: looksLikeWord ? normalize(stripped) : nil)
        }
    }

    static func normalize(_ word: String) -> String {
        word
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: CharacterSet(charactersIn: "'"))
    }

    static func baseForms(for word: String) -> [String] {
        let value = word.lowercased()
        var forms: [String] = []
        var seen = Set<String>()

        func add(_ candidate: String) {
            guard candidate.count > 1, candidate != value, !seen.contains(candidate) else { return }
            seen.insert(candidate)
            forms.append(candidate)
        }

        func addStem(_ stem: String) {
            add(stem)
            if let last = stem.last, stem.count > 2, stem.dropLast().last == last {
                add(String(stem.dropLast()))
            }
        }

        if value.hasSuffix("'s") { add(String(value.dropLast(2))) }
        if value.hasSuffix("ies"), value.count > 3 { add(String(value.dropLast(3)) + "y") }
        if value.hasSuffix("ves"), value.count > 3 {
            add(String(value.dropLast(3)) + "f")
            add(String(value.dropLast(3)) + "fe")
        }
        if value.hasSuffix("es"), value.count > 2 { add(String(value.dropLast(2))) }
        if value.hasSuffix("s"), !value.hasSuffix("ss"), value.count > 2 {
            add(String(value.dropLast()))
        }
        if value.hasSuffix("ied"), value.count > 3 { add(String(value.dropLast(3)) + "y") }
        if value.hasSuffix("ed"), value.count > 3 {
            let stem = String(value.dropLast(2))
            addStem(stem)
            add(stem + "e")
        }
        if value.hasSuffix("ing"), value.count > 4 {
            let stem = String(value.dropLast(3))
            addStem(stem)
            add(stem + "e")
        }
        if value.hasSuffix("ly"), value.count > 3 {
            add(String(value.dropLast(2)))
            add(String(value.dropLast(1)))
        }
        if value.hasSuffix("er"), value.count > 3 {
            addStem(String(value.dropLast(2)))
            add(String(value.dropLast(1)))
        }
        if value.hasSuffix("est"), value.count > 4 {
            addStem(String(value.dropLast(3)))
        }
        if value.hasSuffix("ness"), value.count > 5 {
            add(String(value.dropLast(4)))
        }
        return forms
    }
}

enum SentenceAnalyzer {
    private static let beVerbs: Set<String> = [
        "am", "is", "are", "was", "were", "be", "been", "being"
    ]
    private static let auxVerbs: Set<String> = [
        "do", "does", "did", "have", "has", "had", "will", "would", "shall",
        "should", "can", "could", "may", "might", "must", "ought"
    ]
    private static let prepositions: Set<String> = [
        "in", "on", "at", "to", "for", "with", "by", "from", "of", "about",
        "into", "onto", "over", "under", "between", "among", "through",
        "during", "without", "against", "toward", "towards", "upon", "within",
        "across", "behind", "beside", "beyond", "after", "before", "since",
        "until", "till", "despite", "like", "as", "than", "around", "near",
        "off", "out", "up", "down"
    ]
    private static let conjunctions: Set<String> = [
        "and", "but", "or", "so", "because", "although", "though", "while",
        "if", "when", "unless", "since", "as", "that", "which", "who", "whom",
        "whose", "where", "whether"
    ]
    private static let adverbs: Set<String> = [
        "often", "always", "usually", "never", "sometimes", "also", "just",
        "still", "even", "only", "really", "already", "seldom", "rarely",
        "frequently", "generally", "normally", "perhaps", "maybe", "probably",
        "certainly", "actually", "finally", "suddenly", "recently", "lately"
    ]
    private static let commonVerbs: Set<String> = [
        "accept", "achieve", "add", "admit", "affect", "agree", "allow",
        "answer", "appear", "apply", "argue", "arrive", "ask", "avoid",
        "become", "begin", "believe", "belong", "borrow", "break", "bring",
        "build", "buy", "call", "carry", "cause", "change", "choose", "claim",
        "climb", "close", "come", "compare", "complete", "consider", "contain",
        "continue", "control", "create", "cut", "decide", "deliver", "demand",
        "describe", "design", "develop", "die", "discover", "discuss", "draw",
        "drive", "eat", "encourage", "enjoy", "establish", "expect", "explain",
        "express", "face", "fail", "fall", "feel", "fight", "fill", "find",
        "finish", "focus", "follow", "forget", "form", "gain", "get", "give",
        "go", "grow", "guess", "handle", "happen", "hear", "help", "hold",
        "hope", "identify", "ignore", "imagine", "improve", "include",
        "increase", "indicate", "influence", "inform", "insist", "involve",
        "join", "keep", "know", "lead", "learn", "leave", "let", "like",
        "live", "look", "lose", "love", "make", "manage", "mean", "meet",
        "mention", "move", "need", "notice", "offer", "open", "order", "pass",
        "pay", "perform", "plan", "play", "prefer", "prepare", "present",
        "prevent", "produce", "protect", "prove", "provide", "publish", "pull",
        "push", "put", "raise", "reach", "read", "realize", "receive",
        "recognize", "recommend", "reduce", "refuse", "remain", "remember",
        "remove", "repeat", "replace", "require", "respond", "rest", "return",
        "reveal", "rise", "run", "save", "say", "see", "seem", "sell", "send",
        "serve", "set", "share", "show", "sit", "sleep", "solve", "speak",
        "spend", "stand", "start", "stay", "stop", "study", "succeed",
        "suggest", "support", "suppose", "take", "talk", "teach", "tell",
        "tend", "test", "think", "throw", "touch", "travel", "treat", "try",
        "turn", "understand", "use", "visit", "wait", "walk", "want", "watch",
        "wear", "win", "wish", "work", "worry", "write"
    ]

    static func splitWords(_ text: String) -> [String] {
        let cleaned = text.replacingOccurrences(
            of: "[^A-Za-z'’\\-\\s]",
            with: " ",
            options: .regularExpression
        )
        return cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    static func analyze(_ text: String, isVerb: (String) -> Bool) -> SentenceAnalysis? {
        let words = splitWords(text)
        let lower = words.map { $0.lowercased() }
        let count = words.count

        if count == 0 { return nil }
        if count == 1 {
            return make(
                pattern: "单词 / 片段",
                subject: words[0],
                predicate: "—",
                objectLabel: "释义",
                object: "—",
                adverbial: "",
                note: "选择一个完整的句子片段可以获得语法分析",
                complete: false,
                wordCount: count
            )
        }

        var verbIndex = -1
        var verbType = ""

        for index in 0..<lower.count {
            let type = detectVerb(lower[index], isVerb: isVerb)
            if type.isEmpty { continue }
            if index == 0, lower[0].hasSuffix("ing"), index + 1 < lower.count,
               beVerbs.contains(lower[index + 1]) {
                continue
            }
            verbIndex = index
            verbType = type
            break
        }

        if lower.count > 1, lower[0] == "there", verbIndex > 0 {
            return make(
                pattern: "There be 句型（存在句）",
                subject: "there（形式主语）",
                predicate: words[1...verbIndex].joined(separator: " "),
                objectLabel: "真实主语",
                object: words[(verbIndex + 1)...].joined(separator: " "),
                adverbial: "",
                note: "",
                complete: true,
                wordCount: count
            )
        }

        if verbIndex == 0 {
            return make(
                pattern: "祈使句 / 无主语",
                subject: "（省略）",
                predicate: words[0],
                objectLabel: "宾语 / 补语",
                object: words.count > 1 ? words[1...].joined(separator: " ") : "—",
                adverbial: "",
                note: "句首为动词，可能是祈使句",
                complete: true,
                wordCount: count
            )
        }

        if verbIndex < 0 {
            return make(
                pattern: "未识别谓语",
                subject: words.joined(separator: " "),
                predicate: "—",
                objectLabel: "宾语 / 表语",
                object: "—",
                adverbial: "",
                note: "可能是名词短语、标题或省略结构",
                complete: false,
                wordCount: count
            )
        }

        let subjectParts = splitSubject(Array(words[0..<verbIndex]))
        var predicateWords = [words[verbIndex]]
        var nextIndex = verbIndex + 1

        if (verbType == "aux" || verbType == "be"), nextIndex < words.count {
            let nextType = detectVerb(lower[nextIndex], isVerb: isVerb)
            if !nextType.isEmpty, !auxVerbs.contains(lower[nextIndex]) {
                predicateWords.append(words[nextIndex])
                nextIndex += 1
            }
        }

        let rest = Array(words[nextIndex...])
        let restLower = Array(lower[nextIndex...])

        if beVerbs.contains(lower[verbIndex]), !rest.isEmpty {
            return make(
                pattern: "主系表（SVP）",
                subject: subjectParts.subject,
                predicate: predicateWords.joined(separator: " "),
                objectLabel: "表语",
                object: rest.joined(separator: " "),
                adverbial: subjectParts.adverbial,
                note: "",
                complete: true,
                wordCount: count
            )
        }

        if rest.isEmpty {
            return make(
                pattern: "主谓（SV）",
                subject: subjectParts.subject,
                predicate: predicateWords.joined(separator: " "),
                objectLabel: "宾语",
                object: "—",
                adverbial: subjectParts.adverbial,
                note: "",
                complete: true,
                wordCount: count
            )
        }

        var prepIndex = -1
        for index in 0..<restLower.count {
            if prepositions.contains(restLower[index]) {
                prepIndex = index
                break
            }
        }

        let objectWords = prepIndex >= 0 ? Array(rest[0..<prepIndex]) : rest
        var adverbial = subjectParts.adverbial
        if prepIndex >= 0 {
            let prepPhrase = rest[prepIndex...].joined(separator: " ")
            adverbial = [adverbial, prepPhrase].filter { !$0.isEmpty }.joined(separator: " ")
        }

        if objectWords.isEmpty {
            return make(
                pattern: "主谓（SV）+ 状语",
                subject: subjectParts.subject,
                predicate: predicateWords.joined(separator: " "),
                objectLabel: "宾语",
                object: "—",
                adverbial: adverbial,
                note: "动词后的介词短语作状语",
                complete: true,
                wordCount: count
            )
        }

        return make(
            pattern: "主谓宾（SVO）",
            subject: subjectParts.subject,
            predicate: predicateWords.joined(separator: " "),
            objectLabel: "宾语",
            object: objectWords.joined(separator: " "),
            adverbial: adverbial,
            note: "",
            complete: true,
            wordCount: count
        )
    }

    private static func splitSubject(_ input: [String]) -> (subject: String, adverbial: String) {
        var body = input
        var adverbial: [String] = []

        while let first = body.first,
              conjunctions.contains(first.lowercased()) || prepositions.contains(first.lowercased()) {
            adverbial.append(first)
            body.removeFirst()
        }

        var kept: [String] = []
        for word in body {
            if adverbs.contains(word.lowercased()) {
                adverbial.append(word)
            } else {
                kept.append(word)
            }
        }

        return (kept.joined(separator: " "), adverbial.joined(separator: " "))
    }

    private static func detectVerb(_ word: String, isVerb: (String) -> Bool) -> String {
        if beVerbs.contains(word) { return "be" }
        if auxVerbs.contains(word) { return "aux" }
        if commonVerbs.contains(word) { return "verb" }
        if isVerb(word) { return "verb" }
        if word.hasSuffix("ied"), word.count > 4 { return "verb" }
        if word.hasSuffix("ed"), word.count > 3 { return "verb" }
        if word.hasSuffix("ing"), word.count > 4 { return "verb" }
        return ""
    }

    private static func make(
        pattern: String,
        subject: String,
        predicate: String,
        objectLabel: String,
        object: String,
        adverbial: String,
        note: String,
        complete: Bool,
        wordCount: Int
    ) -> SentenceAnalysis {
        SentenceAnalysis(
            pattern: pattern,
            subject: subject.isEmpty ? "（省略）" : subject,
            predicate: predicate.isEmpty ? "—" : predicate,
            objectLabel: objectLabel,
            object: object.isEmpty ? "—" : object,
            adverbial: adverbial,
            note: note,
            complete: complete,
            wordCount: wordCount
        )
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = y + lineHeight
        }

        return CGSize(width: proposal.width ?? x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct GIFImageView: UIViewRepresentable {
    let data: Data
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = contentMode
        view.clipsToBounds = true
        view.image = GIFImageView.animatedImage(from: data)
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.contentMode = contentMode
        uiView.image = GIFImageView.animatedImage(from: data)
    }

    static func animatedImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return UIImage(data: data) }

        var images: [UIImage] = []
        var duration: Double = 0
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            duration += frameDuration(source, index)
        }
        guard !images.isEmpty else { return UIImage(data: data) }
        return UIImage.animatedImage(with: images, duration: max(duration, 0.2))
    }

    private static func frameDuration(_ source: CGImageSource, _ index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        if let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
            return unclamped
        }
        if let delay = gif[kCGImagePropertyGIFDelayTime] as? Double, delay > 0 {
            return delay
        }
        return 0.1
    }
}

struct Skinnable: ViewModifier {
    @EnvironmentObject private var appearance: AppearanceStore

    let key: String
    let radius: CGFloat
    var gradient: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if gradient {
                        Rectangle().fill(Brand.heroGradient)
                    } else {
                        Rectangle().fill(Brand.cardBackground)
                    }
                    if let image = appearance.skinImage(key) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .opacity(appearance.skinOpacity(key))
                            .brightness(appearance.skinBrightness(key) - 1.0)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            )
            .overlay {
                if appearance.isEditing {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .foregroundStyle(Brand.accent)
                        .overlay {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appearance.presentSkinEditor(for: key)
                                }
                        }
                }
            }
    }
}

extension View {
    func skinnable(_ key: String, radius: CGFloat = 18, gradient: Bool = false) -> some View {
        modifier(Skinnable(key: key, radius: radius, gradient: gradient))
    }
}

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published private(set) var message: String?
    private var task: Task<Void, Never>?

    func show(_ text: String) {
        message = text
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled { message = nil }
        }
    }
}

enum IconRenderer {
    static func render(style: String, image: UIImage?, size: CGFloat = 1024) -> UIImage {
        let dimension = max(64, size)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        return renderer.image { context in
            if let image = image {
                let scale = max(
                    dimension / max(image.size.width, 1),
                    dimension / max(image.size.height, 1)
                )
                let width = image.size.width * scale
                let height = image.size.height * scale
                image.draw(in: CGRect(
                    x: (dimension - width) / 2,
                    y: (dimension - height) / 2,
                    width: width,
                    height: height
                ))
                return
            }

            let colors = colorPair(for: style)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [colors.0.cgColor, colors.1.cgColor] as CFArray,
                locations: [0, 1]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: dimension, y: dimension),
                    options: []
                )
            } else {
                colors.0.setFill()
                context.fill(CGRect(x: 0, y: 0, width: dimension, height: dimension))
            }

            let text = "念" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: dimension * 0.5, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: (dimension - textSize.width) / 2,
                    y: (dimension - textSize.height) / 2
                ),
                withAttributes: attributes
            )
        }
    }

    private static func colorPair(for style: String) -> (UIColor, UIColor) {
        switch style {
        case "ink":
            return (
                UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
                UIColor(red: 0.29, green: 0.29, blue: 0.32, alpha: 1)
            )
        case "sunset":
            return (
                UIColor(red: 1.0, green: 0.48, blue: 0.35, alpha: 1),
                UIColor(red: 1.0, green: 0.71, blue: 0.34, alpha: 1)
            )
        case "forest":
            return (
                UIColor(red: 0.12, green: 0.54, blue: 0.44, alpha: 1),
                UIColor(red: 0.39, green: 0.79, blue: 0.54, alpha: 1)
            )
        default:
            return (
                UIColor(red: 0.24, green: 0.42, blue: 0.96, alpha: 1),
                UIColor(red: 0.48, green: 0.36, blue: 0.98, alpha: 1)
            )
        }
    }
}

struct ToastOverlay: View {
    @EnvironmentObject private var center: ToastCenter

    var body: some View {
        VStack {
            Spacer()
            if let message = center.message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.82)))
                    .padding(.horizontal, 30)
                    .padding(.bottom, 120)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: center.message)
        .allowsHitTesting(false)
    }
}