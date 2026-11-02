//
//  WordBook.swift
//  KaoyanWorkbench
//
//  单词本：每天导入新背会的单词，第二天进入回顾队列。
//  与课表里 07:20 的「英语单词背诵」时段对应。
//

import Foundation

struct WordEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String
    var meaning: String = ""
    /// 录入当天（用于「次日回顾」判定）
    var addedAt: Date = Date()
    /// 最近一次回顾时间
    var lastReviewedAt: Date?
    /// 回顾次数
    var reviewCount: Int = 0
    /// 连续记住次数（达到 3 次算掌握）
    var streak: Int = 0

    var isMastered: Bool { streak >= 3 }

    var addedDayKey: String { DateKey.key(for: addedAt) }

    /// 今天是否需要回顾：录入日期早于今天，且今天还没回顾过
    func isDue(on date: Date = Date()) -> Bool {
        guard !isMastered else { return false }
        let todayKey = DateKey.key(for: date)
        if addedDayKey >= todayKey { return false }
        if let last = lastReviewedAt, DateKey.key(for: last) == todayKey { return false }
        return true
    }
}
