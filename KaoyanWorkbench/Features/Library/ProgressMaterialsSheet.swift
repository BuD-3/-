//
//  ProgressMaterialsSheet.swift
//  KaoyanWorkbench
//
//  从「进度」页点某个章节时弹出的资料列表，可当场追加。
//

import SwiftUI
import UIKit

struct ProgressMaterialsSheet: View {
    let item: ProgressItem

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingComposer = false

    private var materials: [StudyMaterial] {
        store.materials(forProgressItem: item.id)
    }

    var body: some View {
        NavigationStack {
            content
                .background(Theme.background)
                .navigationTitle("章节资料")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingComposer) { composer }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                headerCard
                listSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var listSection: some View {
        Group {
            if materials.isEmpty {
                emptyCard
            } else {
                ForEach(materials) { material in
                    NavigationLink(destination: MaterialDetailView(materialID: material.id)) {
                        row(material)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("关闭") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingComposer = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("添加资料")
        }
    }

    private var composer: some View {
        MaterialComposer(
            editing: nil,
            presetDate: nil,
            presetItem: item,
            onSave: { store.addMaterial($0) },
            availableProgressItems: store.progressItems
        )
    }

    private var emptyCard: some View {
        Card {
            EmptyStateView(
                symbol: "paperclip",
                title: "这个章节还没有资料",
                message: "把课本截图、真题 PDF、或者自己整理的文字笔记传进来，以后翻这一章就能直接看到。"
            )
        }
    }

    private var headerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    SubjectBadge(subject: item.subject, compact: true)
                    Text(item.module)
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Spacer()
                    Text("\(materials.count) 份")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text("计划 \(item.planMonths)\(item.isDone ? " · 已完成" : "")")
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }

    private func row(_ material: StudyMaterial) -> some View {
        Card(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent.opacity(0.10))
                        .frame(width: 40, height: 40)
                    if material.kind == .image,
                       let url = material.fileURL,
                       let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        Image(systemName: material.kind.symbolName)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(material.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(material.summary)
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(ClockFormatter.monthDay(material.createdAt))
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }
}
