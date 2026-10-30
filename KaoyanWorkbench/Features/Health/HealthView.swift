//
//  HealthView.swift
//  KaoyanWorkbench
//
//  健康运动：脱产 14 个月真正的对手是中途放弃，身体是第一生产力。
//

import SwiftUI

struct HealthView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editing = false
    @State private var draft = HealthEntry()

    private var today: Date { Date() }
    private var entry: HealthEntry { store.health(on: today) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                scoreCard
                todayCard
                weekCard
                adviceCard
                historyCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .navigationTitle("健康运动")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) {
            HealthEditorView(entry: draft) { updated in
                store.updateHealth(updated, on: today)
            }
        }
    }

    // MARK: - 健康分

    private var scoreCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("本周身体状态")
                            .font(.headline)
                        Text("运动 3 天 + 平均睡眠 7.5h 视为达标")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    ZStack {
                        RingProgress(
                            value: store.healthScore,
                            tint: store.healthScore > 0.6 ? Color(red: 0.18, green: 0.68, blue: 0.42) : .orange,
                            lineWidth: 7
                        )
                        .frame(width: 62, height: 62)
                        Text(ClockFormatter.percent(store.healthScore))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(store.healthScore > 0.6 ? Color(red: 0.18, green: 0.68, blue: 0.42) : .orange)
                    }
                }

                HStack(spacing: 8) {
                    StatTile(title: "运动天数",
                             value: "\(store.weekExerciseDays) 天",
                             caption: "本周",
                             tint: Color(red: 0.30, green: 0.65, blue: 0.42),
                             symbol: "figure.run")
                    StatTile(title: "运动时长",
                             value: ClockFormatter.minutesText(store.weekExerciseMinutes),
                             caption: "本周累计",
                             tint: .blue,
                             symbol: "stopwatch.fill")
                    StatTile(title: "平均睡眠",
                             value: store.averageSleepHours > 0 ? String(format: "%.1f h", store.averageSleepHours) : "—",
                             caption: "本周",
                             tint: .purple,
                             symbol: "bed.double.fill")
                }
            }
        }
    }

    // MARK: - 今日

    private var todayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("今天")
                        .font(.headline)
                    Spacer()
                    Button(entry.isLogged ? "修改" : "记录") {
                        draft = entry
                        editing = true
                    }
                    .font(.caption.weight(.semibold))
                }

                if !entry.isLogged {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.circle")
                            .font(.title3)
                            .foregroundStyle(Theme.tertiaryLabel)
                        Text("今天还没有记录健康数据。运动 20 分钟或散步一圈，都算。")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 8) {
                        if entry.didExercise {
                            healthRow(
                                symbol: entry.exerciseTypeSymbol,
                                title: entry.exerciseType.isEmpty ? "运动" : entry.exerciseType,
                                value: ClockFormatter.minutesText(entry.exerciseMinutes),
                                tint: Color(red: 0.30, green: 0.65, blue: 0.42)
                            )
                        }
                        if entry.walkedMinutes > 0 {
                            healthRow(symbol: "figure.walk",
                                      title: "散步",
                                      value: ClockFormatter.minutesText(entry.walkedMinutes),
                                      tint: .teal)
                        }
                        if entry.sleepHours > 0 {
                            healthRow(symbol: "bed.double.fill",
                                      title: "睡眠",
                                      value: String(format: "%.1f 小时", entry.sleepHours),
                                      tint: .purple)
                        }
                        if entry.waterCups > 0 {
                            healthRow(symbol: "drop.fill",
                                      title: "饮水",
                                      value: "\(entry.waterCups) 杯",
                                      tint: .blue)
                        }
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.caption2)
                                .foregroundStyle(Theme.tertiaryLabel)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // 示例：课表里的「晚餐 + 散步」
                let dinnerBlock = DailySchedule.blocks(for: today).first { $0.id.hasSuffix("dinner") }
                if let dinnerBlock {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("课表 \(dinnerBlock.timeRangeText)「\(dinnerBlock.title)」— 把这段走完就是有效恢复。")
                            .font(.caption2)
                    }
                    .foregroundStyle(Theme.tertiaryLabel)
                }
            }
        }
    }

    private func healthRow(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(tint)
                .frame(width: 20)
            Text(title)
                .font(.footnote)
            Spacer()
            Text(value)
                .font(.footnote.weight(.medium).monospacedDigit())
                .foregroundStyle(Theme.secondaryLabel)
        }
        .padding(.vertical, 3)
    }

    // MARK: - 本周

    private var weekCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("本周运动")
                    .font(.headline)

                let days = weekDays()
                HStack(spacing: 6) {
                    ForEach(days) { day in
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(circleColor(day.entry))
                                    .frame(width: 30, height: 30)
                                if day.entry.didExercise {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(day.dayNumber)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(day.isToday ? Theme.accent : Theme.tertiaryLabel)
                                }
                            }
                            Text(day.shortLabel)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.tertiaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func weekDays() -> [HealthDay] {
        let monday = CalendarHelper.startOfWeek(Date())
        return (0..<7).map { offset in
            let day = CalendarHelper.adding(days: offset, to: monday)
            return HealthDay(date: day, entry: store.health(on: day))
        }
    }

    private func circleColor(_ entry: HealthEntry) -> Color {
        if entry.didExercise { return Color(red: 0.30, green: 0.65, blue: 0.42) }
        return Theme.tertiaryCard
    }

    // MARK: - 建议

    private var adviceCard: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label("脱产期间的身体底线", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                ForEach(NumberedLine.lines(from: healthRules)) { line in
                    HStack(alignment: .top, spacing: 7) {
                        Text("\(line.number).")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                        Text(line.text)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private let healthRules = [
        "坐 3 小时后必须起来走一圈。你一天要坐 9.5 小时，腰和颈椎比数学更容易先崩。",
        "每天至少一次户外。课表里的「晚餐 + 散步」不是可选，是计划的一部分。",
        "睡眠低于 6.5 小时，第二天的数学就是白学。宁可少做 20 道题。",
        "感冒/发烧直接停工。带病学习的效率不到 20%，还会拖长病程。",
        "运动不需要装备和场地：散步、拉伸、跳绳、俯卧撑就够。"
    ]

    // MARK: - 历史

    private var historyCard: some View {
        let entries = store.recentHealthEntries
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近记录")
                    .font(.headline)

                if entries.isEmpty {
                    Text("还没有历史记录。从今天开始，每天记一行就够。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(entries) { item in
                        HStack(spacing: 8) {
                            Text(ClockFormatter.monthDay(item.date))
                                .font(.caption2)
                                .foregroundStyle(Theme.tertiaryLabel)
                                .frame(width: 56, alignment: .leading)
                            if item.entry.didExercise {
                                Label(ClockFormatter.minutesText(item.entry.exerciseMinutes),
                                      systemImage: "figure.run")
                                    .font(.caption2)
                                    .foregroundStyle(Color(red: 0.30, green: 0.65, blue: 0.42))
                            }
                            if item.entry.sleepHours > 0 {
                                Label(String(format: "%.1f h", item.entry.sleepHours),
                                      systemImage: "bed.double.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.purple)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

// MARK: - 编辑

struct HealthEditorView: View {
    let entry: HealthEntry
    var onSave: (HealthEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: HealthEntry
    @State private var exerciseType: ExerciseType = .walk

    init(entry: HealthEntry, onSave: @escaping (HealthEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _draft = State(initialValue: entry)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("今天运动了", isOn: $draft.didExercise.animation())

                    if draft.didExercise {
                        Picker("运动类型", selection: $exerciseType) {
                            ForEach(ExerciseType.allCases) { type in
                                Label(type.rawValue, systemImage: type.symbolName).tag(type)
                            }
                        }
                        .onChange(of: exerciseType) { _, newValue in
                            draft.exerciseType = newValue.rawValue
                        }

                        Stepper("运动 \(draft.exerciseMinutes) 分钟",
                                value: $draft.exerciseMinutes,
                                in: 0...300,
                                step: 5)
                    }

                    Stepper("散步 \(draft.walkedMinutes) 分钟",
                            value: $draft.walkedMinutes,
                            in: 0...300,
                            step: 10)
                } header: {
                    Text("运动")
                }

                Section {
                    HStack {
                        Text("睡眠")
                        Spacer()
                        Text(String(format: "%.1f 小时", draft.sleepHours))
                            .foregroundStyle(Theme.secondaryLabel)
                            .monospacedDigit()
                    }
                    Slider(value: $draft.sleepHours, in: 0...12, step: 0.5)
                        .tint(.purple)

                    Stepper("饮水 \(draft.waterCups) 杯",
                            value: $draft.waterCups,
                            in: 0...20)
                } header: {
                    Text("作息")
                }

                Section {
                    TextField("备注（如 膝盖有点酸 / 睡得晚）", text: $draft.note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("备注")
                }
            }
            .navigationTitle("健康记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if !draft.didExercise {
                            draft.exerciseMinutes = 0
                        }
                        if draft.exerciseType.isEmpty, draft.didExercise {
                            draft.exerciseType = exerciseType.rawValue
                        }
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let type = ExerciseType(rawValue: entry.exerciseType) {
                    exerciseType = type
                }
            }
        }
    }
}

extension HealthEntry {
    var exerciseTypeSymbol: String {
        ExerciseType(rawValue: exerciseType)?.symbolName ?? "figure.mixed.cardio"
    }
}
