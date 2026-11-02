//
//  ScheduleTemplate.swift
//  KaoyanWorkbench
//
//  可编辑的课表（决策 4）。
//  默认值来自 ExamPlanData 里的硬编码课表，用户可以自己改时间、增删时段，
//  改完之后存进 JSON，后续所有统计都跟着用户版本走。
//

import Foundation

struct ScheduleTemplate: Codable, Hashable {
    /// 周一至周六
    var weekday: [ScheduleBlock]
    /// 周日
    var sunday: [ScheduleBlock]

    static var `default`: ScheduleTemplate {
        ScheduleTemplate(weekday: DailySchedule.weekdayBlocks, sunday: DailySchedule.sundayBlocks)
    }

    func blocks(for date: Date) -> [ScheduleBlock] {
        CalendarHelper.isSunday(date) ? sunday : weekday
    }

    /// 一天的计划学习分钟数（只算 countsAsStudy 的块）
    var weekdayPlannedMinutes: Int {
        weekday.filter { $0.kind.countsAsStudy }.reduce(0) { $0 + $1.durationMinutes }
    }

    var sundayPlannedMinutes: Int {
        sunday.filter { $0.kind.countsAsStudy }.reduce(0) { $0 + $1.durationMinutes }
    }
}
