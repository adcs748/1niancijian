import Foundation
import Combine
import UIKit
import Photos

struct BackupFile: Identifiable {
    let id = UUID()
    let name: String
    let data: Data
    let mime: String
    var size: Int { data.count }
}

struct BackupRecord: Identifiable, Codable, Hashable {
    var id: String
    var createdAt: Date
    var fileCount: Int
    var totalBytes: Int
    var status: String
    var server: String
}

@MainActor
final class BackupService: ObservableObject {
    static let shared = BackupService()

    @Published private(set) var records: [BackupRecord] = []
    @Published private(set) var isUploading = false
    @Published private(set) var statusText = ""
    @Published private(set) var progress = 0.0

    @Published var serverURL: String
    @Published var token: String

    private let recordsURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordsURL = directory.appendingPathComponent("backup-records.json")
        serverURL = UserDefaults.standard.string(forKey: "backupServerURL") ?? ""
        token = UserDefaults.standard.string(forKey: "backupToken") ?? ""
        load()
    }

    func saveSettings() {
        UserDefaults.standard.set(serverURL, forKey: "backupServerURL")
        UserDefaults.standard.set(token, forKey: "backupToken")
        statusText = "服务器配置已保存"
    }

    func requestPhotoAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }

    func collectRecentPhotos(limit: Int) async -> [BackupFile] {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = max(1, limit)

        let result = PHAsset.fetchAssets(with: .image, options: options)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        var files: [BackupFile] = []
        for (index, asset) in assets.enumerated() {
            statusText = "正在读取照片 \(index + 1)/\(assets.count)…"
            if let data = await imageData(for: asset) {
                files.append(BackupFile(name: "photo-\(index + 1).jpg", data: data, mime: "image/jpeg"))
            }
        }
        statusText = ""
        return files
    }

    func upload(files: [BackupFile]) async {
        guard !files.isEmpty, !isUploading else { return }

        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard !base.isEmpty else {
            statusText = "请先配置备份服务器地址"
            return
        }

        isUploading = true
        progress = 0
        statusText = "准备备份…"
        let batchId = "B" + String(Int(Date().timeIntervalSince1970))
        let totalBytes = files.reduce(0) { $0 + $1.size }
        var failed = 0

        for (index, file) in files.enumerated() {
            statusText = "正在上传 \(index + 1)/\(files.count)：\(file.name)"
            do {
                try await uploadOne(file, base: base, batchId: batchId)
            } catch {
                failed += 1
            }
            progress = Double(index + 1) / Double(files.count)
        }

        records.insert(
            BackupRecord(
                id: batchId,
                createdAt: Date(),
                fileCount: files.count,
                totalBytes: totalBytes,
                status: failed > 0 ? "partial" : "uploaded",
                server: base
            ),
            at: 0
        )
        if records.count > 50 {
            records = Array(records.prefix(50))
        }
        save()

        isUploading = false
        statusText = failed > 0 ? "备份完成，\(failed) 个文件失败" : "备份完成"
    }

    private func imageData(for asset: PHAsset) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            var result: Data?
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                result = data
            }
            return result
        }.value
    }

    private func uploadOne(_ file: BackupFile, base: String, batchId: String) async throws {
        guard let url = URL(string: base + "/api/backups/" + batchId + "/files") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(token.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = multipartBody(file: file, boundary: boundary)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func multipartBody(file: BackupFile, boundary: String) -> Data {
        var body = Data()

        func append(_ text: String) {
            body.append(Data(text.utf8))
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.name)\"\r\n")
        append("Content-Type: \(file.mime)\r\n\r\n")
        body.append(file.data)
        append("\r\n--\(boundary)--\r\n")
        return body
    }

    private func load() {
        guard let data = try? Data(contentsOf: recordsURL),
              let decoded = try? JSONDecoder().decode([BackupRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: recordsURL, options: .atomic)
    }
}