import Foundation

enum VocabularyLevel: String, CaseIterable, Codable, Identifiable {
    case cet4
    case cet6

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cet4: return "四级词汇"
        case .cet6: return "六级词汇"
        }
    }

    var shortTitle: String {
        switch self {
        case .cet4: return "CET-4"
        case .cet6: return "CET-6"
        }
    }

    var fileName: String {
        switch self {
        case .cet4: return "cet4_words"
        case .cet6: return "cet6_words"
        }
    }
}

struct WordEntry: Identifiable, Hashable {
    let word: String
    let phonetic: String
    let meaning: String
    let level: VocabularyLevel

    var id: String { "\(level.rawValue)-\(word)" }
    var normalizedWord: String { word.lowercased() }
}

struct WordLookupResult: Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String?
    let meanings: [String]
    let source: String
}

struct Article: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var translations: [Int: String]
    var translatedAt: Date?
    var bank: Bool
    var kind: String
    var level: String

    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        createdAt: Date = Date(),
        translations: [Int: String] = [:],
        translatedAt: Date? = nil,
        bank: Bool = false,
        kind: String = "article",
        level: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.translations = translations
        self.translatedAt = translatedAt
        self.bank = bank
        self.kind = kind
        self.level = level
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, translations, translatedAt, bank, kind, level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        translations = (try? container.decode([Int: String].self, forKey: .translations)) ?? [:]
        translatedAt = try? container.decode(Date.self, forKey: .translatedAt)
        bank = (try? container.decode(Bool.self, forKey: .bank)) ?? false
        kind = (try? container.decode(String.self, forKey: .kind)) ?? "article"
        level = (try? container.decode(String.self, forKey: .level)) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(translations, forKey: .translations)
        try container.encodeIfPresent(translatedAt, forKey: .translatedAt)
        try container.encode(bank, forKey: .bank)
        try container.encode(kind, forKey: .kind)
        try container.encode(level, forKey: .level)
    }

    var paragraphs: [String] {
        ParagraphParser.paragraphs(from: content)
    }

    var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace }).count
    }

    var readingMinutes: Int {
        max(1, Int((Double(wordCount) / 200.0).rounded(.up)))
    }

    var preview: String {
        let first = paragraphs.first ?? content
        return first.count > 86 ? String(first.prefix(86)) + "…" : first
    }

    var isFullyTranslated: Bool {
        let items = paragraphs
        guard !items.isEmpty else { return false }
        return items.indices.allSatisfy { translations[$0] != nil }
    }

    var levelBadge: String {
        if level == VocabularyLevel.cet4.rawValue { return "CET-4" }
        if level == VocabularyLevel.cet6.rawValue { return "CET-6" }
        return "未分级"
    }
}

enum ParagraphParser {
    static func paragraphs(from content: String) -> [String] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var result: [String] = []
        var buffer: [String] = []

        for line in normalized.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !buffer.isEmpty {
                    result.append(buffer.joined(separator: " "))
                    buffer.removeAll()
                }
            } else {
                buffer.append(trimmed)
            }
        }

        if !buffer.isEmpty { result.append(buffer.joined(separator: " ")) }

        if result.isEmpty {
            let single = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return single.isEmpty ? [] : [single]
        }
        return result
    }
}

struct SentenceAnalysis: Codable, Hashable {
    var pattern: String
    var subject: String
    var predicate: String
    var objectLabel: String
    var object: String
    var adverbial: String
    var note: String
    var complete: Bool
    var wordCount: Int
}

enum FavoriteType: String, Codable {
    case word
    case sentence
}

struct FavoriteItem: Identifiable, Codable, Hashable {
    var id: UUID
    var type: FavoriteType
    var text: String
    var translation: String
    var phonetic: String
    var analysis: SentenceAnalysis?
    var addedAt: Date

    init(
        id: UUID = UUID(),
        type: FavoriteType,
        text: String,
        translation: String = "",
        phonetic: String = "",
        analysis: SentenceAnalysis? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.translation = translation
        self.phonetic = phonetic
        self.analysis = analysis
        self.addedAt = addedAt
    }
}

struct BankPaper: Identifiable, Hashable {
    let id: String
    let title: String
    let year: Int
    let month: Int
    let level: VocabularyLevel
    let set: Int
}

struct OfficialSource: Identifiable, Hashable {
    let id: String
    let title: String
    let tag: String
    let detail: String
    let urlString: String
}

enum QuestionBank {
    static let officialSources: [OfficialSource] = [
        OfficialSource(
            id: "official-syllabus",
            title: "《全国大学英语四、六级考试大纲（2016 年修订版）》",
            tag: "官方大纲",
            detail: "教育部教育考试院发布的官方考试大纲 PDF，包含考试性质、内容、题型与样题说明。",
            urlString: "https://cet.neea.edu.cn/res/Home/1704/55b02330ac17274664f06d9d3db8249d.pdf"
        ),
        OfficialSource(
            id: "official-format",
            title: "CET 笔试考核内容与试卷结构",
            tag: "官方说明",
            detail: "四级 / 六级笔试试卷结构、题型、题量、分值比例与考试时间。",
            urlString: "https://cet.neea.edu.cn/html1/folder/16113/1586-1.htm"
        ),
        OfficialSource(
            id: "official-home",
            title: "全国大学英语四、六级考试（CET）官方主页",
            tag: "官方入口",
            detail: "考试动态、报名、成绩查询、常见问题等官方入口。",
            urlString: "https://cet.neea.edu.cn/"
        ),
        OfficialSource(
            id: "official-score",
            title: "CET 成绩查询",
            tag: "考试服务",
            detail: "官方成绩查询入口。",
            urlString: "https://cet.neea.edu.cn/cet/"
        )
    ]

