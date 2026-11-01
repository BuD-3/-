//
//  PlanView.swift
//  KaoyanWorkbench
//
//  计划：14 个月逐月路线图 + 关键时间节点 + 目标分数
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: PlanSegment = .roadmap

    enum PlanSegment: String, CaseIterable, Identifiable {
        case roadmap = "逐月路线"
        case milestones = "关键节点"
        case targets = "目标分数"
        var id: String { rawValue }
    }

    private var currentMonthID: String? {
        ExamPlanData.currentMonth(on: Date())?.id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    segmentPicker

                    switch selection {
                    case .roadmap: roadmapContent
                    case .milestones: milestonesContent
                    case .targets: targetsContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("计划")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var segmentPicker: some View {
        Picker("视图", selection: $selection) {
            ForEach(PlanSegment.allCases) { seg in
                Text(seg.rawValue).tag(seg)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 逐月路线

    private var roadmapContent: some View {
        VStack(spacing: 12) {
            stageLegend

            ForEach(ExamPlanData.months) { month in
                monthCard(month, isCurrent: month.id == currentMonthID)
            }
        }
    }

    private var stageLegend: some View {
        let stages: [PlanStage] = [.foundation, .roundOne, .strengthen, .sprint, .examWeek]
        return Card(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("四个阶段")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryLabel)
                FlowRow(spacing: 8) {
                    ForEach(stages) { stage in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.color(for: stage))
                                .frame(width: 6, height: 6)
                            Text(stage.rawValue)
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.color(for: stage).opacity(0.10))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func monthCard(_ month: MonthPlan, isCurrent: Bool) -> some View {
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // 头部
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.color(for: month.stage))
                        .frame(width: 4)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(month.title)
                                .font(.subheadline.weight(.semibold))
                            if isCurrent {
                                Text("进行中")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accent.opacity(0.14))
                                    .foregroundStyle(Theme.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(month.stage.rawValue)
                            .font(.caption2)
                            .foregroundStyle(Theme.color(for: month.stage))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider().padding(.leading, 14)

                VStack(alignment: .leading, spacing: 10) {
                    monthRow(subject: .math, text: month.math)
                    monthRow(subject: .cs408, text: month.cs408)
                    monthRow(subject: .english, text: month.english)
                    if month.politics != "—" {
                        monthRow(subject: .politics, text: month.politics)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(month.milestone)
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(isCurrent ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func monthRow(subject: Subject, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            SubjectBadge(subject: subject, compact: true)
                .padding(.top, 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.label)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 关键节点

    private var milestonesContent: some View {
        VStack(spacing: 10) {
            ForEach(MilestoneData.all) { milestone in
                milestoneRow(milestone)
            }
        }
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        let today = CalendarHelper.startOfDay(Date())
        let mDate = CalendarHelper.startOfDay(milestone.date)
        let isPast = mDate < today
        let isToday = CalendarHelper.isSameDay(mDate, today)
        let daysAway = CalendarHelper.daysBetween(today, mDate)

        return Card(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 2) {
                    Text(String(format: "%02d", milestone.month))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isPast ? Theme.tertiaryLabel : Theme.accent)
                    Text("\(milestone.year)")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                .frame(width: 30)
                .padding(.vertical, 5)
                .background(isPast ? Theme.tertiaryCard : Theme.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(milestone.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isPast ? Theme.secondaryLabel : Theme.label)
                        if isToday {
                            Text("今天")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        } else if !isPast && daysAway <= 30 {
                            Text("\(daysAway) 天后")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                    }
                    Text(milestone.action)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - 目标分数

    private var targetsContent: some View {
        VStack(spacing: 14) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("总分目标")
                            .font(.headline)
                        Spacer()
                        Text("353 / 500")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    Text("2026 国家线 A 区工学 264 分，按 353 分预留 90 分缓冲。过 264 即有机会，353 为稳态目标。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        scorePill("底线", "290", .gray)
                        scorePill("目标", "353", Theme.accent)
                        scorePill("冲刺", "384", .green)
                        Spacer()
                    }
                }
            }

            ForEach(Subject.allCases) { subject in
                subjectScoreCard(subject)
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Label("报考信息", systemImage: "graduationcap.fill")
                        .font(.subheadline.weight(.semibold))
                    infoRow("院校", "河南大学 人工智能学院（郑州校区）")
                    infoRow("专业", "085410 人工智能（专硕 · 全日制 · 3 年）")
                    infoRow("初试", "101 政治 / 204 英语二 / 302 数学二 / 408")
                    infoRow("身份", "同等学力（须加试《数字逻辑》《离散数学》）")
                    infoRow("复试", "机试 30% + 英语 10% + 面试 60%")
                    infoRow("研招办", "0371-22867269")
                }
            }
        }
    }

    private func scorePill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func subjectScoreCard(_ subject: Subject) -> some View {
        let stats = store.progressStats(for: subject)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    SubjectBadge(subject: subject)
                    Text("满分 \(subject.fullScore)")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Spacer()
                    Text("目标 \(subject.targetScore)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.color(for: subject))
                }

                // 分数区间条
                GeometryReader { geo in
                    let w = geo.size.width
                    let full = Double(subject.fullScore)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.separator.opacity(0.35))
                            .frame(height: 8)
                        Capsule()
                            .fill(Theme.color(for: subject).opacity(0.18))
                            .frame(width: w * (Double(subject.floorScore) / full), height: 8)
                        Capsule()
                            .fill(Theme.color(for: subject))
                            .frame(width: max(4, w * (Double(subject.targetScore) / full)), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("底线 \(subject.floorScore)")
                    Spacer()
                    Text("目标 \(subject.targetScore)")
                    Spacer()
                    Text("冲刺 \(subject.sprintScore)")
                }
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)

                Divider()

                HStack(spacing: 6) {
                    Text("进度项")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Text("\(stats.done)/\(stats.total)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondaryLabel)
                    ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 5)
                }
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.tertiaryLabel)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 自动换行布局

struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowHeights: [CGFloat] = [0]
        var x: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                rowHeights.append(0)
            }
            x += size.width + spacing
            rowHeights[rowHeights.count - 1] = max(rowHeights[rowHeights.count - 1], size.height)
        }

        let totalHeight = rowHeights.reduce(0, +) + spacing * CGFloat(max(0, rowHeights.count - 1))
        return CGSize(width: maxWidth == .infinity ? 0 : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
