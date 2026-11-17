import SwiftUI

struct StorageInfoView: View {
    @EnvironmentObject private var articleStore: ArticleStore
    @EnvironmentObject private var dictionary: DictionaryStore
    @EnvironmentObject private var favorites: FavoriteStore

    @State private var snapshot = StorageSnapshot()
    @State private var refreshedAt = Date()

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "版本 \(version)（\(build)）"
    }

    private var diskUsedBytes: Int64 {
        max(0, snapshot.diskTotalBytes - snapshot.diskFreeBytes)
    }

    private var diskRatio: Double {
        guard snapshot.diskTotalBytes > 0 else { return 0 }
        return Double(diskUsedBytes) / Double(snapshot.diskTotalBytes)
    }

    private var wordsText: String {
        let cet4 = dictionary.words(for: .cet4).count
        let cet6 = dictionary.words(for: .cet6).count
        return "\(cet4 + cet6) 个（四级 \(cet4) · 六级 \(cet6)）"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                memoryCard
                diskCard
                dataCard
                estimateCard
                footerCard
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Brand.pageBackground.ignoresSafeArea())
        .navigationTitle("存储与内存")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("刷新")
            }
        }
        .onAppear { refresh() }
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("应用内存占用", systemImage: "memorychip")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(versionText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(StorageReporter.format(snapshot.residentBytes))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Brand.accent)
                Text("当前运行内存")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text("这是本次运行实际占用的内存（resident），会随加载的文章、壁纸和图片变化。下拉或点右上角可刷新。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineSpacing(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var diskCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("手机存储")
                .font(.system(size: 15, weight: .bold))

            ProgressView(value: diskRatio)
                .tint(Brand.accent)

            HStack {
                Text("已用 \(StorageReporter.format(diskUsedBytes)) / 共 \(StorageReporter.format(snapshot.diskTotalBytes))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("可用 \(StorageReporter.format(snapshot.diskFreeBytes))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Brand.accent)
            }

            Text("本应用在 Documents 中占用 \(StorageReporter.format(snapshot.documentsBytes))，其中外观图片（壁纸/皮肤/启动图）约 \(StorageReporter.format(snapshot.appearanceBytes))。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineSpacing(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("数据明细")
                .font(.system(size: 15, weight: .bold))

            row("文章", "\(snapshot.articleCount) 篇")
            row("收藏", "\(snapshot.favoriteCount) 项")
            row("内置词库词条", wordsText)
            row("文章与译文文件", StorageReporter.format(snapshot.documentsBytes))
            row("外观图片", StorageReporter.format(snapshot.appearanceBytes))
            row("上次刷新", refreshedAt.formatted(date: .omitted, time: .standard))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var estimateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体积与内存说明")
                .font(.system(size: 15, weight: .bold))

            Text("安装包体积：源码约 227 KB，资源约 45 KB；编译后的安装包通常为 1–2 MB 量级（以实际打包结果为准）。")
            Text("运行内存：iOS 应用空壳基线约 20–40 MB；本应用加载词库与文章后，常见占用约 30–60 MB；同时加载大壁纸、多张组件图案或长文章时，峰值可能到 80–100 MB。")
            Text("内存大头是图片：壁纸（1280px）、组件图案（720px）、启动图（最长边 900px）解码为图像后，单张约 1–4 MB。减少同时显示的图片可明显降低占用。")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .lineSpacing(3)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var footerCard: some View {
        Text("提示：以上内存为设备上的真实读数；安装包大小需在 Mac 上用 Xcode 打包后才能精确查看。")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .lineSpacing(2)
            .padding(.horizontal, 4)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func refresh() {
        snapshot = StorageReporter.snapshot(
            articleCount: articleStore.articles.count,
            favoriteCount: favorites.wordCount() + favorites.sentenceCount(),
            wordCount: dictionary.words(for: .cet4).count + dictionary.words(for: .cet6).count
        )
        refreshedAt = Date()
    }
}