import SwiftUI
import UIKit

enum BankSection: String, CaseIterable, Identifiable {
    case all
    case samples
    case index
    case official

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .samples: return "可阅读"
        case .index: return "真题目录"
        case .official: return "官方资料"
        }
    }
}

private struct BankYearGroup: Identifiable {
    let id: Int
    let year: Int
    let papers: [BankPaper]
}

struct QuestionBankView: View {
    @EnvironmentObject private var articleStore: ArticleStore


    @State private var levelFilter = "all"
    @State private var section: BankSection = .all
    @State private var selectedPaper: BankPaper?
    @State private var showImport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero

                Picker("级别", selection: $levelFilter) {
                    Text("全部").tag("all")
                    Text("CET-4").tag("cet4")
                    Text("CET-6").tag("cet6")
                }
                .pickerStyle(.segmented)

                Picker("分区", selection: $section) {
                    ForEach(BankSection.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                if section == .all || section == .samples {
                    samplesSection
                }
                if section == .all || section == .index {
                    indexSection
                }
                if section == .all || section == .official {
                    officialSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 120)
        }
        .background(Brand.pageBackground.ignoresSafeArea())
        .navigationTitle("真题题库")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .accessibilityLabel("导入真题")
            }
        }
        .sheet(isPresented: $showImport) {
            ImportSheet(bank: true)
                .presentationDetents([.large])
        }
        .sheet(item: $selectedPaper) { paper in
            BankPaperSheet(paper: paper)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("四六级真题资料")
                .font(.system(size: 18, weight: .bold))
            Text("内置原创模拟练习可直接阅读；历年真题以目录索引呈现。真题版权归教育部教育考试院，请通过官方或已授权渠道获取后导入。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.accent.opacity(0.08))
        )
    }

    private var bankArticles: [Article] {
        articleStore.articles
            .filter { $0.bank }
            .filter { levelFilter == "all" || $0.level == levelFilter }
            .sorted { $0.title < $1.title }
    }

    private var filteredPapers: [BankPaper] {
        QuestionBank.papers.filter {
            levelFilter == "all" || $0.level.rawValue == levelFilter
        }
    }

    private var paperGroups: [BankYearGroup] {
        let grouped = Dictionary(grouping: filteredPapers) { $0.year }
        return grouped.keys.sorted(by: >).map { year in
            BankYearGroup(
                id: year,
                year: year,
                papers: (grouped[year] ?? []).sorted { $0.month > $1.month }
            )
        }
    }

    private var samplesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("可阅读资料", detail: "保留翻译 / 选词 / 语法 / 收藏 / 朗读")

            if bankArticles.isEmpty {
                emptyCard("该级别暂无资料，可点击右上角导入真题")
            } else {
                ForEach(bankArticles) { article in
                    NavigationLink {
                        ReaderView(articleID: article.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 6) {
                                Text(article.kind == "sample" ? "模拟练习" : "我的真题")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Brand.accent)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Brand.accent.opacity(0.12)))
                                Text(article.levelBadge)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                Spacer()
                                Text("\(article.wordCount) 词")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }

                            Text(article.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text(article.preview)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .skinnable("bank-sample-\(article.id.uuidString)", radius: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var indexSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("历年真题目录", detail: "仅目录 · 不含正文")

            if paperGroups.isEmpty {
                emptyCard("该级别暂无目录")
            } else {
                ForEach(paperGroups) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(group.year) 年")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        ForEach(group.papers) { paper in
                            Button {
                                selectedPaper = paper
                            } label: {
                                HStack {
                                    Text(paper.title)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("查看")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Brand.accent)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .skinnable("bank-paper-\(paper.id)", radius: 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private var officialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("官方资料", detail: "中国教育考试网")

            ForEach(QuestionBank.officialSources) { source in
                Button {
                    open(source.urlString)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Text(source.detail)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 0)

                        Text(source.tag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .skinnable("bank-official-\(source.id)", radius: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionTitle(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Brand.cardBackground)
            )
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct BankPaperSheet: View {
    @Environment(\.dismiss) private var dismiss

    let paper: BankPaper

    @State private var showImport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(paper.title)
                        .font(.system(size: 18, weight: .bold))

                    Text("真题全文的版权归教育部教育考试院所有，本应用不内置未授权的真题正文。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)

                    Text("如果你已通过官方或授权渠道获得该套试卷的文本，点击「去导入」把内容粘贴进来，即可使用翻译、点词、长按组句、语法分析、收藏与朗读等全部阅读功能。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)

                    Button {
                        showImport = true
                    } label: {
                        Label("我已获取，去导入", systemImage: "doc.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Brand.accent.opacity(0.12))
                            )
                            .foregroundStyle(Brand.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: "https://cet.neea.edu.cn/res/Home/1704/55b02330ac17274664f06d9d3db8249d.pdf") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("查看官方考试大纲", systemImage: "doc.text")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 10)
                }
                .padding(20)
            }
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationTitle("真题目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showImport) {
                ImportSheet(bank: true)
                    .presentationDetents([.large])
            }
        }
    }
}