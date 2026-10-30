//
//  ViewModels.swift
//  KaoyanWorkbench
//
//  视图专用的轻量分组/聚合结构体。
//  刻意不使用元组：元组不是 Identifiable，也不能安全地做 KeyPath。
//

import Foundation

/// 本周某一天的学习数据
struct WeekDayStudy: Identifiable, Hashable {
    var id: String { DateKey.key(for: date) }
    let date: Date
    let hours: Double
    let planned: Double
    let isFuture: Bool

    var weekdayLabel: String {
        CalendarHelper.isSameDay(date, Date())
            ? "今"
            : ClockFormatter.weekdayShort(date).replacingOccurrences(of: "周", with: "")
    }
}

/// 某天 + 它的健康记录
struct HealthDay: Identifiable, Hashable {
    var id: String { DateKey.key(for: date) }
    let date: Date
    let entry: HealthEntry

    var dayNumber: Int {
        CalendarHelper.shared.component(.day, from: date)
    }

    var isToday: Bool {
        CalendarHelper.isSameDay(date, Date())
    }

    var shortLabel: String {
        isToday ? "今天" : ClockFormatter.weekdayShort(date).replacingOccurrences(of: "周", with: "")
    }
}

/// 健康记录的历史条目
struct HealthLog: Identifiable, Hashable {
    var id: String { DateKey.key(for: date) }
    let date: Date
    let entry: HealthEntry
}

/// 一个科目下按模块分组
struct ModuleGroup: Identifiable, Hashable {
    var id: String { module }
    let module: String
    let items: [ProgressItem]
}

/// 一段今日复盘
struct ReflectionLog: Identifiable, Hashable {
    var id: String { DateKey.key(for: date) }
    let date: Date
    let text: String
}

/// 带序号的文本行（铁律、建议等）
struct NumberedLine: Identifiable, Hashable {
    var id: Int { number }
    let number: Int
    let text: String

    static func lines(from strings: [String]) -> [NumberedLine] {
        strings.enumerated().map { NumberedLine(number: $0.offset + 1, text: $0.element) }
    }
}
