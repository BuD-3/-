//
//  MaterialComposer.swift
//  KaoyanWorkbench
//
//  新建 / 编辑一条资料：导入文件、从相册选图、或手写文字笔记。
//  可同时关联到「某一天」和「某个章节（进度项）」。
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct MaterialComposer: View {
    /// 编辑模式传入已有资料；新建时传 nil
    let editing: StudyMaterial?
    /// 预设关联的日期（从今日页进入时带上当天）
    var presetDate: Date?
    /// 预设关联的章节（从进度页进入时带上）
    var presetItem: ProgressItem?

    var onSave: (StudyMaterial) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var textBody: String = ""
    @State private var subject: Subject?
    @State private var progressItemID: UUID?
    @State private var linkToDate: Bool = true
    @State private var linkDate: Date = Date()

    // 附件
    @State private var fileName: String?
    @State private var fileSize: Int64 = 0
    @State private var fileNameLabel: String = ""

    // 选择器
    @State private var showingFileImporter = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isImportingPhoto = false
    @State private var errorMessage: String?

    private var isEditing: Bool { editing != nil }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle || fileName != nil || !textBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var kind: StudyMaterialKind {
        if let fileName {
            return StudyMaterialKind.detect(fileName: fileName)
        }
        return .text
    }

    var body: some View {
        NavigationStack {
            Form {
                attachmentSection
                textSection
                metaSection
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑资料" : "添加资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isImportingPhoto)
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .image, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileResult(result)
            }
            .onChange(of: photoItem) { _, newValue in
                guard let newValue else { return }
                importPhoto(newValue)
            }
            .onAppear(perform: loadInitialState)
        }
    }

    // MARK: - 附件

    private var attachmentSection: some View {
        Section {
            if let fileName {
                HStack(spacing: 12) {
                    Image(systemName: kind.symbolName)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fileNameLabel.isEmpty ? "已选择文件" : fileNameLabel)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(fileSize > 0 ? MaterialStorage.formattedSize(fileSize) : "已附加")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    Spacer()
                    Button("移除", role: .destructive) {
                        MaterialStorage.delete(fileName: fileName)
                        self.fileName = nil
                        self.fileSize = 0
                        self.fileNameLabel = ""
                    }
                    .font(.footnote)
                }
            } else {
                Button {
                    showingFileImporter = true
                } label: {
                    Label("导入文件（PDF / 图片 / 文本）", systemImage: "doc.badge.plus")
                        .font(.subheadline)
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("从相册选一张图", systemImage: "photo.badge.plus")
                        .font(.subheadline)
                }

                if isImportingPhoto {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("正在读取图片…")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                }
            }
        } header: {
            Text("附件")
        } footer: {
            Text("文件会拷进 App 自己的目录，不联网上传。单条资料建议不超过 100 MB。")
        }
    }

    // MARK: - 文字

    private var textSection: some View {
        Section {
            TextField("标题（如 同济第1章 极限笔记）", text: $title)

            if fileName == nil {
                TextEditor(text: $textBody)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if textBody.isEmpty {
                            Text("也可以直接写文字笔记…")
                                .font(.subheadline)
                                .foregroundStyle(Theme.tertiaryLabel)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        } header: {
            Text("内容")
        }
    }

    // MARK: - 分类与关联

    private var metaSection: some View {
        Section {
            Picker("科目", selection: $subject) {
                Text("不指定").tag(Subject?.none)
                ForEach(Subject.allCases) { item in
                    Text(item.rawValue).tag(Subject?.some(item))
                }
            }

            Picker("关联章节", selection: $progressItemID) {
                Text("不关联").tag(UUID?.none)
                ForEach(chapterChoices) { item in
                    Text(item.title).tag(UUID?.some(item.id))
                }
            }

            Toggle("关联到某一天", isOn: $linkToDate.animation())
            if linkToDate {
                DatePicker("日期", selection: $linkDate, displayedComponents: .date)
            }

            TextField("备注（哪本书、第几页、易错点）", text: $note, axis: .vertical)
                .lineLimit(1...3)
        } header: {
            Text("归属")
        } footer: {
            Text("关联章节后，可以在「进度」里按章节翻看所有资料；关联日期后，会出现在「今日」的当天记录里。")
        }
    }

    /// 由调用方注入，避免 Composer 依赖整个 Store
    var availableProgressItems: [ProgressItem] = []

    /// 选了科目就只列该科目的章节；没选科目则列全部
    private var chapterChoices: [ProgressItem] {
        guard let subject else { return availableProgressItems }
        return availableProgressItems.filter { $0.subject == subject }
    }

    // MARK: - 行为

    private func loadInitialState() {
        if let editing {
            title = editing.title
            note = editing.note
            textBody = editing.body
            subject = editing.subject
            progressItemID = editing.progressItemID
            fileName = editing.fileName
            fileSize = editing.fileSize
            fileNameLabel = editing.fileName ?? ""
            if let key = editing.dateKey, let date = DateKey.date(from: key) {
                linkToDate = true
                linkDate = date
            } else {
                linkToDate = false
            }
        } else {
            subject = presetItem?.subject
            progressItemID = presetItem?.id
            if let presetDate {
                linkToDate = true
                linkDate = presetDate
            } else {
                linkToDate = false
            }
        }
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let saved = try MaterialStorage.importFile(from: url)
                fileName = saved.fileName
                fileSize = saved.size
                fileNameLabel = url.lastPathComponent
                if title.isEmpty {
                    title = url.deletingPathExtension().lastPathComponent
                }
                errorMessage = nil
            } catch {
                errorMessage = "导入失败：\(error.localizedDescription)"
            }
        case .failure(let error):
            errorMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) {
        isImportingPhoto = true
        Task {
            var failure: String?
            var savedFile: (fileName: String, size: Int64)?
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let png = image.pngData() {
                    savedFile = try MaterialStorage.save(data: png, fileExtension: "png")
                } else {
                    failure = "这张图读不出来，换一张试试。"
                }
            } catch {
                failure = "读取图片失败：\(error.localizedDescription)"
            }

            await MainActor.run {
                isImportingPhoto = false
                photoItem = nil
                if let savedFile {
                    fileName = savedFile.fileName
                    fileSize = savedFile.size
                    fileNameLabel = "相册图片"
                    if title.isEmpty { title = "图片资料" }
                    errorMessage = nil
                } else {
                    errorMessage = failure
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle: String = {
            if !trimmedTitle.isEmpty { return trimmedTitle }
            if hasTextBody { return String(textBody.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20)) }
            return "未命名资料"
        }()

        var material = editing ?? StudyMaterial(title: finalTitle, kind: kind)
        material.title = finalTitle
        material.kind = kind
        material.fileName = fileName
        material.fileSize = fileSize
        material.body = textBody
        material.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        material.subject = subject
        material.progressItemID = progressItemID
        material.dateKey = linkToDate ? DateKey.key(for: linkDate) : nil

        onSave(material)
        dismiss()
    }

    private var hasTextBody: Bool {
        !textBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

