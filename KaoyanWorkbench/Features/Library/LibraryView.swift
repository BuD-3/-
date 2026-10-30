//
//  LibraryView.swift
//  KaoyanWorkbench
//
//  资料库：所有上传的 PDF / 图片 / 文字笔记。
//  可按科目筛选、搜索，点开预览。
//
//  注意：body 刻意拆成多个小片段。Swift 的类型推断对超大 ViewBuilder
//  表达式会超时（"unable to type-check this expression in reasonable time"）。
//

import SwiftUI
import UIKit

struct LibraryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var selectedSubject: Subject?
    @State private var showingComposer = false

    private var materials: [StudyMaterial] {
        store.filteredMaterials(subject: selectedSubject, query: query)
    }

    var body: some View {
        content
            .background(Theme.background)
            .navigationTitle("资料库")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "搜索标题、备注、内容")
            .toolbar { addButton }
            .sheet(isPresented: $showingComposer) { composer }
    }

    // MARK: - 主体

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                summaryCard
                filterBar
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
    private var addButton: some ToolbarContent {
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
            presetItem: nil,
            onSave: { store.addMaterial($0) },
            availableProgressItems: store.progressItems
        )
    }

    // MARK: - 概览

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                summaryHeader
                if store.totalMaterialCount > 0 {
                    kindChips
                }
            }
        }
    }

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("资料库")
                    .font(.headline)
                Text("共 \(store.totalMaterialCount) 份 · 占用 \(store.totalMaterialSize)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var kindChips: some View {
        HStack(spacing: 8) {
            ForEach(StudyMaterialKind.allCases) { kind in
                if count(of: kind) > 0 {
                    kindChip(kind)
                }
            }
            Spacer()
        }
    }

    private func count(of kind: StudyMaterialKind) -> Int {
        store.materials.reduce(0) { $0 + ($1.kind == kind ? 1 : 0) }
    }

    private func kindChip(_ kind: StudyMaterialKind) -> some View {
        HStack(spacing: 4) {
            Image(systemName: kind.symbolName)
                .font(.caption2)
            Text("\(count(of: kind))")
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.tertiaryCard)
        .foregroundStyle(Theme.secondaryLabel)
        .clipShape(Capsule())
    }

    // MARK: - 筛选

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, label: "全部科目")
                ForEach(Subject.allCases) { subject in
                    chip(subject, label: subject.shortName)
                }
            }
        }
    }

    private func chip(_ subject: Subject?, label: String) -> some View {
        let isOn = selectedSubject == subject
        let color = subject.map { Theme.color(for: $0) } ?? Theme.accent
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { selectedSubject = subject }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn ? color : Theme.card)
                .foregroundStyle(isOn ? Color.white : Theme.secondaryLabel)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        Card {
            EmptyStateView(
                symbol: "tray.and.arrow.down",
                title: query.isEmpty ? "还没有资料" : "没搜到",
                message: query.isEmpty
                    ? "把 PDF、拍的笔记图、或者手写的文字笔记传进来，可以挂到某一天，也可以挂到某个章节。"
                    : "换个关键词，或者点右上角加一份。"
            )
        }
    }

    // MARK: - 行

    private func row(_ material: StudyMaterial) -> some View {
        Card(padding: 14) {
            HStack(spacing: 12) {
                thumbnail(material)
                rowText(material)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }

    private func rowText(_ material: StudyMaterial) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(material.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.label)
                .lineLimit(1)

            Text(material.summary)
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
                .lineLimit(1)

            if material.subject != nil || material.dateKey != nil {
                metaLine(material)
            }
        }
    }

    private func metaLine(_ material: StudyMaterial) -> some View {
        HStack(spacing: 6) {
            if let subject = material.subject {
                SubjectBadge(subject: subject, compact: true)
            }
            if let key = material.dateKey, let date = DateKey.date(from: key) {
                Text(ClockFormatter.monthDay(date))
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func thumbnail(_ material: StudyMaterial) -> some View {
        if material.kind == .image,
           let url = material.fileURL,
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: material.kind.symbolName)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}
