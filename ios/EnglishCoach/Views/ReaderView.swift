import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var store: ArticleStore
    @EnvironmentObject private var dictionary: DictionaryStore

    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var player: SpeechPlayer

    let articleID: UUID

    @AppStorage("readerFontSize") private var fontSize: Double = 17
    @AppStorage("readerReadMode") private var readMode = false
    @AppStorage("appTheme") private var themeRaw = ThemeMode.light.rawValue
    @AppStorage("showTranslations") private var showTranslations = true

    @State private var translating = false
    @State private var translatedCount = 0
    @State private var totalCount = 0
    @State private var errorMessage: String?
    @State private var wordSelection: WordCardSelection?
    @State private var selection = TokenSelection.empty
    @State private var selectionItem: SelectionSheetItem?
    @State private var showPlaybackSheet = false
    @State private var showMoreMenu = false

    private var article: Article? {
        store.article(withID: articleID)
    }

    var body: some View {
        Group {
            if let article = article {
                VStack(spacing: 0) {
                    readerToolbar(article)
                    ScrollView {
                        readerContent(article)
                    }
                    .overlay(alignment: .bottom) {
                        if selection.active, let item = selectionItem {
                            SelectionPanel(item: item) {
                                selection = .empty
                                selectionItem = nil
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .background {
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
                .navigationTitle(article.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
                .sheet(item: $wordSelection) { selected in
                    WordCardSheet(word: selected.word)
                        .presentationDetents([.height(400), .medium])
                        .presentationDragIndicator(.visible)
                }

                .sheet(isPresented: $showPlaybackSheet) {
                    PlaybackSheet(title: article.title) {
                        article.paragraphs
                    }
                    .presentationDetents([.medium, .large])
                }
                .confirmationDialog("阅读设置", isPresented: $showMoreMenu, titleVisibility: .visible) {
                    Button(showTranslations ? "隐藏译文" : "显示译文") {
                        showTranslations.toggle()
                    }
                    Button("重新翻译全文") {
                        startTranslate()
                    }
                    Button("朗读整篇文章") {
                        showPlaybackSheet = true
                    }
                    Button("取消", role: .cancel) {}
                }
            } else {
                ContentUnavailableView("文章不存在", systemImage: "doc.questionmark")
            }
        }
    }

    private func readerToolbar(_ article: Article) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolButton(skinKey: "tool-font-dec", title: "字号", glyph: "A−") {
                    changeFont(-1)
                }
                toolButton(skinKey: "tool-font-inc", title: "字号", glyph: "A+") {
                    changeFont(1)
                }
                toolButton(
                    skinKey: "tool-theme",
                    title: themeRaw == ThemeMode.dark.rawValue ? "浅色" : "深色",
                    systemImage: themeRaw == ThemeMode.dark.rawValue ? "sun.max.fill" : "moon.fill"
                ) {
                    toggleTheme()
                }
                toolButton(
                    skinKey: "tool-read-mode",
                    title: readMode ? "阅读中" : "阅读模式",
                    systemImage: readMode ? "eye.slash.fill" : "eye.fill"
                ) {
                    toggleReadMode()
                }
                toolButton(skinKey: "tool-translate", title: "翻译", systemImage: "character.book.closed") {
                    startTranslate()
                }
                toolButton(skinKey: "tool-play", title: "朗读", systemImage: "play.fill") {
                    showPlaybackSheet = true
                }
                NavigationLink {
                    VocabularyView(initialTab: .favorites)
                } label: {
                    toolLabel(skinKey: "tool-favorites", title: "收藏夹", systemImage: "star.fill")
                }
                .buttonStyle(.plain)
                toolButton(skinKey: "tool-more", title: "更多", systemImage: "ellipsis.circle") {
                    showMoreMenu = true
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private func toolButton(
        skinKey: String,
        title: String,
        glyph: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(glyph)
                    .font(.system(size: 16, weight: .heavy))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, height: 46)
            .skinnable(skinKey, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private func toolButton(
        skinKey: String,
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            toolLabel(skinKey: skinKey, title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func toolLabel(skinKey: String, title: String, systemImage: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Brand.accent)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 52, height: 46)
        .skinnable(skinKey, radius: 12)
    }

    private func readerContent(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            articleHeader(article)

            if readMode {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash.fill")
                    Text("阅读模式已开启，单词选中已关闭")
                }
                .font(.system(size: 11))
                .foregroundStyle(Brand.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.accent.opacity(0.1))
                )
            }

            if !article.isFullyTranslated, !translating {
                Button {
                    startTranslate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "character.book.closed")
                        Text("一键翻译全文")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .skinnable("reader-translate", radius: 14, gradient: true)
                }
                .buttonStyle(.plain)
            }

            if translating {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在翻译 \(translatedCount)/\(totalCount) 段…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Brand.cardBackground)
                )
            }

            if let errorMessage = errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
            }

            ForEach(Array(article.paragraphs.enumerated()), id: \.offset) { index, paragraph in
                paragraphCard(article: article, paragraph: paragraph, index: index)
            }

            if article.isFullyTranslated, !translating {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Brand.accent)
                    Text("全文翻译完成")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 120)
    }

    private func articleHeader(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.system(size: 24, weight: .bold))
            HStack(spacing: 5) {
                Text("\(article.wordCount) 词")
                Text("·")
                Text("\(article.paragraphs.count) 段")
                Text("·")
                Text("约 \(article.readingMinutes) 分钟")
                if article.isFullyTranslated {
                    Text("·")
                    Label("已翻译", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Brand.accent)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)

            Text(readMode
                 ? "当前处于阅读模式，单词选中已关闭"
                 : "单击单词查词；长按单词后继续点击其他单词，可组成句子并查看语法成分")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 2)
    }

    private func paragraphCard(article: Article, paragraph: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            WordTokensView(
                tokens: TokenItem.parse(paragraph),
                paragraphIndex: index,
                selection: selection,
                readMode: readMode,
                fontSize: fontSize,
                onTap: { tokenIndex in
                    if selection.active {
                        extendSelection(index: index, tokenIndex: tokenIndex)
                    } else {
                        openWord(paragraph: paragraph, tokenIndex: tokenIndex)
                    }
                },
                onLongPress: { tokenIndex in
                    beginSelection(index: index, tokenIndex: tokenIndex)
                }
            )

            if showTranslations, let translation = article.translations[index] {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Brand.accent.opacity(0.45))
                        .frame(width: 3)
                    Text(translation)
                        .font(.system(size: max(13, fontSize - 2)))
                        .foregroundStyle(Brand.translations)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .skinnable("para-\(article.id.uuidString)-\(index)", radius: 18)
    }

    private func openWord(paragraph: String, tokenIndex: Int) {
        let tokens = TokenItem.parse(paragraph)
        guard tokenIndex >= 0, tokenIndex < tokens.count else { return }
        guard let key = tokens[tokenIndex].lookupKey else { return }
        wordSelection = WordCardSelection(word: key)
    }

    private func beginSelection(index: Int, tokenIndex: Int) {
        selection = TokenSelection(paragraph: index, anchor: tokenIndex, focus: tokenIndex, active: true)
        presentSelectionSheet(index: index)
    }

    private func extendSelection(index: Int, tokenIndex: Int) {
        if selection.paragraph != index {
            selection = TokenSelection(paragraph: index, anchor: tokenIndex, focus: tokenIndex, active: true)
        } else {
            selection.focus = tokenIndex
        }
        presentSelectionSheet(index: index)
    }

    private func presentSelectionSheet(index: Int) {
        guard let article = article else { return }
        let paragraphs = article.paragraphs
        guard index >= 0, index < paragraphs.count else { return }

        let tokens = TokenItem.parse(paragraphs[index])
        let low = min(selection.anchor, selection.focus)
        let high = max(selection.anchor, selection.focus)
        guard low >= 0, high < tokens.count else { return }

        let text = tokens[low...high].map(\.text).joined(separator: " ")
        let wordCount = high - low + 1
        let analysis = SentenceAnalyzer.analyze(text, isVerb: dictionary.isVerbWord)

        selectionItem = SelectionSheetItem(
            text: text,
            analysis: analysis,
            wordCount: wordCount
        )
    }

    private func changeFont(_ delta: Double) {
        fontSize = min(24, max(15, fontSize + delta))
    }

    private func toggleTheme() {
        themeRaw = themeRaw == ThemeMode.dark.rawValue
            ? ThemeMode.light.rawValue
            : ThemeMode.dark.rawValue
    }

    private func toggleReadMode() {
        readMode.toggle()
        if readMode {
            selection = .empty
            selectionItem = nil
        }
    }

    private func startTranslate() {
        guard !translating, let current = article else { return }

        var prepared = current
        let paragraphs = prepared.paragraphs
        guard !paragraphs.isEmpty else { return }

        if prepared.isFullyTranslated {
            prepared.translations = [:]
            store.update(prepared)
        }

        let initial = prepared
        translating = true
        errorMessage = nil
        totalCount = paragraphs.count
        translatedCount = paragraphs.indices.filter { initial.translations[$0] != nil }.count

        Task {
            var working = initial
            for (index, paragraph) in paragraphs.enumerated() {
                if working.translations[index] != nil { continue }
                do {
                    let translation = try await TranslationService.shared.translateParagraph(paragraph)
                    working.translations[index] = translation
                    working.translatedAt = Date()
                    store.update(working)
                    translatedCount = paragraphs.indices.filter { working.translations[$0] != nil }.count
                } catch {
                    errorMessage = "第 \(index + 1) 段翻译失败：\(error.localizedDescription)"
                    break
                }
            }
            translating = false
            if errorMessage == nil {
                working.translatedAt = Date()
                store.update(working)
            }
        }
    }
}