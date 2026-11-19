import SwiftUI

enum VocabularyTab: String, CaseIterable, Identifiable {
    case cet4
    case cet6
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cet4: return "四级"
        case .cet6: return "六级"
        case .favorites: return "收藏夹"
        }
    }

    var level: VocabularyLevel? {
        switch self {
        case .cet4: return .cet4
        case .cet6: return .cet6
        case .favorites: return nil
        }
    }
}

struct VocabularyView: View {
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore


    @State private var tab: VocabularyTab
    @State private var search = ""
    @State private var wordSelection: WordCardSelection?
    @State private var sentenceSelection: FavoriteItem?
    @State private var showPlayback = false

    init(initialTab: VocabularyTab = .cet4) {
        _tab = State(initialValue: initialTab)
    }

    private var words: [WordEntry] {
        guard let level = tab.level else { return [] }
        let all = dictionary.words(for: level)
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.word.lowercased().contains(query) || $0.meaning.contains(query)
        }
    }

    private var favoriteItems: [FavoriteItem] {
        favorites.filtered(search)
    }

    private var playbackTitle: String {
        switch tab {
        case .cet4: return "四级词汇"
        case .cet6: return "六级词汇"
        case .favorites: return "收藏夹单词"
        }
    }

    private func playbackItems() -> [String] {
        switch tab {
        case .cet4, .cet6:
            return words.map { $0.word + "\n" + $0.meaning }
        case .favorites:
            return favoriteItems.filter { $0.type == .word }.map { $0.text + "\n" + ($0.translation ?? "") }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("词汇范围", selection: $tab) {
                ForEach(VocabularyTab.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 10)

            searchBar

            ScrollView {
                LazyVStack(spacing: 8) {
                    headerCount

                    if tab == .favorites {
                        if favoriteItems.isEmpty {
                            emptyState(search.isEmpty ? "收藏夹还是空的\n阅读时长按单词组句，或点击单词收藏" : "没有找到匹配的收藏")
                        } else {
                            ForEach(favoriteItems) { item in
                                favoriteRow(item)
                            }
                        }
                    } else {
                        if words.isEmpty {
                            emptyState("没有找到匹配的单词")
                        } else {
                            ForEach(Array(words.enumerated()), id: \.element.id) { index, entry in
                                wordRow(entry, index: index + 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
        .background(Brand.pageBackground.ignoresSafeArea())
        .navigationTitle("词汇学习")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPlayback = true
                } label: {
                    Image(systemName: "play.circle")
                }
                .accessibilityLabel("自动播放")
            }
        }
        .sheet(item: $wordSelection) { selection in
            WordCardSheet(word: selection.word)
                .presentationDetents([.height(400), .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $sentenceSelection) { item in
            FavoriteSentenceSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlayback) {
            PlaybackSheet(title: playbackTitle) {
                playbackItems()
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: tab) { _, _ in
            search = ""
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索单词、释义或收藏内容", text: $search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .skinnable("vocab-search", radius: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var headerCount: some View {
        HStack {
            Text(tab == .favorites
                 ? "共 \(favoriteItems.count) 条收藏"
                 : "共 \(words.count) 个单词")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func wordRow(_ entry: WordEntry, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 22, alignment: .trailing)

            Button {
                wordSelection = WordCardSelection(word: entry.word)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.word)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        if !entry.phonetic.isEmpty {
                            Text(entry.phonetic)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        if favorites.isFavorited(.word, text: entry.word) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(entry.meaning)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                SpeechService.shared.speak(entry.word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Brand.accent.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .skinnable("word-\(entry.normalizedWord)", radius: 14)
    }

    @ViewBuilder
    private func favoriteRow(_ item: FavoriteItem) -> some View {
        if item.type == .sentence {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    sentenceSelection = item
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("句子")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Brand.accent)
                        Text(item.text)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(item.translation.isEmpty ? "暂无译文" : item.translation)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    SpeechService.shared.speak(item.text)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.accent)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Button {
                    favorites.remove(item)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .skinnable("fav-\(item.id.uuidString)", radius: 14)
        } else {
            HStack(spacing: 10) {
                Button {
                    wordSelection = WordCardSelection(word: item.text)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("单词")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Brand.accent)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(item.text)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            if !item.phonetic.isEmpty {
                                Text(item.phonetic)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(item.translation)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    SpeechService.shared.speak(item.text)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.accent)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Button {
                    favorites.remove(item)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .skinnable("fav-\(item.id.uuidString)", radius: 14)
        }
    }

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}