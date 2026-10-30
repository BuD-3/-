//
//  CalendarHelper.swift
//  KaoyanWorkbench
//

import Foundation

enum CalendarHelper {
    static var shared: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        cal.firstWeekday = 2 // 周一为一周第一天
        return cal
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return shared.date(from: comps) ?? Date()
    }

    static func startOfDay(_ date: Date) -> Date {
        shared.startOfDay(for: date)
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        shared.isDate(a, inSameDayAs: b)
    }

    static func isSunday(_ date: Date) -> Bool {
        shared.component(.weekday, from: date) == 1
    }

    static func isSaturday(_ date: Date) -> Bool {
        shared.component(.weekday, from: date) == 7
    }

    /// 从 a 到 b 的整天数（b - a）
    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let start = startOfDay(a)
        let end = startOfDay(b)
        return shared.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func adding(days: Int, to date: Date) -> Date {
        shared.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// 本周周一 0 点
    static func startOfWeek(_ date: Date) -> Date {
        let comps = shared.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return shared.date(from: comps) ?? startOfDay(date)
    }

    static func daysInMonth(_ date: Date) -> Int {
        shared.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    static func monthKey(_ date: Date) -> String {
        let c = shared.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }
}

// MARK: - 格式化

enum ClockFormatter {
    static func hhmm(_ minuteOfDay: Int) -> String {
        let h = minuteOfDay / 60
        let m = minuteOfDay % 60
        return String(format: "%02d:%02d", h, m)
    }

    static func hhmm(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func minutesText(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) 分钟" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) 小时" : "\(h) 小时 \(m) 分"
    }

    static func hoursText(_ hours: Double) -> String {
        if hours == 0 { return "0 小时" }
        if abs(hours.rounded() - hours) < 0.05 {
            return "\(Int(hours.rounded())) 小时"
        }
        return String(format: "%.1f 小时", hours)
    }

    static func monthDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日"
        return f.string(from: date)
    }

    static func fullDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy 年 M 月 d 日 EEEE"
        return f.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let idx = CalendarHelper.shared.component(.weekday, from: date) - 1
        return "周" + names[max(0, min(6, idx))]
    }

    static func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.numberStyle = .currency
        f.currencySymbol = "¥"
        f.maximumFractionDigits = abs(value.rounded() - value) < 0.005 ? 0 : 2
        f.minimumFractionDigits = abs(value.rounded() - value) < 0.005 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? "¥\(Int(value))"
    }

    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
