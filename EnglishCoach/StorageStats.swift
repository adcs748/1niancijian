import Foundation
import Darwin

struct StorageSnapshot {
    var residentBytes: UInt64 = 0
    var documentsBytes: Int64 = 0
    var appearanceBytes: Int64 = 0
    var diskTotalBytes: Int64 = 0
    var diskFreeBytes: Int64 = 0
    var articleCount: Int = 0
    var favoriteCount: Int = 0
    var wordCount: Int = 0
}

enum StorageReporter {
    static func snapshot(articleCount: Int, favoriteCount: Int, wordCount: Int) -> StorageSnapshot {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appearance = documents.appendingPathComponent("Appearance", isDirectory: true)

        var result = StorageSnapshot()
        result.residentBytes = residentMemory()
        result.documentsBytes = directorySize(documents)
        result.appearanceBytes = directorySize(appearance)

        if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            result.diskTotalBytes = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            result.diskFreeBytes = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        }

        result.articleCount = articleCount
        result.favoriteCount = favoriteCount
        result.wordCount = wordCount
        return result
    }

    static func directorySize(_ url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]) else {
                continue
            }
            if values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
            }
        }
        return total
    }

    static func residentMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(info.resident_size)
    }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
    }

    static func format(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}