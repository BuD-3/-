//
//  BackupService.swift
//  KaoyanWorkbench
//
//  完整备份与恢复。
//
//  把所有业务数据 + 资料库附件的二进制一起塞进一个 .json 文件，
//  换设备 / 重签 App / 重装系统后能原样恢复。
//
//  为什么用 JSON 而不是 zip：
//  - Foundation 没有内置 zip 写入
//  - JSON 里 Data 会自动编码成 base64，一个文件就能带走全部内容
//  - 可读、可手工检查、可以用任何编辑器打开
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 备份文件的内容
struct BackupArchive: Codable {
    /// 结构版本，用于以后兼容处理
    var version: Int = BackupArchive.currentVersion
    var createdAt: Date = Date()
    var appBuild: String = "1.0"

    var checkIns: [String: DayCheckIn] = [:]
    var mistakes: [Mistake] = []
    var progressItems: [ProgressItem] = []
    var budgetEntries: [BudgetEntry] = []
    var todos: [TodoItem] = []
    var materials: [StudyMaterial] = []
    var settings: AppSettings = AppSettings()

    /// 附件文件名 → 文件内容
    var attachments: [String: Data] = [:]

    static let currentVersion = 2

    var totalAttachmentBytes: Int64 {
        attachments.values.reduce(0) { $0 + Int64($1.count) }
    }

    var attachmentCount: Int { attachments.count }

    var summaryText: String {
        "打卡 \(checkIns.count) 天 · 错题 \(mistakes.count) 条 · 进度 \(progressItems.filter(\.isDone).count)/\(progressItems.count) 项 · 资料 \(materials.count) 份（附件 \(attachmentCount) 个）"
    }
}

enum BackupService {
    // MARK: - 编码 / 解码

    static func encode(_ archive: BackupArchive) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(archive)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupArchive.self, from: data)
    }

    static func suggestedFileName(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmm"
        return "考研工作台备份-\(f.string(from: date))"
    }

    /// 备份里带的提示：附件体积过大时提醒用户
    static func sizeWarning(_ archive: BackupArchive) -> String? {
        let bytes = archive.totalAttachmentBytes
        if bytes > 80 * 1024 * 1024 {
            return "附件共 \(MaterialStorage.formattedSize(bytes))，文件会比较大，导出时请耐心等几秒。"
        }
        return nil
    }
}

// MARK: - 给 SwiftUI 的 fileExporter 用

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
