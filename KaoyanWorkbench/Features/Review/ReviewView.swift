//
//  ReviewView.swift
//  KaoyanWorkbench
//
//  错题本：当天回炉① + 第 7 天回炉②，两次都过才算掌握。
//

import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingEditor = false
    @State private var filter: ReviewFilter = .due
    @State private var selectedSubject: Subject?

    enum ReviewFilter: String, CaseIterable, Identifiable {
        case due = "待回炉"
        case all = "全部"
        case mastered = "已掌握"
        var id: String { rawValue }
    }

    private var filtered: [Mistake] {
        var list: [Mistake]
        switch filter {
        case .due:
            list = store.mistakes.filter { $0.status != .mastered }
        case .all:
            list = store.mistakes
        case .mastered:
            list = store.mistakes.filter { $0.status == .mastered }
        }
        if let selectedSubject {
            list = list.filter { $0.subject == selectedSubject }
        }
        return list.sorted { $0.createdAt > $1.createdAt }
    }

    private var dueQueue: [Mistake] { store.reviewQueue() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    summaryCard
                    if !store.mistakes.isEmpty {
                        distributionCard
                    }
                    filterBar
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ForEach(filtered) { mistake in
                            mistakeCard(mistake)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("错题本")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("新增错题")
                }
            }
            .sheet(isPresented: $showingEditor) {
                MistakeEditorView(mistake: nil) { newMistake in
                    store.addMistake(newMistake)
                }
            }
        }
    }

    // MARK: - 概览

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("回炉队列")
                        .font(.headline)
                    Spacer()
                    Text("\(dueQueue.count) 题待处理")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(dueQueue.isEmpty ? Theme.secondaryLabel : .orange)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        StatTile(title: "待回炉①",
                                 value: "\(store.freshCount)",
                                 tint: .orange,
                                 symbol: "clock.arrow.circlepath")
                        StatTile(title: "待回炉②",
                                 value: "\(store.pendingWeekCount)",
                                 tint: .red,
                                 symbol: "calendar.badge.clock")
                    }
                    HStack(spacing: 8) {
                        StatTile(title: "今日完成",
                                 value: "\(store.completedTodayCount)",
                                 tint: .blue,
                                 symbol: "checkmark.circle.fill")
                        StatTile(title: "已掌握",
                                 value: "\(store.mistakes.filter { $0.status == .mastered }.count)",
                                 tint: Color(red: 0.18, green: 0.68, blue: 0.42),
                                 symbol: "checkmark.seal.fill")
                    }
                }
            }
        }
    }

    /// 错误分布：按错误类型聚合
    /// 按错误类型聚合
    private var typeCounts: [MistakeTypeBar] {
        MistakeType.allCases.map { type in
            MistakeTypeBar(
                id: type.rawValue,
                name: type.rawValue,
                count: store.mistakes.filter { $0.errorType == type }.count,
                color: type.tint
            )
        }
        .filter { $0.count > 0 }
        .sorted { $0.count > $1.count }
    }

    private var distributionCard: some View {
        let counts = typeCounts
        let maxCount = max(1, counts.map { $0.count }.max() ?? 1)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("错误分布")
                        .font(.headline)
                    Spacer()
                    Text("共 \(store.mistakes.count) 条")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                VStack(spacing: 7) {
                    ForEach(counts) { item in
                        HStack(spacing: 8) {
                            Text(item.name)
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryLabel)
                                .frame(width: 58, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Theme.separator.opacity(0.25))
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(item.color)
                                        .frame(
                                            width: max(4, geo.size.width * Double(item.count) / Double(maxCount)),
                                            height: 6
                                        )
                                }
                                .frame(height: 6)
                                .frame(maxHeight: .infinity, alignment: .center)
                            }
                            .frame(height: 12)
                            Text("\(item.count)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.tertiaryLabel)
                                .frame(width: 22, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 12) {
            Picker("筛选", selection: $filter) {
                ForEach(ReviewFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    subjectChip(nil, label: "全部科目")
                    ForEach(Subject.allCases) { subject in
                        subjectChip(subject, label: subject.shortName)
                    }
                }
            }
        }
    }

    private func subjectChip(_ subject: Subject?, label: String) -> some View {
        let isSelected = selectedSubject == subject
        let color = subject.map { Theme.color(for: $0) } ?? Theme.accent
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedSubject = subject
            }
        } label: {
            Text(label)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Theme.card)
                .foregroundStyle(isSelected ? Color.white : Theme.secondaryLabel)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        Card {
            EmptyStateView(
                symbol: filter == .mastered ? "tray" : "sparkles",
                title: filter == .mastered ? "还没有已掌握的题" : "回炉队列清空了",
                message: filter == .mastered
                    ? "两次回炉都通过的错题会出现在这里。"
                    : "今天的错题当天回炉，第 7 天再回炉一次。现在没有到期的题。"
            )
        }
    }

    // MARK: - 错题卡

    private func mistakeCard(_ mistake: Mistake) -> some View {
        let isDueNow = mistake.isWeekReviewDue() || (mistake.status == .fresh && CalendarHelper.isSameDay(mistake.createdAt, Date()))
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    SubjectBadge(subject: mistake.subject, compact: true)
                    Text(mistake.displaySource)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.secondaryLabel)
                        .lineLimit(1)
                    Spacer()
                    statusTag(mistake)
                }

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Text(mistake.point.isEmpty ? "未填考点" : mistake.point)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text(mistake.errorType.rawValue)
                        .font(.footnote)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.10))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                    Text(ClockFormatter.monthDay(mistake.createdAt) + " 录入")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                    if mistake.status == .pendingDay {
                        Text("回炉② \(ClockFormatter.monthDay(mistake.weekReviewDue))")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    Spacer()
                }

                if !mistake.correctIdea.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        Text(mistake.correctIdea)
                            .font(.subheadline)
                            .foregroundStyle(Theme.label)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.tertiaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack(spacing: 8) {
                    if !mistake.didSameDayReview {
                        Button {
                            withAnimation { store.markSameDayReviewed(mistake) }
                        } label: {
                            Label("完成回炉①", systemImage: "arrow.clockwise")
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Theme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else if !mistake.didWeekReview {
                        Button {
                            withAnimation { store.markWeekReviewed(mistake) }
                        } label: {
                            Label(
                                isDueNow ? "完成回炉②（已到期）" : "完成回炉②",
                                systemImage: isDueNow ? "checkmark.circle.fill" : "calendar"
                            )
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isDueNow ? Color.orange : Theme.accent.opacity(0.15))
                            .foregroundStyle(isDueNow ? .white : Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.42))
                            Text("两次回炉都通过")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.18, green: 0.68, blue: 0.42).opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Button {
                            store.undoReviews(mistake)
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.footnote)
                                .foregroundStyle(Theme.tertiaryLabel)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                store.deleteMistake(mistake)
            } label: {
                Label("删除", systemImage: "trash")
            }
            if mistake.didSameDayReview || mistake.didWeekReview {
                Button {
                    store.undoReviews(mistake)
                } label: {
                    Label("重置回炉状态", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    private func statusTag(_ mistake: Mistake) -> some View {
        let (text, color): (String, Color) = {
            switch mistake.status {
            case .fresh: return ("待回炉①", .orange)
            case .pendingDay:
                if mistake.isWeekReviewDue() { return ("回炉② 已到期", .red) }
                return ("待回炉②", .blue)
            case .mastered: return ("已掌握", Color(red: 0.18, green: 0.68, blue: 0.42))
            }
        }()
        return Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(color.opacity(0.13))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - 新增/编辑错题

struct MistakeEditorView: View {
    let mistake: Mistake?
    var onSave: (Mistake) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var subject: Subject = .math
    @State private var source: String = ""
    @State private var point: String = ""
    @State private var errorType: MistakeType = .calculation
    @State private var correctIdea: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("科目", selection: $subject) {
                        ForEach(Subject.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    TextField("来源（如 2020 数二 第15题）", text: $source)
                    TextField("考点（如 极限 / 1^∞ 型）", text: $point)
                } header: {
                    Text("题目")
                }

                Section {
                    Picker("错误类型", selection: $errorType) {
                        ForEach(MistakeType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                } header: {
                    Text("错因")
                }

                Section {
                    TextEditor(text: $correctIdea)
                        .frame(minHeight: 90)
                } header: {
                    Text("正确思路（一句话）")
                } footer: {
                    Text("用一句话写清「下次怎么做」，比抄一遍答案有用。")
                }
            }
            .navigationTitle(mistake == nil ? "新增错题" : "编辑错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var result = mistake ?? Mistake(
                            subject: subject,
                            source: source,
                            point: point,
                            errorType: errorType,
                            correctIdea: correctIdea
                        )
                        result.subject = subject
                        result.source = source
                        result.point = point
                        result.errorType = errorType
                        result.correctIdea = correctIdea
                        onSave(result)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(point.trimmingCharacters(in: .whitespaces).isEmpty
                              && source.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let mistake else { return }
                subject = mistake.subject
                source = mistake.source
                point = mistake.point
                errorType = mistake.errorType
                correctIdea = mistake.correctIdea
            }
        }
    }
}


// MARK: - 分布条

struct MistakeTypeBar: Identifiable {
    let id: String
    let name: String
    let count: Int
    let color: Color
}

extension MistakeType {
    var tint: Color {
        switch self {
        case .calculation: return Color(red: 0.90, green: 0.45, blue: 0.15)
        case .concept: return Color(red: 0.85, green: 0.25, blue: 0.30)
        case .method: return Color(red: 0.55, green: 0.32, blue: 0.86)
        case .careless: return Color(red: 0.20, green: 0.55, blue: 0.90)
        case .blank: return Color(red: 0.45, green: 0.45, blue: 0.50)
        case .time: return Color(red: 0.18, green: 0.68, blue: 0.42)
        }
    }
}
