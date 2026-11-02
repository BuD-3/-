//
//  ScheduleEditorView.swift
//  KaoyanWorkbench
//
//  课表编辑（决策 4）：把写死的时间改成自己能改的。
//

import SwiftUI

struct ScheduleEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ScheduleTemplate

    init(initial: ScheduleTemplate) {
        _draft = State(initialValue: initial)
    }

    var body: some View {
        Form {
            summarySection
            section(title: "周一至周六", blocks: $draft.weekday)
            section(title: "周日", blocks: $draft.sunday)

            Section {
                Button(role: .destructive) {
                    draft = .default
                } label: {
                    Text("恢复默认课表")
                }
            }
        }
        .navigationTitle("编辑课表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    store.updateSchedule(draft)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Text("周中合计")
                Spacer()
                Text(ClockFormatter.hoursText(Double(draft.weekdayPlannedMinutes) / 60))
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondaryLabel)
            }
            HStack {
                Text("周日合计")
                Spacer()
                Text(ClockFormatter.hoursText(Double(draft.sundayPlannedMinutes) / 60))
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondaryLabel)
            }
        } header: {
            Text("计划学习时长（只算学习类时段）")
        } footer: {
            Text("改成你自己的作息后，首页课表、学习时长统计都会跟着变。")
        }
    }

    @ViewBuilder
    private func section(title: String, blocks: Binding<[ScheduleBlock]>) -> some View {
        Section {
            ForEach(blocks) { $block in
                blockEditor($block)
            }
            .onDelete { indexSet in
                blocks.wrappedValue.remove(atOffsets: indexSet)
            }
            .onMove { from, to in
                blocks.wrappedValue.move(fromOffsets: from, toOffset: to)
            }

            Button {
                blocks.wrappedValue.append(
                    ScheduleBlock(
                        id: "custom-\(UUID().uuidString.prefix(8))",
                        startMinute: 20 * 60,
                        endMinute: 21 * 60,
                        title: "新时段",
                        detail: "",
                        kind: .math
                    )
                )
            } label: {
                Label("添加时段", systemImage: "plus.circle")
            }
        } header: {
            Text(title)
        }
    }

    private func blockEditor(_ block: Binding<ScheduleBlock>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField("名称", text: block.title)
                    .font(.subheadline.weight(.medium))

                Spacer(minLength: 0)

                Picker("", selection: block.kind) {
                    ForEach(ScheduleBlockKind.allCases, id: \.self) { kind in
                        Text(kindLabel(kind)).tag(kind)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            HStack(spacing: 12) {
                DatePicker("", selection: minuteBinding(block.startMinute), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("–")
                    .foregroundStyle(Theme.tertiaryLabel)
                DatePicker("", selection: minuteBinding(block.endMinute), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Spacer()
                Text(ClockFormatter.hoursText(Double(max(0, block.wrappedValue.durationMinutes)) / 60))
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
                    .monospacedDigit()
            }
        }
    }

    /// Int 分钟 ↔ Date 的双向绑定（用今天作为基准日，只取时分）
    private func minuteBinding(_ source: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                let base = CalendarHelper.startOfDay(Date())
                return base.addingTimeInterval(TimeInterval(source.wrappedValue * 60))
            },
            set: { newValue in
                let comps = CalendarHelper.shared.dateComponents([.hour, .minute], from: newValue)
                source.wrappedValue = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    private func kindLabel(_ kind: ScheduleBlockKind) -> String {
        switch kind {
        case .english: return "英语"
        case .math: return "数学"
        case .cs408: return "408"
        case .review: return "复盘"
        case .rest: return "生活"
        case .flexible: return "弹性"
        }
    }
}
