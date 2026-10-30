//
//  AppStore.swift
//  KaoyanWorkbench
//
//  单一数据源。所有业务数据都是 @Published，变更后自动落盘。
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    // MARK: - 持久化键
    private enum Key {
        static let checkIns = "checkIns"
        static let mistakes = "mistakes"
        static let progress = "progress"
        static let budget = "budget"
        static let todos = "todos"
        static let settings = "settings"
        static let materials = "materials"
    }

    // MARK: - 数据

    @Published private(set) var checkIns: [String: DayCheckIn] = [:]
    @Published private(set) var mistakes: [Mistake] = []
    @Published private(set) var progressItems: [ProgressItem] = []
    @Published private(set) var budgetEntries: [BudgetEntry] = []
    @Published private(set) var todos: [TodoItem] = []
    @Published private(set) var materials: [StudyMaterial] = []
    @Published var settings: AppSettings = AppSettings()

    private var cancellables = Set<AnyCancellable>()
    private var isLoaded = false

    // MARK: - 初始化

    init() {
        load()
        bindAutosave()
        isLoaded = true
        seedScreenshotDemoIfRequested()
        refreshReminders()
    }

    /// 仅用于 CI 自动化截图：启动参数 --seed-demo 时塞几条示例资料。
    /// 正常使用不会触发。
    private func seedScreenshotDemoIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--seed-demo") else { return }
        guard materials.isEmpty else { return }

        let todayKey = DateKey.key(for: Date())
        let mathItem = progressItems.first { $0.subject == .math }
        let csItem = progressItems.first { $0.subject == .cs408 }

        materials = [
            StudyMaterial(
                title: "同济第1章 极限笔记",
                kind: .text,
                body: "1^∞ 型先取对数再等价无穷小，别直接代换。\n洛必达只在 0/0 或 ∞/∞ 可用，用前先验证。",
                note: "第 1 章 第 3 节，课上没听懂的那道例题",
                subject: .math,
                progressItemID: mathItem?.id,
                dateKey: todayKey
            ),
            StudyMaterial(
                title: "408 绪论 · 线性表小结",
                kind: .text,
                body: "顺序表随机访问 O(1)，插入删除 O(n)；链表反之。\n考选择题时特别注意「平均」和「最坏」的区别。",
                note: "王道第 1-2 章",
                subject: .cs408,
                progressItemID: csItem?.id,
                dateKey: todayKey
            ),
            StudyMaterial(
                title: "长难句拆句练习",
                kind: .text,
                body: "主句 + 定语从句 + 状语。先找谓语动词，再定位连词。",
                note: "每天 2 句",
                subject: .english,
                progressItemID: nil,
                dateKey: todayKey
            )
        ]
    }

    private func load() {
        checkIns = Persistence.shared.load([String: DayCheckIn].self, from: Key.checkIns) ?? [:]
        mistakes = Persistence.shared.load([Mistake].self, from: Key.mistakes) ?? []
        progressItems = Persistence.shared.load([ProgressItem].self, from: Key.progress) ?? SeedData.progressItems()
        budgetEntries = Persistence.shared.load([BudgetEntry].self, from: Key.budget) ?? []
        todos = Persistence.shared.load([TodoItem].self, from: Key.todos) ?? []
        materials = Persistence.shared.load([StudyMaterial].self, from: Key.materials) ?? []
        settings = Persistence.shared.load(AppSettings.self, from: Key.settings) ?? AppSettings()
    }

    private func bindAutosave() {
        $checkIns.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.checkIns)
        }.store(in: &cancellables)

        $mistakes.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.mistakes)
        }.store(in: &cancellables)

        $progressItems.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.progress)
        }.store(in: &cancellables)

        $budgetEntries.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.budget)
        }.store(in: &cancellables)

        $todos.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.todos)
        }.store(in: &cancellables)

        $materials.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.materials)
        }.store(in: &cancellables)

        $settings.dropFirst().sink { value in
            Persistence.shared.save(value, to: Key.settings)
        }.store(in: &cancellables)
    }

    // MARK: - 打卡

    func checkIn(for date: Date) -> DayCheckIn {
        let key = DateKey.key(for: date)
        return checkIns[key] ?? DayCheckIn.empty(dateKey: key)
    }

    func todayCheckIn() -> DayCheckIn {
        checkIn(for: Date())
    }

    /// 读取或创建某天记录，并保证非空内容被写回
    @discardableResult
    private func ensureCheckIn(for date: Date) -> DayCheckIn {
        let key = DateKey.key(for: date)
        if let existing = checkIns[key] { return existing }
        let fresh = DayCheckIn.empty(dateKey: key)
        checkIns[key] = fresh
        return fresh
    }

    func toggleBlock(_ block: ScheduleBlock, on date: Date) {
        let key = DateKey.key(for: date)
        var record = ensureCheckIn(for: date)
        if record.completedBlockIDs.contains(block.id) {
            record.completedBlockIDs.remove(block.id)
        } else {
            record.completedBlockIDs.insert(block.id)
        }
        record.updatedAt = Date()
        checkIns[key] = record
    }

    func setBlocks(_ ids: Set<String>, on date: Date) {
        let key = DateKey.key(for: date)
        var record = ensureCheckIn(for: date)
        record.completedBlockIDs = ids
        record.updatedAt = Date()
        checkIns[key] = record
    }

    func setExtraMinutes(_ minutes: Int, on date: Date) {
        let key = DateKey.key(for: date)
        var record = ensureCheckIn(for: date)
        record.extraStudyMinutes = max(0, minutes)
        record.updatedAt = Date()
        checkIns[key] = record
    }

    func setReflection(_ text: String, on date: Date) {
        let key = DateKey.key(for: date)
        var record = ensureCheckIn(for: date)
        record.reflection = text
        record.updatedAt = Date()
        checkIns[key] = record
    }

    func updateHealth(_ entry: HealthEntry, on date: Date) {
        let key = DateKey.key(for: date)
        var record = ensureCheckIn(for: date)
        record.health = entry
        record.updatedAt = Date()
        checkIns[key] = record
    }

    /// 某天已完成的课表区块
    func completedBlocks(on date: Date) -> Set<String> {
        checkIns[DateKey.key(for: date)]?.completedBlockIDs ?? []
    }

    /// 某天的有效学习小时数（勾选的课表块 + 补记）
    func studyHours(on date: Date) -> Double {
        let record = checkIns[DateKey.key(for: date)] ?? DayCheckIn.empty(dateKey: DateKey.key(for: date))
        let blocks = DailySchedule.blocks(for: date)
        let fromBlocks = blocks
            .filter { $0.kind.countsAsStudy && record.completedBlockIDs.contains($0.id) }
            .reduce(0.0) { $0 + $1.durationHours }
        return fromBlocks + Double(record.extraStudyMinutes) / 60.0
    }

    func plannedHours(on date: Date) -> Double {
        DailySchedule.studyHours(for: date)
    }

    /// 完成度 0...1
    func completionRatio(on date: Date) -> Double {
        let planned = plannedHours(on: date)
        guard planned > 0 else { return 0 }
        return min(1, studyHours(on: date) / planned)
    }

    var todayDate: Date { CalendarHelper.startOfDay(Date()) }

    /// 本周每日学习时长（周一 → 周日）
    func weekStudyHours() -> [WeekDayStudy] {
        let monday = CalendarHelper.startOfWeek(Date())
        let today = todayDate
        return (0..<7).map { offset in
            let day = CalendarHelper.adding(days: offset, to: monday)
            return WeekDayStudy(
                date: day,
                hours: studyHours(on: day),
                planned: plannedHours(on: day),
                isFuture: CalendarHelper.startOfDay(day) > today
            )
        }
    }

    var weekTotalHours: Double {
        weekStudyHours().reduce(0) { $0 + $1.hours }
    }

    var weekPlannedHours: Double {
        weekStudyHours().filter { !$0.isFuture }.reduce(0) { $0 + $1.planned }
    }

    /// 连续打卡天数：从今天（或昨天）往回数，当天有效学习 > 0 才算
    var streakDays: Int {
        var count = 0
        var cursor = todayDate
        if studyHours(on: cursor) <= 0 {
            cursor = CalendarHelper.adding(days: -1, to: cursor)
        }
        var guardCount = 0
        while studyHours(on: cursor) > 0 && guardCount < 2000 {
            count += 1
            cursor = CalendarHelper.adding(days: -1, to: cursor)
            guardCount += 1
        }
        return count
    }

    /// 累计学习小时数（自备考启动以来，对齐 9.5 小时/天 基准）
    var totalStudyHours: Double {
        checkIns.values.reduce(0) { sum, record in
            guard let date = DateKey.date(from: record.dateKey) else { return sum }
            let blocks = DailySchedule.blocks(for: date)
            let hours = blocks
                .filter { $0.kind.countsAsStudy && record.completedBlockIDs.contains($0.id) }
                .reduce(0.0) { $0 + $1.durationHours }
            return sum + hours + Double(record.extraStudyMinutes) / 60.0
        }
    }

    // MARK: - 错题本

    func addMistake(_ mistake: Mistake) {
        var copy = mistake
        copy.createdAt = Date()
        mistakes.insert(copy, at: 0)
        refreshReminders()
    }

    func updateMistake(_ mistake: Mistake) {
        if let idx = mistakes.firstIndex(where: { $0.id == mistake.id }) {
            mistakes[idx] = mistake
        }
    }

    func deleteMistake(_ mistake: Mistake) {
        mistakes.removeAll { $0.id == mistake.id }
        refreshReminders()
    }

    /// 回炉①：当日回炉
    func markSameDayReviewed(_ mistake: Mistake) {
        guard let idx = mistakes.firstIndex(where: { $0.id == mistake.id }) else { return }
        mistakes[idx].didSameDayReview = true
        mistakes[idx].sameDayReviewedAt = Date()
        refreshReminders()
    }

    /// 回炉②：第 7 天回炉
    func markWeekReviewed(_ mistake: Mistake) {
        guard let idx = mistakes.firstIndex(where: { $0.id == mistake.id }) else { return }
        mistakes[idx].didWeekReview = true
        mistakes[idx].weekReviewedAt = Date()
        refreshReminders()
    }

    func undoReviews(_ mistake: Mistake) {
        guard let idx = mistakes.firstIndex(where: { $0.id == mistake.id }) else { return }
        mistakes[idx].didSameDayReview = false
        mistakes[idx].didWeekReview = false
        mistakes[idx].sameDayReviewedAt = nil
        mistakes[idx].weekReviewedAt = nil
        refreshReminders()
    }

    /// 今日需要回炉的错题（当日回炉 + 到期回炉②）
    func reviewQueue(on date: Date = Date()) -> [Mistake] {
        let today = CalendarHelper.startOfDay(date)
        return mistakes.filter { mistake in
            let created = CalendarHelper.startOfDay(mistake.createdAt)
            if CalendarHelper.isSameDay(created, today), !mistake.didSameDayReview { return true }
            return mistake.isWeekReviewDue(on: date)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    var dueWeekReviews: [Mistake] {
        mistakes.filter { $0.isWeekReviewDue() }
    }

    var unmasteredMistakes: [Mistake] {
        mistakes.filter { $0.status != .mastered }
    }

    // MARK: - 进度追踪

    func toggleProgress(_ item: ProgressItem) {
        guard let idx = progressItems.firstIndex(where: { $0.id == item.id }) else { return }
        progressItems[idx].isDone.toggle()
        progressItems[idx].completedAt = progressItems[idx].isDone ? Date() : nil
    }

    func updateProgress(_ item: ProgressItem) {
        if let idx = progressItems.firstIndex(where: { $0.id == item.id }) {
            progressItems[idx] = item
        }
    }

    func progressStats(for subject: Subject) -> (done: Int, total: Int, ratio: Double) {
        let items = progressItems.filter { $0.subject == subject }
        let done = items.filter { $0.isDone }.count
        let ratio = items.isEmpty ? 0 : Double(done) / Double(items.count)
        return (done, items.count, ratio)
    }

    var overallProgress: Double {
        guard !progressItems.isEmpty else { return 0 }
        return Double(progressItems.filter { $0.isDone }.count) / Double(progressItems.count)
    }

    func groupedProgress(for subject: Subject) -> [ModuleGroup] {
        let items = progressItems.filter { $0.subject == subject }
        var order: [String] = []
        var map: [String: [ProgressItem]] = [:]
        for item in items {
            if map[item.module] == nil { order.append(item.module) }
            map[item.module, default: []].append(item)
        }
        return order.map { ModuleGroup(module: $0, items: map[$0] ?? []) }
    }

    /// 依据当前月份，给出这个月应该推进的进度项。
    /// 备考尚未开始时（今天早于 2026-11-01），回落到计划起点那个月，
    /// 避免打开 App 看到「0 项」不知所措。
    func currentMonthFocus() -> [ProgressItem] {
        let now = Date()
        let key = CalendarHelper.monthKey(now)
        let current = progressItems.filter { $0.planMonthList.contains(key) && !$0.isDone }
        if !current.isEmpty { return current }
        if now < PlanTimeline.startDate {
            let startKey = CalendarHelper.monthKey(PlanTimeline.startDate)
            return progressItems.filter { $0.planMonthList.contains(startKey) && !$0.isDone }
        }
        return []
    }

    /// 当前焦点是否为「备考启动前」的预读
    var isBeforePlanStart: Bool {
        Date() < PlanTimeline.startDate
    }

    // MARK: - 预算

    func addBudgetEntry(_ entry: BudgetEntry) {
        budgetEntries.append(entry)
    }

    func deleteBudgetEntry(_ entry: BudgetEntry) {
        budgetEntries.removeAll { $0.id == entry.id }
    }

    var totalSpent: Double {
        budgetEntries.reduce(0) { $0 + $1.amount }
    }

    var remainingFunds: Double {
        BudgetPlan.totalFunds - totalSpent
    }

    var spentRatio: Double {
        min(1, totalSpent / BudgetPlan.totalFunds)
    }

    func spent(for category: BudgetCategory) -> Double {
        budgetEntries.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
    }

    func spentThisMonth() -> Double {
        let key = CalendarHelper.monthKey(Date())
        return budgetEntries
            .filter { CalendarHelper.monthKey($0.date) == key }
            .reduce(0) { $0 + $1.amount }
    }

    /// 备考月序号（第几个月），用于算月均可用额度
    var elapsedMonths: Int {
        let start = PlanTimeline.startDate
        let now = Date()
        if now < start { return 0 }
        let days = CalendarHelper.daysBetween(start, now)
        return max(1, days / 30 + 1)
    }

    var monthlyAllowance: Double {
        // 剩余可动用额度 / 剩余月份
        let remainingMonths = max(1, 14 - elapsedMonths + 1)
        return max(0, remainingFunds) / Double(remainingMonths)
    }

    /// 是否处于预算危险区
    var budgetStatus: BudgetStatus {
        if remainingFunds < 0 { return .over }
        if totalSpent > BudgetPlan.plannedSpend { return .warning }
        return .healthy
    }

    // MARK: - 待办

    func addTodo(_ todo: TodoItem) {
        todos.insert(todo, at: 0)
    }

    func toggleTodo(_ todo: TodoItem) {
        guard let idx = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[idx].isDone.toggle()
        todos[idx].completedAt = todos[idx].isDone ? Date() : nil
    }

    func updateTodo(_ todo: TodoItem) {
        if let idx = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[idx] = todo
        }
    }

    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
    }

    var openTodos: [TodoItem] {
        todos.filter { !$0.isDone }
            .sorted { a, b in
                switch (a.dueDate, b.dueDate) {
                case let (da?, db?): return da < db
                case (nil, _?): return false
                case (_?, nil): return true
                default: return a.createdAt > b.createdAt
                }
            }
    }

    func todosDueToday() -> [TodoItem] {
        todos.filter { $0.isDueToday }
    }

    // MARK: - 健康

    func health(on date: Date) -> HealthEntry {
        checkIn(for: date).health
    }

    var weekExerciseMinutes: Int {
        let monday = CalendarHelper.startOfWeek(Date())
        var total = 0
        for offset in 0..<7 {
            let day = CalendarHelper.adding(days: offset, to: monday)
            if CalendarHelper.startOfDay(day) > todayDate { break }
            total += health(on: day).exerciseMinutes
        }
        return total
    }

    var weekExerciseDays: Int {
        let monday = CalendarHelper.startOfWeek(Date())
        var count = 0
        for offset in 0..<7 {
            let day = CalendarHelper.adding(days: offset, to: monday)
            if CalendarHelper.startOfDay(day) > todayDate { break }
            let e = health(on: day)
            if e.didExercise || e.exerciseMinutes > 0 { count += 1 }
        }
        return count
    }

    var averageSleepHours: Double {
        let monday = CalendarHelper.startOfWeek(Date())
        var samples: [Double] = []
        for offset in 0..<7 {
            let day = CalendarHelper.adding(days: offset, to: monday)
            if CalendarHelper.startOfDay(day) > todayDate { break }
            let s = health(on: day).sleepHours
            if s > 0 { samples.append(s) }
        }
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }

    /// 本周健康达标分（0...1）：运动 3 天 + 平均睡眠 ≥7h
    var healthScore: Double {
        let exercisePart = min(1, Double(weekExerciseDays) / 3.0) * 0.5
        let sleepPart = min(1, max(0, (averageSleepHours - 5) / 2.5)) * 0.5
        return exercisePart + sleepPart
    }

    var recentHealthEntries: [HealthLog] {
        checkIns.values
            .compactMap { record -> HealthLog? in
                guard let date = DateKey.date(from: record.dateKey), record.health.isLogged else { return nil }
                return HealthLog(date: date, entry: record.health)
            }
            .sorted { $0.date > $1.date }
            .prefix(14)
            .map { $0 }
    }

    // MARK: - 资料库

    func addMaterial(_ material: StudyMaterial) {
        var copy = material
        if copy.createdAt > Date().addingTimeInterval(60) { copy.createdAt = Date() }
        materials.insert(copy, at: 0)
    }

    func updateMaterial(_ material: StudyMaterial) {
        if let idx = materials.firstIndex(where: { $0.id == material.id }) {
            materials[idx] = material
        }
    }

    func deleteMaterial(_ material: StudyMaterial) {
        if let fileName = material.fileName {
            MaterialStorage.delete(fileName: fileName)
        }
        materials.removeAll { $0.id == material.id }
    }

    /// 某一天上传的资料
    func materials(on date: Date) -> [StudyMaterial] {
        let key = DateKey.key(for: date)
        return materials
            .filter { $0.dateKey == key }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 某个进度项（章节）下的资料
    func materials(forProgressItem id: UUID) -> [StudyMaterial] {
        materials
            .filter { $0.progressItemID == id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func materialCount(forProgressItem id: UUID) -> Int {
        materials.reduce(0) { $0 + ($1.progressItemID == id ? 1 : 0) }
    }

    var totalMaterialCount: Int { materials.count }

    var totalMaterialBytes: Int64 { MaterialStorage.totalSize() }

    var totalMaterialSize: String {
        MaterialStorage.formattedSize(totalMaterialBytes)
    }

    /// 按科目筛选（nil 表示不筛选）
    func filteredMaterials(subject: Subject?, query: String) -> [StudyMaterial] {
        var list = materials
        if let subject {
            list = list.filter { $0.subject == subject }
        }
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !keyword.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(keyword)
                || $0.note.localizedCaseInsensitiveContains(keyword)
                || $0.body.localizedCaseInsensitiveContains(keyword)
            }
        }
        return list.sorted { $0.createdAt > $1.createdAt }
    }

    /// 供 UI 选择「关联章节」用
    func progressItems(for subject: Subject?) -> [ProgressItem] {
        guard let subject else { return progressItems }
        return progressItems.filter { $0.subject == subject }
    }

    func progressItem(with id: UUID?) -> ProgressItem? {
        guard let id else { return nil }
        return progressItems.first { $0.id == id }
    }

    // MARK: - 提醒

    /// 按当前设置与错题状态重建本地通知
    func refreshReminders() {
        let snapshot = mistakes
        let hour = settings.reminderHour
        let enabled = settings.remindersEnabled
        Task {
            await NotificationManager.shared.syncReviewReminders(
                mistakes: snapshot, hour: hour, enabled: enabled
            )
        }
    }

    /// 开关回炉提醒。开启时会请求系统授权；被拒绝则自动关回去。
    func setRemindersEnabled(_ enabled: Bool) {
        settings.remindersEnabled = enabled
        guard enabled else {
            Task { await NotificationManager.shared.clearAllReviewReminders() }
            return
        }
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if !granted {
                settings.remindersEnabled = false
            }
            refreshReminders()
        }
    }

    func setReminderHour(_ hour: Int) {
        settings.reminderHour = max(0, min(23, hour))
        refreshReminders()
    }

    func reminderPermission() async -> ReminderPermission {
        await NotificationManager.shared.currentPermission()
    }

    func pendingReminderCount() async -> Int {
        await NotificationManager.shared.pendingReviewCount()
    }

    // MARK: - 数据管理

    func resetProgressToSeed() {
        progressItems = SeedData.progressItems()
    }

    func clearAllData() {
        for material in materials {
            if let fileName = material.fileName {
                MaterialStorage.delete(fileName: fileName)
            }
        }
        checkIns = [:]
        mistakes = []
        progressItems = SeedData.progressItems()
        budgetEntries = []
        todos = []
        materials = []
        settings = AppSettings()
    }
}

// MARK: - 设置

struct AppSettings: Codable {
    /// 是否开启每周日提醒休息（展示用）
    var showSundayRestCard: Bool = true
    /// 初试日期（可用来自定义，默认 2027-12-18）
    var examDateOverride: Date?
    /// 错题第 7 天回炉提醒
    var remindersEnabled: Bool = false
    /// 提醒时间（小时，0...23）
    var reminderHour: Int = 9

    init() {}

    // 手写解码：新增字段用 decodeIfPresent，
    // 这样老版本存下的 JSON 不会因为缺 key 直接解码失败。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        showSundayRestCard = try c.decodeIfPresent(Bool.self, forKey: .showSundayRestCard) ?? true
        examDateOverride = try c.decodeIfPresent(Date.self, forKey: .examDateOverride)
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 9
    }
}

enum BudgetStatus {
    case healthy
    case warning
    case over

    var title: String {
        switch self {
        case .healthy: return "弹药充足"
        case .warning: return "已超计划线"
        case .over: return "弹药告急"
        }
    }

    var symbolName: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .over: return "xmark.octagon.fill"
        }
    }
}

