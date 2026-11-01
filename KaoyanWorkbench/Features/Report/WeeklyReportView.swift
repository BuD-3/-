//
//  WeeklyReportView.swift
//  KaoyanWorkbench
//
//  学习时长周报：本周实际 vs 计划，时间花在哪，和上周比。
//
//  注意：body 与各卡片都拆成小片段，避免 Swift 类型推断超时。
//

import SwiftUI

struct WeeklyReportView: View {
    /// 当前查看的那一周的任意一天
    @State private var anchorDate: Date = Date()
    @EnvironmentObject private var store: AppStore

    private var report: WeekReport { store.weekReport(containing: anchorDate) }
    private var isCurrentWeek: Bool { store.isCurrentWeek(report.weekStart) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                weekSwitcher
                overviewCard
                chartCard
                breakdownCard
                detailCard
                verdictCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .navigationTitle("学习周报")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 周切换

    private var weekSwitcher: some View {
        HStack(spacing: 12) {
            Button {
                shiftWeek(-7)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(Theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(.subheadline.weight(.semibold))
                Text(isCurrentWeek ? "本周" : "历史")
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
            .frame(maxWidth: .infinity)

            Button {
                shiftWeek(7)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(Theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isCurrentWeek)
            .opacity(isCurrentWeek ? 0.35 : 1)
        }
    }

    private var weekRangeText: String {
        let end = CalendarHelper.adding(days: 6, to: report.weekStart)
        return "\(ClockFormatter.monthDay(report.weekStart)) – \(ClockFormatter.monthDay(end))"
    }

    private func shiftWeek(_ days: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            anchorDate = CalendarHelper.adding(days: days, to: anchorDate)
        }
    }

    // MARK: - 概览

    private var overviewCard: some View {
        Card {
            HStack(alignment: .center, spacing: 16) {
                ratioRing
                summaryColumn
            }
        }
    }

    private var ratioRing: some View {
        ZStack {
            RingProgress(value: report.ratio, tint: ratioColor, lineWidth: 8)
                .frame(width: 84, height: 84)
            VStack(spacing: 1) {
                Text("\(Int((report.ratio * 100).rounded()))%")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(ratioColor)
                Text("完成率")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }

    private var ratioColor: Color {
        if report.ratio >= 0.95 { return Color(red: 0.18, green: 0.68, blue: 0.42) }
        if report.ratio >= 0.7 { return Color(red: 0.90, green: 0.60, blue: 0.10) }
        return Color(red: 0.85, green: 0.28, blue: 0.24)
    }

    private var summaryColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("本周专注")
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", report.totalHours))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("/ \(String(format: "%.1f", report.plannedHours)) 小时")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)
            }

            comparisonRow
        }
    }

    private var comparisonRow: some View {
        let diff = report.comparedToLastWeek
        let sign = diff >= 0 ? "+" : "−"
        let text = String(format: "%@%.1f", sign, abs(diff))
        return HStack(spacing: 5) {
            Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .foregroundStyle(diff >= 0 ? Color(red: 0.18, green: 0.68, blue: 0.42) : .red)
            Text("比上周同期 \(text) 小时")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryLabel)
        }
    }

    // MARK: - 每日柱状

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader
                barsRow
                chartLegend
            }
        }
    }

    private var chartHeader: some View {
        HStack {
            Text("每日分布")
                .font(.headline)
            Spacer()
            Text("虚线 = 当天计划")
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
    }

    private var maxBarHours: Double {
        max(1.5, report.days.map { max($0.hours, $0.planned) }.max() ?? 9.5)
    }

    private var barsRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(report.days) { day in
                barColumn(day)
            }
        }
    }

    private func barColumn(_ day: WeekDayStudy) -> some View {
        let maxH = maxBarHours
        let height: CGFloat = 96
        let barH = max(2, height * CGFloat(min(day.hours / maxH, 1)))
        let planH = height * CGFloat(min(day.planned / maxH, 1))
        let achieved = day.planned > 0 && day.hours >= day.planned * 0.9
        let color = achieved ? Color(red: 0.18, green: 0.68, blue: 0.42) : Theme.accent

        return VStack(spacing: 5) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.accent.opacity(0.08))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(day.isFuture ? Theme.tertiaryCard : color.opacity(0.85))
                    .frame(height: day.isFuture ? 6 : barH)

                // 计划基准线
                if day.planned > 0 {
                    Rectangle()
                        .fill(Theme.tertiaryLabel.opacity(0.5))
                        .frame(height: 1)
                        .offset(y: -planH)
                }
            }
            .frame(height: height)

            Text(day.weekdayLabel)
                .font(.system(size: 9))
                .foregroundStyle(day.isToday ? Theme.accent : Theme.tertiaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartLegend: some View {
        HStack(spacing: 12) {
            legendDot(Color(red: 0.18, green: 0.68, blue: 0.42), "达标")
            legendDot(Theme.accent, "未达标")
            legendDot(Theme.tertiaryCard, "未到")
            Spacer()
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryLabel)
        }
    }

    // MARK: - 分块

    private var breakdownCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("时间花在哪")
                    .font(.headline)

                if report.slices.isEmpty {
                    Text("本周还没有打勾记录，所以没有时间分布。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(report.slices) { item in
                        sliceRow(item)
                    }
                }
            }
        }
    }

    private func sliceRow(_ item: SliceTotal) -> some View {
        let ratio = report.totalHours > 0 ? item.hours / report.totalHours : 0
        let color = Theme.color(for: item.slice)
        return VStack(spacing: 5) {
            HStack(spacing: 7) {
                Image(systemName: item.slice.symbolName)
                    .font(.system(size: 11))
                    .foregroundStyle(color)
                    .frame(width: 16)
                Text(item.slice.title)
                    .font(.caption)
                    .foregroundStyle(Theme.label)
                Spacer()
                Text(String(format: "%.1f h", item.hours))
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.secondaryLabel)
                Text("\(Int((ratio * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.tertiaryLabel)
                    .frame(width: 34, alignment: .trailing)
            }
            ProgressBar(value: ratio, tint: color, height: 6)
        }
        .padding(.vertical, 2)
    }

    // MARK: - 明细

    private var detailCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("本周明细")
                    .font(.headline)
                detailRow("达标天数", "\(report.achievedDays) / \(max(1, report.elapsedDays)) 天", "checkmark.seal.fill", Color(red: 0.18, green: 0.68, blue: 0.42))
                detailRow("额外补记", report.extraMinutes > 0 ? ClockFormatter.minutesText(report.extraMinutes) : "无", "plus.circle.fill", Color(red: 0.45, green: 0.52, blue: 0.62))
                detailRow("写了复盘", "\(report.reflectionDays) 天", "text.quote", Color(red: 0.55, green: 0.32, blue: 0.86))
                detailRow("连续打卡", "\(store.streakDays) 天", "flame.fill", .orange)
                detailRow("每周目标", String(format: "%.0f 小时（9.5×6）", WeekReport.weeklyGoal), "target", Theme.accent)
            }
        }
    }

    private func detailRow(_ title: String, _ value: String, _ symbol: String, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(Theme.label)
        }
    }

    // MARK: - 评语

    private var verdictCard: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Label("这周怎么样", systemImage: "text.bubble.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ratioColor)
                Text(report.verdict)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
