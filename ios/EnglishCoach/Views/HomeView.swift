import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var articleStore: ArticleStore
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore
    @EnvironmentObject private var appearance: AppearanceStore

    @State private var showImportSheet = false
    @State private var importBank = false
    @State private var showAppearance = false
    @State private var dailyWord: WordEntry?
    @State private var wordSelection: WordCardSelection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                importCard
                bankCard
                dailyCard
                levelRow
                favoritesCard
                backupCard
                storageCard
                articlesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .background(backgroundLayer)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showImportSheet) {
            ImportSheet(bank: importBank)
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceView()
                .presentationDetents([.large])
        }
        .sheet(item: $wordSelection) { selection in
            WordCardSheet(word: selection.word)
                .presentationDetents([.height(400), .medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if dailyWord == nil {
                dailyWord = randomWord()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Brand.pageBackground
            if let wallpaper = appearance.wallpaperImage {
                Image(uiImage: wallpaper)
                    .resizable()
                    .scaledToFill()
                    .opacity(appearance.wallpaperOpacity)
            }
        }
        .clipped()
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .top) {
            Image(uiImage: appearance.currentIcon(size: 44))
                .resizable()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("一念词间")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                Text("四六级英语 · 导入 · 翻译 · 词汇")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showAppearance = true
            } label: {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Brand.cardBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("外观与壁纸")
        }
        .padding(.top, 12)
    }

    private var importCard: some View {
        Button {
            importBank = false
            showImportSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.18)))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.85)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("导入英语文章")
                        .font(.system(size: 20, weight: .bold))
                    Text("粘贴文本或从文件导入，自动生成中文译文")
                        .font(.system(size: 13))
                        .opacity(0.86)
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-import", radius: 22, gradient: true)
            .shadow(color: Brand.accent.opacity(0.25), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var bankCard: some View {
        NavigationLink {
            QuestionBankView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))

                VStack(alignment: .leading, spacing: 3) {
                    Text("四六级真题题库")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("模拟练习 · 历年真题目录 · 官方大纲")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("\(QuestionBank.papers.count) 条目录")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-bank", radius: 18)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dailyCard: some View {
        if let word = dailyWord {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("今日词汇 · \(word.level.shortTitle)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Brand.accent)
                    Spacer()
                    Button {
                        dailyWord = randomWord()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("换一个单词")
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                    if !word.phonetic.isEmpty {
                        Text(word.phonetic)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        SpeechService.shared.speak(word.word)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Brand.accent)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Brand.accent.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("朗读")
                }

                Text(word.meaning)
                    .font(.system(size: 14))
                    .foregroundStyle(Brand.translations)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Button {
                    wordSelection = WordCardSelection(word: word.word)
                } label: {
                    Text("查看完整释义 ›")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-daily", radius: 18)
        }
    }

    private var levelRow: some View {
        HStack(spacing: 14) {
            levelCard(.cet4)
            levelCard(.cet6)
        }
    }

    private func levelCard(_ level: VocabularyLevel) -> some View {
        NavigationLink {
            VocabularyView(initialTab: level == .cet4 ? .cet4 : .cet6)
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text(level.shortTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Brand.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                Text(level.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("\(dictionary.words(for: level).count) 个核心词")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable(level == .cet4 ? "home-level-cet4" : "home-level-cet6", radius: 18)
        }
        .buttonStyle(.plain)
    }

    private var backupCard: some View {
        NavigationLink {
            BackupView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("安全备份")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("备份到你的服务器 · 客户数据追回")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-backup", radius: 18)
        }
        .buttonStyle(.plain)
    }

    private var storageCard: some View {
        NavigationLink {
            StorageInfoView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "memorychip")
                    .font(.system(size: 20))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Brand.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("存储与内存")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("查看应用内存、存储占用与数据明细")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-storage", radius: 18)
        }
        .buttonStyle(.plain)
    }

    private var favoritesCard: some View {
        NavigationLink {
            VocabularyView(initialTab: .favorites)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 3) {
                    Text("我的收藏")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(favoriteSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skinnable("home-favorites", radius: 18)
        }
        .buttonStyle(.plain)
    }

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的文章")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                if !articleStore.personalArticles.isEmpty {
                    Text("\(articleStore.personalArticles.count) 篇")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            if articleStore.personalArticles.isEmpty {
                emptyArticles
            } else {
                VStack(spacing: 10) {
                    ForEach(articleStore.personalArticles) { article in
                        NavigationLink {
                            ReaderView(articleID: article.id)
                        } label: {
                            ArticleRowCard(article: article)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                articleStore.delete(article)
                            } label: {
                                Label("删除文章", systemImage: "trash")
                            }
                        }
                        .skinnable("article-\(article.id.uuidString)", radius: 18)
                    }
                }
            }
        }
    }

    private var emptyArticles: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)
            Text("还没有文章，导入一篇开始精读吧")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var favoriteSummary: String {
        let words = favorites.wordCount()
        let sentences = favorites.sentenceCount()
        if words == 0, sentences == 0 {
            return "阅读时长按单词组句，或点击单词收藏"
        }
        var parts = ["\(words) 个单词"]
        if sentences > 0 { parts.append("\(sentences) 句句子") }
        return parts.joined(separator: " · ")
    }

    private func randomWord() -> WordEntry? {
        let pool = dictionary.words(for: .cet4) + dictionary.words(for: .cet6)
        return pool.randomElement()
    }
}