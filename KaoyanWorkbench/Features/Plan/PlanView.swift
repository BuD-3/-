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

    /// 关键节点是否展开全部
    @State private var showAllMilestones = false

    enum PlanSegment: String, CaseIterable, Identifiable {
        case roadmap = "逐月路线"
        case milestones = "关键节点"
        case targets = "目标分数"
        case schedule = "课表"
        var id: String { rawValue }
    }

    /// 截图用：--plan-seg N 直接打开某个分段（0 逐月 1 节点 2 目标 3 课表）
    private static var launchSegment: PlanSegment {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "--plan-seg"),
              idx + 1 < args.count,
              let value = Int(args[idx + 1]),
              value >= 0, value < PlanSegment.allCases.count else { return .roadmap }
        return PlanSegment.allCases[value]
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
                    case .schedule: scheduleContent
                    }

                    ironRulesCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("--plan-seg") {
                    selection = PlanView.launchSegment
                }
            }
            .navigationTitle("计划")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    /// 三条铁律（原在今日页，因占用太多空间移到计划页底部）
    private var ironRulesCard: some View {
        Card(padding: 14) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(NumberedLine.lines(from: IronRules.all)) { line in
                        HStack(alignment: .top, spacing: 7) {
                            Text("\(line.number).")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.orange)
                            Text(line.text)
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("三条铁律", systemImage: "exclamationmark.shield.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
            }
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
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryLabel)
                FlowRow(spacing: 8) {
                    ForEach(stages) { stage in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.color(for: stage))
                                .frame(width: 6, height: 6)
                            Text(stage.rawValue)
                                .font(.footnote)
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
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.color(for: month.stage))
                        .frame(width: 4)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(month.title)
                                .font(.subheadline.weight(.semibold))
                            if isCurrent {
                                Text("进行中")
                                    .font(.footnote.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accent.opacity(0.14))
                                    .foregroundStyle(Theme.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(month.stage.rawValue)
                            .font(.footnote)
                            .foregroundStyle(Theme.color(for: month.stage))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider().padding(.leading, 14)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(Subject.allCases) { subject in
                        SubjectFlipCard(
                            subject: subject,
                            short: month.shortText(for: subject),
                            full: month.text(for: subject),
                            isIdle: month.isIdle(for: subject)
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text(month.milestone)
                        .font(.footnote)
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
                .font(.footnote)
                .foregroundStyle(Theme.label)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 课表（可编辑）

    private var scheduleContent: some View {
        VStack(spacing: 12) {
            Card {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("周中 \(ClockFormatter.hoursText(Double(store.schedule.weekdayPlannedMinutes) / 60))")
                            .font(.subheadline.weight(.semibold))
                        Text("周日 \(ClockFormatter.hoursText(Double(store.schedule.sundayPlannedMinutes) / 60))")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    NavigationLink {
                        ScheduleEditorView(initial: store.schedule)
                    } label: {
                        HStack(spacing: 4) {
                            Text("编辑")
                                .font(.footnote.weight(.medium))
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.accent.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            scheduleGroup(title: "周一至周六", blocks: store.schedule.weekday)
            scheduleGroup(title: "周日", blocks: store.schedule.sunday)
        }
    }

    private func scheduleGroup(title: String, blocks: [ScheduleBlock]) -> some View {
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                Divider().padding(.leading, 14)

                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    HStack(spacing: 10) {
                        Text(ClockFormatter.hhmm(block.startMinute))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(block.kind.countsAsStudy ? Theme.accent : Theme.tertiaryLabel)
                            .frame(width: 46, alignment: .leading)

                        Text(block.title)
                            .font(.footnote)
                            .foregroundStyle(block.kind.countsAsStudy ? Theme.label : Theme.secondaryLabel)

                        Spacer(minLength: 0)

                        if block.kind.countsAsStudy {
                            Text(ClockFormatter.hoursText(block.durationHours))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.tertiaryLabel)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)

                    if index < blocks.count - 1 {
                        Divider().padding(.leading, 70)
                    }
                }
            }
        }
    }

    // MARK: - 关键节点

    private var milestonesContent: some View {
        let today = CalendarHelper.startOfDay(Date())
        let all = MilestoneData.all
        let upcoming = all.filter { CalendarHelper.startOfDay($0.date) >= today }
        let shown = showAllMilestones ? all : Array(upcoming.prefix(5))

        return VStack(spacing: 12) {
            ForEach(shown) { milestone in
                milestoneRow(milestone)
            }

            if !showAllMilestones {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllMilestones = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("查看全部 \(all.count) 个节点")
                            .font(.footnote)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.tertiaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        let today = CalendarHelper.startOfDay(Date())
        let mDate = CalendarHelper.startOfDay(milestone.date)
        let isPast = mDate < today
        let isToday = CalendarHelper.isSameDay(mDate, today)
        let daysAway = CalendarHelper.daysBetween(today, mDate)

        return Card(padding: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text(String(format: "%02d", milestone.month))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(isPast ? Theme.tertiaryLabel : Theme.accent)
                    Text("\(milestone.year)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                .frame(width: 30)
                .padding(.vertical, 5)
                .background(isPast ? Theme.tertiaryCard : Theme.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(milestone.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isPast ? Theme.secondaryLabel : Theme.label)
                        if isToday {
                            Text("今天")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        } else if !isPast && daysAway <= 30 {
                            Text("\(daysAway) 天后")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                    }
                    Text(milestone.action)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - 目标分数

    private var targetsContent: some View {
        VStack(spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("总分目标")
                            .font(.headline)
                        Spacer()
                        Text("353 / 500")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    Text("2026 国家线 A 区工学 264 分，按 353 分预留 90 分缓冲。过 264 即有机会，353 为稳态目标。")
                        .font(.footnote)
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
                    infoRow("院校", "目标院校（详见个人计划表）")
                    infoRow("专业", "目标专业（专硕 · 全日制 · 3 年）")
                    infoRow("初试", "101 政治 / 204 英语二 / 302 数学二 / 408")
                    infoRow("身份", "同等学力（须加试《数字逻辑》《离散数学》）")
                    infoRow("复试", "机试 30% + 英语 10% + 面试 60%")
                    infoRow("研招办", "以目标院校官网为准")
                }
            }
        }
    }

    private func scorePill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.footnote)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    SubjectBadge(subject: subject)
                    Text("满分 \(subject.fullScore)")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Spacer()
                    Text("目标 \(subject.targetScore)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.color(for: subject))
                }

                // 三个分数横排（决策 23：不再把 4 个数塞进一条区间条）
                HStack(spacing: 8) {
                    scorePill("底线", "\(subject.floorScore)", Theme.tertiaryLabel)
                    scorePill("目标", "\(subject.targetScore)", Theme.color(for: subject))
                    scorePill("冲刺", "\(subject.sprintScore)", Color(red: 0.18, green: 0.68, blue: 0.42))
                }

                Divider()

                HStack(spacing: 8) {
                    Text("进度项")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Text("\(stats.done)/\(stats.total)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.secondaryLabel)
                    ProgressBar(value: stats.ratio, tint: Theme.color(for: subject), height: 5)
                }
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.tertiaryLabel)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.footnote)
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
