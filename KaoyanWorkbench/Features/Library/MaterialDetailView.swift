//
//  MaterialDetailView.swift
//  KaoyanWorkbench
//
//  单份资料：预览 + 归属信息 + 编辑 / 分享 / 删除。
//

import SwiftUI
import UIKit

struct MaterialDetailView: View {
    let materialID: UUID

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditor = false
    @State private var showingDeleteConfirm = false

    private var material: StudyMaterial? {
        store.materials.first { $0.id == materialID }
    }

    var body: some View {
        Group {
            if let material {
                content(material)
            } else {
                missingView
            }
        }
        .navigationTitle(material?.title ?? "资料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEditor) { editorSheet }
        .alert("删除这份资料？", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let material {
                    store.deleteMaterial(material)
                }
                dismiss()
            }
        } message: {
            Text("附件文件会一起删掉，无法恢复。")
        }
    }

    private var missingView: some View {
        EmptyStateView(
            symbol: "trash",
            title: "这份资料已被删除",
            message: "返回上一页看看别的。"
        )
        .frame(maxHeight: .infinity)
        .background(Theme.background)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if let material {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("编辑信息", systemImage: "pencil")
                    }
                    shareButton(material)
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func shareButton(_ material: StudyMaterial) -> some View {
        if let url = material.fileURL, FileManager.default.fileExists(atPath: url.path) {
            ShareLink(item: url) {
                Label("分享附件", systemImage: "square.and.arrow.up")
            }
        } else if material.hasBody {
            ShareLink(item: material.body) {
                Label("分享文字", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var editorSheet: some View {
        if let material {
            MaterialComposer(
                editing: material,
                presetDate: nil,
                presetItem: nil,
                onSave: { store.updateMaterial($0) },
                availableProgressItems: store.progressItems
            )
        }
    }

    // MARK: - 内容

    private func content(_ material: StudyMaterial) -> some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                previewCard(material)
                infoCard(material)
                if material.hasBody {
                    textCard(material)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
    }

    @ViewBuilder
    private func previewCard(_ material: StudyMaterial) -> some View {
        if material.hasFile,
           let url = material.fileURL,
           FileManager.default.fileExists(atPath: url.path) {
            if material.kind == .image,
               let image = UIImage(contentsOfFile: url.path) {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 460)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            } else {
                // PDF / 文本 用系统 QuickLook
                QuickLookPreview(url: url)
                    .frame(height: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .cardStyle(padding: 0)
            }
        } else if material.hasFile {
            Card {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("附件文件找不到了，可能被系统清理过。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                }
            }
        }
    }

    private func infoCard(_ material: StudyMaterial) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: material.kind.symbolName)
                        .foregroundStyle(Theme.accent)
                    Text(material.kind.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(ClockFormatter.monthDay(material.createdAt))
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Divider()

                if let subject = material.subject {
                    infoRow("科目", subject.rawValue)
                }
                if let item = store.progressItem(with: material.progressItemID) {
                    infoRow("章节", "\(item.module) · \(item.title)")
                }
                if let key = material.dateKey, let date = DateKey.date(from: key) {
                    infoRow("日期", ClockFormatter.monthDay(date))
                }
                if !material.sizeText.isEmpty {
                    infoRow("大小", material.sizeText)
                }
                if !material.note.isEmpty {
                    infoRow("备注", material.note)
                }
            }
        }
    }

    private func textCard(_ material: StudyMaterial) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("文字内容")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button {
                        UIPasteboard.general.string = material.body
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                }
                Text(material.body)
                    .font(.footnote)
                    .foregroundStyle(Theme.label)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.tertiaryLabel)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
