//
//  NotificationManager.swift
//  KaoyanWorkbench
//
//  错题「第 7 天回炉」的本地通知。
//
//  用本地通知（UNUserNotificationCenter）而不是远程推送：
//  - 不需要服务器，不需要付费开发者账号
//  - 每道错题单独排一条通知，到点必达，不依赖 App 是否打开
//

import Foundation
import UserNotifications

/// 对外的授权状态（避免视图层直接 import UserNotifications）
enum ReminderPermission: Equatable {
    case notDetermined
    case denied
    case authorized
    case unknown

    var title: String {
        switch self {
        case .notDetermined: return "还没请求授权"
        case .denied: return "已拒绝通知权限"
        case .authorized: return "已允许通知"
        case .unknown: return "状态未知"
        }
    }

    var canSchedule: Bool { self == .authorized }
}

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    /// 所有回炉提醒的 identifier 前缀，便于整体清理
    static let reviewPrefix = "review.week."

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - 授权

    func currentPermission() async -> ReminderPermission {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .unknown
        }
    }

    /// 请求授权，返回是否允许
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            #if DEBUG
            print("[Notifications] 请求授权失败：\(error)")
            #endif
            return false
        }
    }

    // MARK: - 排程

    /// 按当前错题状态重建所有回炉提醒。
    /// 任何让错题状态变化的地方调用它，保证通知与数据一致。
    func syncReviewReminders(mistakes: [Mistake], hour: Int, enabled: Bool) async {
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { $0.hasPrefix(Self.reviewPrefix) }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }

        guard enabled else { return }
        guard await currentPermission().canSchedule else { return }

        // 限制数量：iOS 单个 App 最多 64 条待发通知
        let eligible = mistakes
            .filter { $0.didSameDayReview && !$0.didWeekReview }
            .sorted { $0.weekReviewDue < $1.weekReviewDue }
            .prefix(60)

        for mistake in eligible {
            await schedule(for: mistake, hour: hour)
        }
    }

    private func schedule(for mistake: Mistake, hour: Int) async {
        let dueDay = CalendarHelper.startOfDay(mistake.weekReviewDue)
        var comps = CalendarHelper.shared.dateComponents([.year, .month, .day], from: dueDay)
        comps.hour = max(0, min(23, hour))
        comps.minute = 0

        guard let fireDate = CalendarHelper.shared.date(from: comps) else { return }
        // 已经过点的（比如当天才完成回炉①、而提醒时间已过）顺延到一小时后
        var finalComps = comps
        if fireDate <= Date() {
            let soon = Date().addingTimeInterval(60 * 60)
            finalComps = CalendarHelper.shared.dateComponents(
                [.year, .month, .day, .hour, .minute], from: soon
            )
        }

        let content = UNMutableNotificationContent()
        content.title = "该回炉了"
        let sourceText = mistake.displaySource
        content.body = "\(mistake.subject.rawValue) · \(sourceText)\n\(mistake.point.isEmpty ? "第 7 天回炉" : mistake.point)"
        content.sound = .default
        content.threadIdentifier = "kaoyan.review"

        let trigger = UNCalendarNotificationTrigger(dateMatching: finalComps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.reviewPrefix + mistake.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[Notifications] 排程失败：\(error)")
            #endif
        }
    }

    /// 清掉所有回炉提醒
    func clearAllReviewReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.reviewPrefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// 待发的回炉提醒数量（设置页展示用）
    func pendingReviewCount() async -> Int {
        let pending = await center.pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix(Self.reviewPrefix) }.count
    }
}
