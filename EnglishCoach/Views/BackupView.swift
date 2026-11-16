import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct BackupView: View {
    @EnvironmentObject private var backup: BackupService
    @AppStorage("backupConsent") private var consent = false

    @State private var pending: [BackupFile] = []
    @State private var showFileImporter = false
    @State private var photoLimit = 20
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                consentCard
                serverCard
                pickCard
                pendingCard
                recordsCard
            }
            .padding(20)
            .padding(.bottom, 120)
        }
        .background(Brand.pageBackground.ignoresSafeArea())
        .navigationTitle("安全备份")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item, .image, .movie, .pdf, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleFiles(result)
        }
        .alert("提示", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("客户数据备份")
                .font(.system(size: 18, weight: .bold))
            Text("仅上传你在下方主动选择的文件，或经授权后从相册导出的照片；不会扫描其他 App 或系统文件。备份保存到你配置的服务器。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.08))
        )
    }

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("我同意将选中的照片/文件上传到指定服务器", isOn: $consent)
                .font(.system(size: 13, weight: .semibold))
            Text("可随时在 iOS 设置中撤销照片权限；未勾选时不会上传任何内容。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("备份服务器")
                .font(.system(size: 15, weight: .bold))

            TextField("https://你的备份服务器", text: $backup.serverURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.system(size: 13))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.pageBackground)
                )

            SecureField("访问令牌（Token）", text: $backup.token)
                .font(.system(size: 13))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.pageBackground)
                )

            HStack {
                Button {
                    backup.saveSettings()
                } label: {
                    Text("保存配置")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Brand.accent.opacity(0.12)))
                        .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                if !backup.serverURL.isEmpty, let url = URL(string: backup.serverURL) {
                    Link("打开服务器", destination: url)
                        .font(.system(size: 12, weight: .medium))
                }
            }

            Text("提示：需要先部署 backup-server（见项目 README），并建议使用 HTTPS。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var pickCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择要备份的内容")
                .font(.system(size: 15, weight: .bold))

            HStack {
                Text("相册照片数量")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("数量", selection: $photoLimit) {
                    Text("10 张").tag(10)
                    Text("20 张").tag(20)
                    Text("50 张").tag(50)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            HStack(spacing: 10) {
                Button {
                    loadPhotos()
                } label: {
                    Label("读取最近照片", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                        .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)
                .disabled(busy || !consent)

                Button {
                    showFileImporter = true
                } label: {
                    Label("选择文件", systemImage: "folder")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                        .foregroundStyle(Brand.accent)
                }
                .buttonStyle(.plain)
                .disabled(!consent)
            }

            if busy {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(backup.statusText.isEmpty ? "处理中…" : backup.statusText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Text("iOS 只能读取用户授权的照片/视频，以及你通过文件选择器选中的文档；无法读取其他 App 或系统文件。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("待备份 · \(pending.count) 个文件")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(ByteCountFormatter.string(
                    fromByteCount: Int64(pending.reduce(0) { $0 + $1.size }),
                    countStyle: .file
                ))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            if pending.isEmpty {
                Text("还没有选择文件")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(pending) { file in
                    HStack {
                        Text(file.name)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }

            if backup.isUploading {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: backup.progress)
                    Text(backup.statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    startUpload()
                } label: {
                    Label("开始备份", systemImage: "shield.checkered")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(pending.isEmpty || backup.isUploading || !consent)

                Button {
                    pending = []
                } label: {
                    Text("清空")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .disabled(backup.isUploading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("备份记录")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(backup.records.count) 次")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if backup.records.isEmpty {
                Text("暂无备份记录")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(backup.records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.createdAt.formatted(date: .numeric, time: .shortened))
                                .font(.system(size: 12, weight: .medium))
                            Text("\(record.fileCount) 个文件 · " +
                                 ByteCountFormatter.string(fromByteCount: Int64(record.totalBytes), countStyle: .file))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(record.status == "uploaded" ? "已上传" : "部分失败")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(
                                    record.status == "uploaded"
                                        ? Color.green.opacity(0.12)
                                        : Color.orange.opacity(0.15)
                                )
                            )
                            .foregroundStyle(record.status == "uploaded" ? Color.green : Color.orange)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.cardBackground)
        )
    }

    private func loadPhotos() {
        guard consent else {
            errorMessage = "请先勾选“我同意将选中的照片/文件上传到指定服务器”。"
            return
        }
        busy = true
        errorMessage = nil
        Task {
            let granted = await backup.requestPhotoAccess()
            guard granted else {
                busy = false
                errorMessage = "未获得照片访问权限。请在 iOS 设置 → 隐私与安全性 → 照片 中允许「一念词间」访问。"
                return
            }
            let files = await backup.collectRecentPhotos(limit: photoLimit)
            pending.append(contentsOf: files)
            busy = false
            if files.isEmpty {
                errorMessage = "没有读取到照片，请确认相册中有图片。"
            }
        }
    }

    private func startUpload() {
        guard consent else {
            errorMessage = "请先勾选“我同意将选中的照片/文件上传到指定服务器”。"
            return
        }
        let files = pending
        Task {
            await backup.upload(files: files)
            pending = []
        }
    }

    private func handleFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var files: [BackupFile] = []
            for url in urls.prefix(100) {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else { continue }
                guard data.count <= 200 * 1024 * 1024 else { continue }

                let ext = url.pathExtension.lowercased()
                let mime: String
                switch ext {
                case "png": mime = "image/png"
                case "jpg", "jpeg": mime = "image/jpeg"
                case "pdf": mime = "application/pdf"
                case "mp4": mime = "video/mp4"
                case "mov": mime = "video/quicktime"
                default: mime = "application/octet-stream"
                }

                files.append(BackupFile(name: url.lastPathComponent, data: data, mime: mime))
            }
            pending.append(contentsOf: files)
            if files.isEmpty {
                errorMessage = "没有读取到可用文件（单文件需小于 200MB）。"
            }
        case .failure(let error):
            errorMessage = "读取文件失败：\(error.localizedDescription)"
        }
    }
}