    static let papers: [BankPaper] = {
        var items: [BankPaper] = []
        for year in 2016...2026 {
            let months = year == 2026 ? [6] : [6, 12]
            for month in months {
                for level in VocabularyLevel.allCases {
                    for set in 1...3 {
                        items.append(BankPaper(
                            id: "paper-\(year)-\(month)-\(level.rawValue)-\(set)",
                            title: "\(year) 年 \(month) 月 \(level.shortTitle) 真题（第 \(set) 套）",
                            year: year,
                            month: month,
                            level: level,
                            set: set
                        ))
                    }
                }
            }
        }
        return items
    }()

    static let sampleArticles: [Article] = [
        Article(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            title: "The Hidden Cost of Convenience",
            createdAt: Date(timeIntervalSince1970: 1_760_000_000),
            translations: [
                0: "网购让生活比以往更方便。轻点几下，几乎任何东西都能在几天内送到家门口。然而，这种便利背后有代价，只是当我们盯着屏幕时很容易忽略。",
                1: "每一次配送都涉及包装、燃料，以及跨越仓库与道路的运输。商品页面上的低价很少包含这些隐性成本。它们由环境承担，最终也由我们所有人承担。",
                2: "这并不意味着我们应该放弃网购，而是意味着我们应该更有思考地购买：合并订单、尽可能选择更慢的配送，并问自己是否真的需要这件商品。便利是一种工具，而不是借口。"
            ],
            translatedAt: Date(timeIntervalSince1970: 1_760_000_100),
            bank: true,
            kind: "sample",
            level: "cet4"
        ),
        Article(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
            title: "Learning to Ask Better Questions",
            createdAt: Date(timeIntervalSince1970: 1_759_000_000),
            translations: [
                0: "孩子们不停地提问。天空为什么是蓝的？人为什么会生病？他们的好奇心似乎无穷无尽，而这是他们拥有的最强大的学习工具之一。",
                1: "随着年龄增长，我们中的许多人不再提问。我们担心显得愚蠢，或者假定答案早已知道。久而久之，这种沉默让我们的思维变得更窄，让我们的对话更无趣。",
                2: "更好的问题并不需要完美的知识，而需要专注与诚实：我漏掉了什么？我为什么相信这一点？谁可能不同意，为什么？一个好问题并不会显得软弱，它会打开一扇门。"
            ],
            translatedAt: Date(timeIntervalSince1970: 1_759_000_100),
            bank: true,
            kind: "sample",
            level: "cet4"
        ),
        Article(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
            title: "Why Cities Need Silence",
            createdAt: Date(timeIntervalSince1970: 1_758_000_000),
            translations: [
                0: "现代城市仿佛是为被听见而设计的。车流轰鸣，广告闪烁，音乐从每家店铺涌出。噪音被视为活力的标志，而安静常被误认为空洞。",
                1: "研究却讲述了另一个故事。持续的噪音会升高压力激素、干扰睡眠，并让专注变得更难。这些影响悄无声息地累积，而这正是它们容易被忽视的原因。",
                2: "保护安静的城市并不是要让人们沉默，而是在为思考、休息与交谈留出空间。安静并不是生命的缺席，而是让生命被察觉的条件。"
            ],
            translatedAt: Date(timeIntervalSince1970: 1_758_000_100),
            bank: true,
            kind: "sample",
            level: "cet6"
        )
    ]

    static func sampleContent(for id: UUID) -> String? {
        switch id.uuidString {
        case "A1000000-0000-0000-0000-000000000001":
            return "Online shopping has made life easier than ever. With a few taps, almost anything can arrive at our door within days. Yet this convenience carries costs that are easy to ignore when we are staring at a screen.\n\nEvery delivery involves packaging, fuel, and a journey across warehouses and roads. The cheap price on a product page rarely includes these hidden expenses. They are paid instead by the environment and, eventually, by all of us.\n\nNone of this means we should abandon online shopping. It means we should buy with more thought: combine orders, choose slower delivery when possible, and ask whether we truly need the item. Convenience is a tool, not an excuse."
        case "A1000000-0000-0000-0000-000000000002":
            return "Children ask questions constantly. Why is the sky blue? Why do people get sick? Their curiosity seems endless, and it is one of the most powerful learning tools they possess.\n\nAs we grow older, many of us stop asking. We worry about looking foolish, or we assume that the answer is already known. Over time, this silence makes our thinking narrower and our conversations duller.\n\nBetter questions do not require perfect knowledge. They require attention and honesty: What am I missing? Why do I believe this? Who might disagree, and why? A good question does not show weakness; it opens a door."
        case "A1000000-0000-0000-0000-000000000003":
            return "Modern cities are designed to be heard. Traffic roars, advertisements flash and music pours out of every shop. Noise is treated as a sign of energy, and quiet is often mistaken for emptiness.\n\nResearch tells a different story. Constant noise raises stress hormones, disturbs sleep, and makes concentration harder. The effects accumulate quietly, which is precisely why they are easy to dismiss.\n\nA city that protects quiet is not trying to silence its people. It is creating room for thought, rest, and conversation. Silence is not the absence of life; it is a condition that allows life to be noticed."
        default:
            return nil
        }
    }
}