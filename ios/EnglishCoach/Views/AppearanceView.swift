import SwiftUI
import PhotosUI
import UIKit
import Foundation

struct AppearanceView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var articleStore: ArticleStore
    @EnvironmentObject private var favorites: FavoriteStore
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.dismiss) private var dismiss

    @State private var wallpaperPicker: PhotosPickerItem?
    @State private var launchPicker: PhotosPickerItem?
    @State private var wallpaperOpacity: Double = 0.3
    @State private var launchSize: Double = 60
    @State private var launchDuration: Double = 2.2
    @State private var launchEnabled = true
    @State private var launchFit = "contain"
    @State private var iconPicker: PhotosPickerItem?
    @State private var iconExportURL: URL?
    @State private var showIconGuide = false
    @State private var exportArticles = true
    @State private var exportFavorites = true
    @State private var exportAppearance = true
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    iconSection
                    wallpaperSection
                    launchSection
                    layoutSection
                    dataSection

                    Button {
                        appearance.resetAll()
                        syncState()
                        toast.show("已恢复默认外观")
                    } label: {
                        Text("恢复默认外观")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationTitle("外观与壁纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                syncState()
                prepareIconExport()
            }
            .onChange(of: wallpaperPicker) { _, item in
                loadWallpaper(item)
            }
            .onChange(of: launchPicker) { _, item in
                loadLaunch(item)
            }
            .onChange(of: iconPicker) { _, item in
                loadIcon(item)
            }
            .onChange(of: wallpaperOpacity) { _, value in
                appearance.setWallpaperOpacity(value)
            }
            .onChange(of: launchSize) { _, value in
                appearance.setLaunchSize(value)
            }
            .onChange(of: launchDuration) { _, value in
                appearance.setLaunchDuration(value)
            }
            .onChange(of: launchEnabled) { _, value in
                appearance.setLaunchEnabled(value)
            }
            .onChange(of: launchFit) { _, value in
                appearance.setLaunchFit(value)
            }
            .alert("设置自定义桌面图标", isPresented: $showIconGuide) {
                Button("打开快捷指令") {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text("1. 点击「导出 1024 图标」，保存到相册或文件。\n2. 在「快捷指令」中新建“打开 App”快捷方式，选择一念词间。\n3. 添加到主屏幕时选择导出的图片。\n\niOS 不允许 App 直接替换桌面图标，这是系统限制；快捷指令是使用任意相册图片作为桌面图标的官方方式。")
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("应用图标与桌面图标")
                .font(.system(size: 15, weight: .bold))

            HStack(spacing: 12) {
                Image(uiImage: appearance.currentIcon(size: 64))
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                Text("选择内置样式或从相册选择图片，图标会显示在首页。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                iconStyleButton("blue", "蓝色")
                iconStyleButton("ink", "墨黑")
                iconStyleButton("sunset", "日落")
                iconStyleButton("forest", "森林")
            }

            PhotosPicker(selection: $iconPicker, matching: .images) {
                Label("从相册选择图标", systemImage: "photo")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }

            if appearance.iconConfig.fileName != nil {
                Button {
                    appearance.clearIcon()
                    prepareIconExport()
                } label: {
                    Text("恢复默认图标")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.87, green: 0.91, blue: 1.0),
                                Color(red: 1.0, green: 0.93, blue: 0.89)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 6) {
                    Image(uiImage: appearance.currentIcon(size: 64))
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    Text("一念词间")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.75))
                }
            }
            .frame(height: 126)

            if let url = iconExportURL {
                ShareLink(item: url) {
                    Label("导出 1024 图标", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                        .foregroundStyle(Brand.accent)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在准备图标…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showIconGuide = true
            } label: {
                Label("如何设置到桌面", systemImage: "questionmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)

            Text("iOS 不允许 App 直接用相册图片替换桌面图标。导出图标后，可用「快捷指令」新建“打开 App”快捷方式并添加到主屏幕，选择这张图片即可得到自定义桌面图标。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private func iconStyleButton(_ style: String, _ title: String) -> some View {
        Button {
            appearance.setIconStyle(style)
            prepareIconExport()
        } label: {
            Circle()
                .fill(styleColor(style))
                .frame(width: 36, height: 36)
                .overlay {
                    if appearance.iconConfig.type == "builtin", appearance.iconConfig.style == style {
                        Circle().strokeBorder(Color.primary.opacity(0.55), lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func styleColor(_ style: String) -> Color {
        switch style {
        case "ink": return Color(red: 0.16, green: 0.16, blue: 0.18)
        case "sunset": return Color(red: 1.0, green: 0.48, blue: 0.35)
        case "forest": return Color(red: 0.12, green: 0.54, blue: 0.44)
        default: return Brand.accent
        }
    }

    @MainActor
    private func loadIcon(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                appearance.updateIconImage(data: data)
                prepareIconExport()
                toast.show("应用图标已更新")
            } else {
                toast.show("图标读取失败，请换一张试试")
            }
        }
    }

    @MainActor
    private func prepareIconExport() {
        guard let data = appearance.iconExportData() else {
            iconExportURL = nil
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NianCiJian-icon-1024.png")
        do {
            try data.write(to: url, options: .atomic)
            iconExportURL = url
        } catch {
            iconExportURL = nil
        }
    }

    private var wallpaperSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主界面壁纸")
                .font(.system(size: 15, weight: .bold))

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                if let image = appearance.wallpaperImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .opacity(max(0.35, appearance.wallpaperOpacity))
                } else {
                    Text("尚未选择壁纸")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            PhotosPicker(selection: $wallpaperPicker, matching: .images) {
                Label("从相册选择", systemImage: "photo.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }

            if appearance.wallpaperImage != nil {
                Button {
                    appearance.clearWallpaper()
                } label: {
                    Text("移除壁纸")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Text("透明度")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Slider(value: $wallpaperOpacity, in: 0...1)
                Text("\(Int(wallpaperOpacity * 100))%")
                    .font(.system(size: 12))
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var launchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("启动动画")
                .font(.system(size: 15, weight: .bold))
            Text("支持 JPG / PNG / GIF，尺寸、显示方式与时长均可调。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                launchPreview
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("当前格式：\(launchFormatLabel)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $launchPicker, matching: .images) {
                Label("选择图片", systemImage: "photo")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }

            if appearance.config.launch.fileName != nil {
                Button {
                    appearance.clearLaunch()
                    syncState()
                } label: {
                    Text("清除动画")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Text("尺寸")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Slider(value: $launchSize, in: 20...100)
                Text("\(Int(launchSize))%")
                    .font(.system(size: 12))
                    .frame(width: 40, alignment: .trailing)
            }

            Picker("显示方式", selection: $launchFit) {
                Text("完整").tag("contain")
                Text("铺满").tag("cover")
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Text("时长")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Slider(value: $launchDuration, in: 0.5...5)
                Text(String(format: "%.1fs", launchDuration))
                    .font(.system(size: 12))
                    .frame(width: 44, alignment: .trailing)
            }

            Toggle("每次启动播放", isOn: $launchEnabled)

            Button {
                appearance.previewLaunch()
                dismiss()
            } label: {
                Label("预览启动动画", systemImage: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("组件底层图案")
                .font(.system(size: 15, weight: .bold))
            Text("进入编辑模式后，点击任意卡片、工具栏按钮或列表项，即可为它单独选择相册图片。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Button {
                appearance.beginSkinEditing()
                dismiss()
            } label: {
                Label("进入组件图案编辑", systemImage: "hand.tap")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据导出")
                .font(.system(size: 15, weight: .bold))
            Text("导出为 JSON 数据包，可用 web-preview/viewer.html 查看；只包含你勾选的内容。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(2)

            Toggle("文章与图片识别记录", isOn: $exportArticles)
                .font(.system(size: 13))
            Toggle("收藏夹", isOn: $exportFavorites)
                .font(.system(size: 13))
            Toggle("外观配置", isOn: $exportAppearance)
                .font(.system(size: 13))

            Button {
                generateExport()
            } label: {
                Label("生成数据包", systemImage: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                    .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
            .disabled(!exportArticles && !exportFavorites && !exportAppearance)

            if let url = exportURL {
                ShareLink(item: url) {
                    Label("保存 / 分享数据包", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    @ViewBuilder
    private var launchPreview: some View {
        if let data = appearance.launchImageData {
            if appearance.launchIsGIF {
                GIFImageView(data: data)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        } else {
            VStack(spacing: 4) {
                Text("EnglishCoach")
                    .font(.system(size: 18, weight: .heavy))
                Text("四六级英语")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchFormatLabel: String {
        let type = appearance.config.launch.originalType
        if type.contains("gif") { return "GIF（保留动画）" }
        if type.contains("png") { return "PNG" }
        if type.contains("jpeg") { return "JPG" }
        return "默认品牌动画"
    }

    private func syncState() {
        wallpaperOpacity = appearance.wallpaperOpacity
        launchSize = appearance.config.launch.size
        launchDuration = appearance.config.launch.duration
        launchEnabled = appearance.config.launch.enabled
        launchFit = appearance.config.launch.fit
    }

    @MainActor
    private func loadWallpaper(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                appearance.updateWallpaper(data: data)
                toast.show("壁纸已更新")
            } else {
                toast.show("图片读取失败，请换一张试试")
            }
        }
    }

    @MainActor
    private func loadLaunch(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                toast.show("图片读取失败，请换一张试试")
                return
            }

            let detected = Self.detectType(data)
            let type = detected.isEmpty && UIImage(data: data) != nil ? "image/jpeg" : detected
            guard !type.isEmpty else {
                toast.show("启动动画仅支持 JPG / PNG / GIF")
                return
            }
            if type == "image/gif", data.count > 1_500_000 {
                toast.show("GIF 超过 1.5MB，请压缩后再试")
                return
            }

            appearance.updateLaunch(data: data, type: type)
            syncState()
            toast.show("启动动画已更新")
        }
    }

    private static func detectType(_ data: Data) -> String {
        guard data.count > 12 else { return "" }
        let bytes = [UInt8](data.prefix(12))
        if bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46 {
            return "image/gif"
        }
        if bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47 {
            return "image/png"
        }
        if bytes[0] == 0xFF, bytes[1] == 0xD8 {
            return "image/jpeg"
        }
        return ""
    }

    @MainActor
    private func generateExport() {
        guard exportArticles || exportFavorites || exportAppearance else {
            toast.show("请至少勾选一项导出内容")
            return
        }
        let package = ExportPackage(
            app: "一念词间",
            version: 1,
            exportedAt: Date(),
            articles: exportArticles ? articleStore.articles : nil,
            favorites: exportFavorites ? favorites.items : nil,
            appearance: exportAppearance ? appearance.config : nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(package) else {
            toast.show("数据包生成失败")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let name = "一念词间-数据包-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            exportURL = url
            toast.show("数据包已生成，可保存或分享")
        } catch {
            toast.show("写入文件失败，请重试")
        }
    }
}

private struct ExportPackage: Codable {
    var app: String
    var version: Int
    var exportedAt: Date
    var articles: [Article]?
    var favorites: [FavoriteItem]?
    var appearance: AppearanceConfig?
}