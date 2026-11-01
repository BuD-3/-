//
//  TodayView.swift
//  KaoyanWorkbench
//
//  主页：倒计时 + 当前阶段 + 今日课表打卡 + 学习时长
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingReflection = false
    @State private var reflectionDraft = ""
    @State private var showingComposer = false

    private var today: Date { Date() }
    private var blocks: [ScheduleBlock] { DailySchedule.blocks(for: today) }
    private var completed: Set<String> { store.completedBlocks(on: today) }
    private var record: DayCheckIn { store.checkIn(for: today) }
    private var studiedHours: Double { store.studyHours(on: today) }
    private var plannedHours: Double { store.plannedHours(on: today) }
    private var ratio: Double { store.completionRatio(on: today) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Theme.spacing) {
                        countdownCard
                        stageCard

                        if isLaunchDay {
                            launchDayCard
                        } else if CalendarHelper.isSunday(today) {
                            sundayCard
                        }

                        timetableCard
                        materialCard
                            .id("materials")
                        if !record.reflection.isEmpty {
                            reflectionPreview
                        }
                        weekSummaryCard
                        navigationHintCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    // 仅自动化截图用：直接把「今天学过什么」滚到可见位置
                    guard ProcessInfo.processInfo.arguments.contains("--focus-materials") else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("materials", anchor: .top)
                        }
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reflectionDraft = record.reflection
                        showingReflection = true
                    } label: {
                        Image(systemName: record.reflection.isEmpty ? "square.and.pencil" : "square.and.pencil.circle.fill")
                    }
                    .accessibilityLabel("写今日复盘")
                }
            }
            .sheet(isPresented: $showingReflection) {
                ReflectionSheet(text: $reflectionDraft) { text in
                    store.setReflection(text, on: today)
                    showingReflection = false
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingComposer) {
                MaterialComposer(
                    editing: nil,
                    presetDate: today,
                    presetItem: nil,
                    onSave: { store.addMaterial($0) },
                    availableProgressItems: store.progressItems
                )
            }
        }
    }

    // MARK: - 倒计时

    private var daysLeft: Int {
        max(0, CalendarHelper.daysBetween(today, PlanTimeline.examDate))
    }

    private var daysElapsed: Int {
        max(0, CalendarHelper.daysBetween(PlanTimeline.startDate, today))
    }

    /// 备考第几天：启动日当天即为第 1 天
    private var dayNumber: Int { daysElapsed + 1 }

    private var hasStarted: Bool {
        CalendarHelper.startOfDay(today) >= CalendarHelper.startOfDay(PlanTimeline.startDate)
    }

    /// 今天是不是备考启动日
    private var isLaunchDay: Bool {
        CalendarHelper.isSameDay(today, PlanTimeline.startDate)
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ClockFormatter.weekdayShort(today))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.secondaryLabel)
                    Text(ClockFormatter.monthDay(today))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(daysLeft)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(daysLeft <= 30 ? Color.red : Theme.accent)
                        Text("天")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Text("距初试")
                        .font(.caption)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
            }

            HStack(spacing: 10) {
                countdownChip(
                    title: "备考进度",
                    value: hasStarted ? "第 \(dayNumber) 天" : "未启动",
                    symbol: "flame.fill",
                    tint: .orange
                )
                countdownChip(
                    title: "连续打卡",
                    value: "\(store.streakDays) 天",
                    symbol: "checkmark.seal.fill",
                    tint: Color(red: 0.18, green: 0.68, blue: 0.42)
                )
                countdownChip(
                    title: "累计专注",
                    value: ClockFormatter.hoursText(store.totalStudyHours),
                    symbol: "clock.fill",
                    tint: Theme.color(for: Subject.math)
                )
            }

            if let next = MilestoneData.next(after: today) {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("下一节点：\(next.title) · \(next.dateText)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Theme.card, Theme.card.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.accent.opacity(0.08), lineWidth: 1)
        )
    }

    private func countdownChip(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.tertiaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 当前阶段

    private var stageCard: some View {
        let month = ExamPlanData.currentMonth(on: today)
        let stage = month?.stage ?? .foundation
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Theme.color(for: stage))
                            .frame(width: 8, height: 8)
                        Text(stage.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.color(for: stage))
                    }
                    Spacer()
                    Text(month?.title ?? "—")
                        .font(.caption)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Divider()

                if let month {
                    VStack(alignment: .leading, spacing: 9) {
                        focusRow(subject: .math, text: month.math)
                        focusRow(subject: .cs408, text: month.cs408)
                        focusRow(subject: .english, text: month.english)
                        if month.politics != "—" {
                            focusRow(subject: .politics, text: month.politics)
                        }
                    }

                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                        Text("本月里程碑：\(month.milestone)")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                }
            }
        }
    }

    private func focusRow(subject: Subject, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            SubjectBadge(subject: subject, compact: true)
                .padding(.top, 1)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.label)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 启动日

    private var launchDayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("今天是备考第 1 天")
                            .font(.subheadline.weight(.semibold))
                        Text("14 个月从今天开始算")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                }

                if CalendarHelper.isSunday(today) {
                    Text("今天是周日，按计划本来就该休息——Day 1 撞上休息日不算坏事：把书桌、资料、作息定下来，明天 07:20 正式开始第一章。")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("先去把今天课表第一项打勾。开局不需要完美，只需要真的开始。")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - 周日休息

    private var sundayCard: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.30, green: 0.65, blue: 0.42))
                VStack(alignment: .leading, spacing: 3) {
                    Text("今天是休息日")
                        .font(.subheadline.weight(.semibold))
                    Text("每周必须休满一天，这是计划的一部分。别愧疚。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                Spacer()
            }
        }
    }

    // MARK: - 今日课表

    private var timetableCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("今日课表")
                            .font(.headline)
                        Text("已完成 \(ClockFormatter.hoursText(studiedHours)) / 计划 \(ClockFormatter.hoursText(plannedHours))")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    ZStack {
                        RingProgress(value: ratio, tint: Theme.accent, lineWidth: 5)
                            .frame(width: 44, height: 44)
                        Text(ClockFormatter.percent(ratio))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(blocks) { block in
                        blockRow(block, isLast: block.id == blocks.last?.id)
                    }
                }

                extraTimeRow
            }
        }
    }

    private func blockRow(_ block: ScheduleBlock, isLast: Bool) -> some View {
        let isDone = completed.contains(block.id)
        let isStudy = block.kind.countsAsStudy
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    store.toggleBlock(block, on: today)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(isDone ? Theme.color(of: block.kind) : Theme.color(of: block.kind).opacity(0.12))
                                .frame(width: 22, height: 22)
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .fill(Theme.color(of: block.kind))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        if !isLast {
                            Rectangle()
                                .fill(Theme.separator.opacity(0.5))
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 2)
                        }
                    }
                    .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(block.timeRangeText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.tertiaryLabel)
                            if isStudy {
                                Text(ClockFormatter.hoursText(block.durationHours))
                                    .font(.caption2)
                                    .foregroundStyle(Theme.tertiaryLabel)
                            }
                        }
                        Text(block.title)
                            .font(.subheadline.weight(isStudy ? .medium : .regular))
                            .foregroundStyle(isDone ? Theme.tertiaryLabel : Theme.label)
                            .strikethrough(isDone, color: Theme.tertiaryLabel)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var extraTimeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.secondaryLabel)
            Text("额外补记")
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
            Spacer()
            Text(record.extraStudyMinutes == 0 ? "无" : ClockFormatter.minutesText(record.extraStudyMinutes))
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.secondaryLabel)
                .monospacedDigit()
            Stepper(
                "",
                value: Binding(
                    get: { record.extraStudyMinutes },
                    set: { store.setExtraMinutes($0, on: today) }
                ),
                in: 0...600,
                step: 15
            )
            .labelsHidden()
        }
        .padding(.top, 4)
    }

    // MARK: - 今日上传的学习内容

    private var todayMaterials: [StudyMaterial] { store.materials(on: today) }

    private var materialCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                materialHeader
                materialBody
            }
        }
    }

    private var materialHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今天学过什么")
                    .font(.headline)
            }
            Spacer()
            Button {
                showingComposer = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .accessibilityLabel("上传今天的学习内容")
        }
    }

    @ViewBuilder
    private var materialBody: some View {
        if todayMaterials.isEmpty {
            emptyMaterialPrompt
        } else {
            materialList
        }
    }

    private var emptyMaterialPrompt: some View {
        Button {
            showingComposer = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("还没有记录")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.label)
                    Text("点这里上传今天学的资料")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                Spacer()
            }
            .padding(12)
            .background(Theme.tertiaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var materialList: some View {
        VStack(spacing: 8) {
            ForEach(todayMaterials) { material in
                NavigationLink(destination: MaterialDetailView(materialID: material.id)) {
                    materialRow(material)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func materialRow(_ material: StudyMaterial) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.accent.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: material.kind.symbolName)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(material.title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.label)
                    .lineLimit(1)
                Text(material.summary)
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - 复盘预览

    private var reflectionPreview: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("今日复盘", systemImage: "text.quote")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button("编辑") {
                        reflectionDraft = record.reflection
                        showingReflection = true
                    }
                    .font(.caption)
                }
                Text(record.reflection)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 本周

    private var weekSummaryCard: some View {
        let week = store.weekStudyHours()
        let maxHours = max(1.0, week.map { max($0.hours, $0.planned) }.max() ?? 8)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("本周专注")
                        .font(.headline)
                    Spacer()
                    NavigationLink {
                        WeeklyReportView()
                    } label: {
                        HStack(spacing: 3) {
                            Text("\(ClockFormatter.hoursText(store.weekTotalHours)) / \(ClockFormatter.hoursText(store.weekPlannedHours))")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryLabel)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Theme.tertiaryLabel)
                        }
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(week) { day in
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Theme.accent.opacity(0.10))
                                    .frame(height: 56)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(CalendarHelper.isSameDay(day.date, Date()) ? Theme.accent : Theme.accent.opacity(0.55))
                                    .frame(height: max(3, 56 * (day.hours / maxHours)))
                            }
                            Text(day.weekdayLabel)
                                .font(.caption2)
                                .foregroundStyle(CalendarHelper.isSameDay(day.date, Date()) ? Theme.accent : Theme.tertiaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                let todayHealth = store.health(on: today)
                if todayHealth.isLogged {
                    HStack(spacing: 12) {
                        if todayHealth.exerciseMinutes > 0 {
                            Label(ClockFormatter.minutesText(todayHealth.exerciseMinutes), systemImage: "figure.run")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        if todayHealth.sleepHours > 0 {
                            Label(String(format: "%.1f h 睡眠", todayHealth.sleepHours), systemImage: "bed.double.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - 提示

    private var navigationHintCard: some View {
        Card(padding: 14) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(NumberedLine.lines(from: IronRules.all)) { line in
                        HStack(alignment: .top, spacing: 7) {
                            Text("\(line.number).")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.orange)
                            Text(line.text)
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("三条铁律", systemImage: "exclamationmark.shield.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - 复盘编辑

struct ReflectionSheet: View {
    @Binding var text: String
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("三行就够：今天卡在哪、明天先做什么、身体状态如何。")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)

                TextEditor(text: $text)
                    .focused($focused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Theme.tertiaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 180)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("例：极限 1^∞ 型还是慢；明天先做 30 道同类题再碰新章。")
                                .font(.footnote)
                                .foregroundStyle(Theme.tertiaryLabel)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                Spacer()
            }
            .padding(16)
            .background(Theme.background)
            .navigationTitle("今日复盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }
}
