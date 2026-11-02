//
//  ProgressView.swift
//  KaoyanWorkbench
//
//  进度追踪：四科进度项（当前 37 项），按模块折叠，自动算完成率。
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var store: AppStore
    @State private var expandedSubjects: Set<Subject> = Set(Subject.allCases)
    @State private var scoreTarget: ProgressItem?
    @State private var libraryTarget: ProgressItem?

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
            .sheet(item: $libraryTarget) { item in
                ProgressMaterialsSheet(item: item)
            }
            .sheet(item: $scoreTarget) { item in
                ScoreEditorSheet(item: item) { score in
                    store.setSelfTestScore(item, score: score)
                }
            }
        }
    }

    // MARK: - 总览

    private var overviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总体完成度")
                            .font(.headline)
                        Text("完成 \(store.progressItems.filter { $0.isDone }.count) / \(store.progressItems.count) 个进度项")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    ZStack {
                        RingProgress(value: store.overallProgress, tint: Theme.accent, lineWidth: 7)
                            .frame(width: 56, height: 56)
                        Text(ClockFormatter.percent(store.overallProgress))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }

                // 按轮次分段（决策 11）
                VStack(spacing: 9) {
                    ForEach(store.progressByRound()) { round in
                        roundRow(round)
                    }
                }

                Divider()

                // 四科分布保留
                VStack(spacing: 8) {
                    ForEach(Subject.allCases) { subject in
                        let stats = store.progressStats(for: subject)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.color(for: subject))
                                .frame(width: 7, height: 7)
                            Text(subject.rawValue)
                                .font(.footnote.weight(.medium))
                                .frame(width: 46, alignment: .leading)
                            ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 6)
                            Text("\(stats.done)/\(stats.total)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.tertiaryLabel)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func roundRow(_ round: RoundProgress) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(round.name)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.label)
                Spacer()
                Text("\(round.done)/\(round.total)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.tertiaryLabel)
                Text(ClockFormatter.percent(round.ratio))
                    .font(.footnote.monospacedDigit().weight(.medium))
                    .foregroundStyle(round.ratio > 0 ? Theme.accent : Theme.tertiaryLabel)
                    .frame(width: 38, alignment: .trailing)
            }
            ProgressBar(value: round.ratio, tint: Theme.accent, height: 7)
        }
    }

    // MARK: - 本月重点

    private var monthFocusCard: some View {
        let items = store.currentMonthItems()
        let done = items.filter { $0.isDone }.count
        let beforeStart = store.isBeforePlanStart
        let ratio = items.isEmpty ? 0 : Double(done) / Double(items.count)

        // 未完成的排在前面
        let sorted = items.sorted { a, b in
            if a.isDone != b.isDone { return !a.isDone }
            return a.title < b.title
        }

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(beforeStart ? "启动月进度" : "本月进度",
                          systemImage: beforeStart ? "flag.checkered" : "scope")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(done)/\(items.count) 项 · \(ClockFormatter.percent(ratio))")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                if items.isEmpty {
                    Text("本月没有排定的进度项。")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ProgressBar(value: ratio, tint: Theme.accent, height: 8)

                    if beforeStart {
                        Text("备考 2026-11-01 启动，下面是首月任务。")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(sorted.prefix(10).enumerated()), id: \.element.id) { index, item in
                            monthItemRow(item)
                            if index < min(sorted.count, 10) - 1 {
                                Divider().padding(.leading, 26)
                            }
                        }
                    }

                    if sorted.count > 10 {
                        Text("还有 \(sorted.count - 10) 项…")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }
            }
        }
    }

    private func monthItemRow(_ item: ProgressItem) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                store.toggleProgress(item)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(item.isDone ? Theme.color(for: item.subject) : Theme.tertiaryLabel)

                SubjectBadge(subject: item.subject, compact: true)

                Text(item.title)
                    .font(.footnote)
                    .foregroundStyle(item.isDone ? Theme.tertiaryLabel : Theme.label)
                    .strikethrough(item.isDone, color: Theme.tertiaryLabel)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.color(for: subject).opacity(0.13))
                                .frame(width: 32, height: 32)
                            Text(subject.shortName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.color(for: subject))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subject.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.label)
                            Text("\(stats.done)/\(stats.total) 完成 · \(ClockFormatter.percent(stats.ratio))")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        Spacer()
                        ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 5)
                            .frame(width: 60)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(group.module)
                                    .font(.footnote.weight(.semibold))
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

    /// 显示用分数文本
    private func scoreText(_ item: ProgressItem) -> String {
        let raw = item.selfTestScore.trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? "未测" : raw
    }

    /// 按分数区间上色
    private func scoreColor(_ item: ProgressItem) -> Color {
        guard let value = Int(item.selfTestScore.trimmingCharacters(in: .whitespaces)) else {
            return Theme.tertiaryLabel
        }
        switch value {
        case ..<60: return .red
        case 60..<80: return .orange
        case 80..<90: return Theme.accent
        default: return Color(red: 0.18, green: 0.68, blue: 0.42)
        }
    }

    private func progressRow(_ item: ProgressItem, subject: Subject) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    store.toggleProgress(item)
                }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17))
                        .foregroundStyle(item.isDone ? Theme.color(for: subject) : Theme.tertiaryLabel)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(item.isDone ? Theme.tertiaryLabel : Theme.label)
                            .strikethrough(item.isDone, color: Theme.tertiaryLabel)
                            .multilineTextAlignment(.leading)
                        Text(itemMood(item, planMonths: item.planMonths))
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    Spacer(minLength: 0)

                    // 分数（决策 14）：直接显示数字，没测就显示「未测」
                    Button {
                        scoreTarget = item
                    } label: {
                        Text(scoreText(item))
                            .font(.footnote.monospacedDigit().weight(.semibold))
                            .foregroundStyle(scoreColor(item))
                            .frame(minWidth: 34)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(scoreColor(item).opacity(item.selfTestScore.isEmpty ? 0.06 : 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 该章节下的资料数量 / 入口
            Button {
                libraryTarget = item
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 11))
                    let count = store.materialCount(forProgressItem: item.id)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundStyle(store.materialCount(forProgressItem: item.id) > 0 ? Theme.accent : Theme.tertiaryLabel)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Theme.tertiaryCard)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看该章节资料")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    /// 计划月份的提示文字：已过期待补 / 本月 / 未来
    private func itemMood(_ item: ProgressItem, planMonths: String) -> String {
        guard let first = item.planMonthList.first else { return planMonths }
        let current = CalendarHelper.monthKey(Date())
        if item.isDone { return "已完成" }
        if first < current { return "\(planMonths) · 已过期" }
        if item.planMonthList.contains(current) { return "\(planMonths) · 本月" }
        return planMonths
    }

    // MARK: - 重置

    private var resetCard: some View {
        Card(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(Theme.secondaryLabel)
                VStack(alignment: .leading, spacing: 4) {
                    Text("重置进度表")
                        .font(.footnote.weight(.semibold))
                    Text("把 \(store.progressItems.count) 个进度项恢复为「未开始」，不影响打卡和错题。")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                Spacer()
                Button("重置") {
                    store.resetProgressToSeed()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
    }
}
