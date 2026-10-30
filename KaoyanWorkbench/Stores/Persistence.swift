//
//  Persistence.swift
//  KaoyanWorkbench
//
//  轻量 JSON 文件持久化。所有数据存在 App 的 Documents 目录，
//  随 iCloud 备份，不依赖任何第三方数据库。
//

import Foundation

final class Persistence {
    static let shared = Persistence()

    private let root: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.kaoyan.workbench.persistence", qos: .utility)

    private init() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        root = docs.appendingPathComponent("WorkbenchData", isDirectory: true)
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    private func url(for name: String) -> URL {
        root.appendingPathComponent("\(name).json")
    }

    func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let fileURL = url(for: name)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // 解码失败时把坏文件挪走，避免下次启动又失败、也避免静默丢数据
            let backup = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            #if DEBUG
            print("[Persistence] 解码 \(name) 失败：\(error)")
            #endif
            return nil
        }
    }

    func save<T: Encodable>(_ value: T, to name: String) {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            #if DEBUG
            print("[Persistence] 编码 \(name) 失败：\(error)")
            #endif
            return
        }
        let fileURL = url(for: name)
        queue.async {
            do {
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                #if DEBUG
                print("[Persistence] 写入 \(name) 失败：\(error)")
                #endif
            }
        }
    }

    /// 导出全部 JSON 备份数据
    func exportAll() -> Data? {
        guard let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return nil
        }
        var bundle: [String: Data] = [:]
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file) {
                bundle[file.deletingPathExtension().lastPathComponent] = data
            }
        }
        return try? JSONSerialization.data(withJSONObject: bundle.mapValues { String(decoding: $0, as: UTF8.self) },
                                           options: [.prettyPrinted, .sortedKeys])
    }
}
