//
//  WeeklyReport.swift
//  KaoyanWorkbench
//
//  学习时长周报的数据结构。
//
//  计划基准：9.5 小时/天 × 每周 6 天 ≈ 57 小时/周
//  （Tab 里周日只安排 2 小时周复盘，所以按天算计划更准）
//

import Foundation

/// 一周里时间花在哪一块
enum StudySlice: String, CaseIterable, Identifiable {
    case math
    case cs408
    case english
    case review
    case extra

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: return "数学"
        case .cs408: return "408"
        case .english: return "英语"
        case .review: return "错题复盘"
        case .extra: return "额外补记"
        }
    }

    var symbolName: String {
        switch self {
        case .math: return "function"
        case .cs408: return "cpu"
        case .english: return "textformat.abc"
        case .review: return "arrow.triangle.2.circlepath"
        case .extra: return "plus.circle"
        }
    }
}

/// 某个分块在本周累计的时长
struct SliceTotal: Identifiable {
    var id: StudySlice { slice }
    let slice: StudySlice
    let hours: Double
}

/// 一周的完整统计
struct WeekReport: Identifiable {
    var id: String { DateKey.key(for: weekStart) }

    let weekStart: Date
    /// 本周 7 天（周一 → 周日）
    let days: [WeekDayStudy]

    /// 已过去的天数（含今天）；未来天不算欠账
    let elapsedDays: Int

    let totalHours: Double
    let plannedHours: Double
    let lastWeekHours: Double

    /// 按分块排序（时长降序，去掉 0）
    let slices: [SliceTotal]

    /// 达到计划 90% 的天数
    let achievedDays: Int
    /// 补记的分钟数
    let extraMinutes: Int
    /// 写了复盘的天数
    let reflectionDays: Int

    /// 完成率；计划为 0 时返回 0
    var ratio: Double {
        plannedHours > 0 ? min(1.5, totalHours / plannedHours) : 0
    }

    /// 与上周同为「已过去天数」的口径比较，避免拿半周比整周
    var comparedToLastWeek: Double {
        totalHours - lastWeekHours
    }

    /// 每周目标（9.5 小时 × 6 天）
    static let weeklyGoal: Double = 9.5 * 6

    var goalRatio: Double {
        min(1.5, totalHours / Self.weeklyGoal)
    }

    /// 一句话评价
    var verdict: String {
        if plannedHours <= 0 { return "本周还没开始。" }
        let pct = Int((ratio * 100).rounded())
        if totalHours <= 0 {
            return "这一周还没记录任何学习。打开今日页，把课表第一项勾上就算开始。"
        }
        if ratio >= 1.0 {
            return "本周 \(pct)% 达成，节奏是稳的。别加码，保持住就是赢。"
        }
        if ratio >= 0.8 {
            return "本周 \(pct)%，差一点点。检查一下是不是某天被事情打断了。"
        }
        if ratio >= 0.5 {
            return "本周 \(pct)%，明显欠账。先别管进度表，把明天的第一项做完。"
        }
        return "本周 \(pct)%，掉得有点多。14 个月的对手不是难度，是中断——明天重新开始，不用补偿前面的。"
    }
}
