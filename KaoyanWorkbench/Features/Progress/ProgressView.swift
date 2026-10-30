//
//  ProgressView.swift
//  KaoyanWorkbench
//
//  进度追踪：四科 40 个进度项，按模块折叠，自动算完成率。
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var store: AppStore
    @State private var expandedSubjects: Set<Subject> = Set(Subject.allCases)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    overviewCard
                    monthFocusCard

                    ForEach(Subject.allCases) { subject in
                        subjectSection(subject)
                    }

                    resetCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("进度")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 总览

    private var overviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("总体完成度")
                            .font(.headline)
                        Text("完成 \(store.progressItems.filter { $0.isDone }.count) / \(store.progressItems.count) 个进度项")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    ZStack {
                        RingProgress(value: store.overallProgress, tint: Theme.accent, lineWidth: 7)
                            .frame(width: 62, height: 62)
                        Text(ClockFormatter.percent(store.overallProgress))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }

                VStack(spacing: 9) {
                    ForEach(Subject.allCases) { subject in
                        let stats = store.progressStats(for: subject)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.color(for: subject))
                                .frame(width: 7, height: 7)
                            Text(subject.rawValue)
                                .font(.caption.weight(.medium))
                                .frame(width: 46, alignment: .leading)
                            ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 6)
                            Text("\(stats.done)/\(stats.total)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Theme.tertiaryLabel)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 本月重点

    private var monthFocusCard: some View {
        let focus = store.currentMonthFocus()
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("本月该推进", systemImage: "scope")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(focus.count) 项")
                        .font(.caption)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                if focus.isEmpty {
                    Text("本月计划项已全部勾完，或本月无计划项。去看看下个月的任务。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(focus.prefix(6)) { item in
                        Button {
                            withAnimation { store.toggleProgress(item) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .font(.caption)
                                    .foregroundStyle(Theme.color(for: item.subject))
                                SubjectBadge(subject: item.subject, compact: true)
                                Text(item.title)
                                    .font(.caption)
                                    .foregroundStyle(Theme.label)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if focus.count > 6 {
                        Text("还有 \(focus.count - 6) 项…")
                            .font(.caption2)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }
            }
        }
    }

    // MARK: - 分科

    private func subjectSection(_ subject: Subject) -> some View {
        let stats = store.progressStats(for: subject)
        let isExpanded = expandedSubjects.contains(subject)
        let groups = store.groupedProgress(for: subject)

        return Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if isExpanded {
                            expandedSubjects.remove(subject)
                        } else {
                            expandedSubjects.insert(subject)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.color(for: subject).opacity(0.13))
                                .frame(width: 32, height: 32)
                            Text(subject.shortName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.color(for: subject))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subject.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.label)
                            Text("\(stats.done)/\(stats.total) 完成 · \(ClockFormatter.percent(stats.ratio))")
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        Spacer()
                        ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 5)
                            .frame(width: 60)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 6) {
                                Text(group.module)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Theme.color(for: subject))
                                Rectangle()
                                    .fill(Theme.color(for: subject).opacity(0.18))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 4)

                            ForEach(group.items) { item in
                                progressRow(item, subject: subject)
                            }
                        }
                    }
                    Color.clear.frame(height: 8)
                }
            }
        }
    }

    private func progressRow(_ item: ProgressItem, subject: Subject) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                store.toggleProgress(item)
            }
        } label: {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(item.isDone ? Theme.color(for: subject) : Theme.tertiaryLabel)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.footnote)
                        .foregroundStyle(item.isDone ? Theme.tertiaryLabel : Theme.label)
                        .strikethrough(item.isDone, color: Theme.tertiaryLabel)
                        .multilineTextAlignment(.leading)
                    Text(itemMood(item, planMonths: item.planMonths))
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 计划月份的提示文字：已过期待补 / 本月 / 未来
    private func itemMood(_ item: ProgressItem, planMonths: String) -> String {
        guard let first = item.planMonthList.first else { return "计划 \(planMonths)" }
        let current = CalendarHelper.monthKey(Date())
        if item.isDone { return "已完成" }
        if first < current { return "计划 \(planMonths) · 已过期" }
        if item.planMonthList.contains(current) { return "计划 \(planMonths) · 本月" }
        return "计划 \(planMonths)"
    }

    // MARK: - 重置

    private var resetCard: some View {
        Card(padding: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(Theme.secondaryLabel)
                VStack(alignment: .leading, spacing: 2) {
                    Text("重置进度表")
                        .font(.caption.weight(.semibold))
                    Text("把 40 个进度项恢复为「未开始」，不影响打卡和错题。")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                Spacer()
                Button("重置") {
                    store.resetProgressToSeed()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
    }
}
