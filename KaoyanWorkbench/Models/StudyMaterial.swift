//
//  StudyMaterial.swift
//  KaoyanWorkbench
//
//  资料库：PDF / 图片 / 文字笔记。
//  可以同时关联到「某一天」和「某个进度项（章节）」。
//
//  注意：类型名刻意用 StudyMaterial 而不是 Material ——
//  SwiftUI 自带 Material 协议，同名会产生歧义。
//

import Foundation

// MARK: - 类型

enum StudyMaterialKind: String, Codable, CaseIterable, Identifiable {
    case pdf
    case image
    case text
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "图片"
        case .text: return "文字"
        case .other: return "文件"
        }
    }

    var symbolName: String {
        switch self {
        case .pdf: return "doc.richtext.fill"
        case .image: return "photo.fill"
        case .text: return "text.alignleft"
        case .other: return "paperclip"
        }
    }

    static func detect(fileName: String) -> StudyMaterialKind {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf":
            return .pdf
        case "png", "jpg", "jpeg", "heic", "heif", "webp", "gif", "tif", "tiff":
            return .image
        case "txt", "md", "markdown", "text", "rtf", "log":
            return .text
        default:
            return .other
        }
    }
}

// MARK: - 实体

struct StudyMaterial: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var kind: StudyMaterialKind

    /// 附件在 Materials 目录下的文件名；文字笔记为 nil
    var fileName: String?
    /// 文字笔记正文
    var body: String = ""
    /// 备注（哪本书、第几页、错在哪）
    var note: String = ""

    var subject: Subject?
    /// 关联的进度项（章节）
    var progressItemID: UUID?
    /// 关联的日期键 "yyyy-MM-dd"
    var dateKey: String?

    var createdAt: Date = Date()
    var fileSize: Int64 = 0

    var hasFile: Bool { fileName != nil }
    var hasBody: Bool { !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var fileURL: URL? {
        guard let fileName else { return nil }
        return MaterialStorage.url(for: fileName)
    }

    var sizeText: String {
        fileSize > 0 ? MaterialStorage.formattedSize(fileSize) : ""
    }

    /// 用于列表展示的摘要
    var summary: String {
        if hasBody {
            let compact = body.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(compact.prefix(60))
        }
        if !note.isEmpty { return note }
        return kind.title
    }
}

// MARK: - 文件存储

enum MaterialStorage {
    private static let folderName = "Materials"

    static var root: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = docs.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for fileName: String) -> URL {
        root.appendingPathComponent(fileName)
    }

    static func exists(fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: fileName).path)
    }

    /// 写入一段数据（图片、文字转成的文件）
    static func save(data: Data, fileExtension ext: String) throws -> (fileName: String, size: Int64) {
        let cleanExt = ext.isEmpty ? "dat" : ext
        let name = UUID().uuidString + "." + cleanExt
        let dest = url(for: name)
        try data.write(to: dest, options: [.atomic])
        return (name, Int64(data.count))
    }

    /// 从文件选择器拿到的外部 URL 拷贝进沙盒
    static func importFile(from external: URL) throws -> (fileName: String, size: Int64) {
        let accessed = external.startAccessingSecurityScopedResource()
        defer { if accessed { external.stopAccessingSecurityScopedResource() } }

        let ext = external.pathExtension.isEmpty ? "dat" : external.pathExtension
        let name = UUID().uuidString + "." + ext
        let dest = url(for: name)
        try FileManager.default.copyItem(at: external, to: dest)

        let attrs = try? FileManager.default.attributesOfItem(atPath: dest.path)
        let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        return (name, size)
    }

    /// 直接按指定文件名写回（恢复备份时用，必须保留原文件名，
    /// 否则 StudyMaterial.fileName 会对不上）
    static func write(data: Data, fileName: String) throws {
        let dest = url(for: fileName)
        try data.write(to: dest, options: [.atomic])
    }

    static func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// 资料库总占用
    static func totalSize() -> Int64 {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for file in files {
            let values = try? file.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }

    static func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: bytes)
    }
}
