//
//  ExamPlan.swift
//  KaoyanWorkbench
//
//  考研作战计划的静态数据层。
//  数据来源：2028考研_河南大学人工智能_脱产14个月作战计划.xlsx
//  （02 14个月计划 / 03 每日课表 / 04 进度追踪 / 05 两万块预算）
//

import Foundation

// MARK: - 科目

enum Subject: String, CaseIterable, Codable, Identifiable, Hashable {
    case math = "数学二"
    case cs408 = "408"
    case english = "英语二"
    case politics = "政治"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .math: return "数学"
        case .cs408: return "408"
        case .english: return "英语"
        case .politics: return "政治"
        }
    }

    /// 目标分 / 冲刺分 / 底线分（来自 01 总览「二、目标分数」）
    var targetScore: Int {
        switch self {
        case .math: return 122
        case .cs408: return 105
        case .english: return 58
        case .politics: return 68
        }
    }

    var sprintScore: Int {
        switch self {
        case .math: return 132
        case .cs408: return 115
        case .english: return 65
        case .politics: return 72
        }
    }

    var floorScore: Int {
        switch self {
        case .math: return 95
        case .cs408: return 85
        case .english: return 50
        case .politics: return 60
        }
    }

    var fullScore: Int {
        self == .math || self == .cs408 ? 150 : 100
    }
}

// MARK: - 阶段

enum PlanStage: String, Codable, CaseIterable, Identifiable {
    case foundation = "地基期"
    case roundOne = "一轮期"
    case strengthen = "强化期"
    case sprint = "冲刺期"
    case examWeek = "考前"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .foundation: return "打地基：高数 + 数据结构并行，不求快只求稳"
        case .roundOne: return "一轮铺开：数学第二轮 + 408 四门推进"
        case .strengthen: return "强化攻坚：政治加入，408 转入真题"
        case .sprint: return "冲刺收网：真题限时，错题回炉"
        case .examWeek: return "考前调整：按考试时间做模拟，睡够"
        }
    }
}

// MARK: - 时间轴

enum PlanTimeline {
    /// 备考启动日（含）
    static let startDate: Date = CalendarHelper.date(2026, 11, 1)
    /// 初试日（预计 2027-12-18，以教育部公告为准）
    static let examDate: Date = CalendarHelper.date(2027, 12, 18)
    /// 备考总天数
    static var totalDays: Int {
        CalendarHelper.daysBetween(startDate, examDate)
    }
}

// MARK: - 14 个月逐月计划

struct MonthPlan: Identifiable, Codable, Hashable {
    let id: String          // "2026-11"
    let stage: PlanStage
    let math: String
    let cs408: String
    let english: String
    let politics: String
    let milestone: String

    var monthStart: Date {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return PlanTimeline.startDate }
        return CalendarHelper.date(parts[0], parts[1], 1)
    }

    var title: String {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return id }
        return "\(parts[0]) 年 \(parts[1]) 月"
    }
}

enum ExamPlanData {
    static let months: [MonthPlan] = [
        MonthPlan(id: "2026-11", stage: .foundation,
                  math: "高数：函数、极限、连续（同济第 1 章 + 基础课）；每天 30 道纯计算",
                  cs408: "数据结构：绪论、线性表（王道第 1-2 章）",
                  english: "单词 Unit1-4（每天 100 词，滚动复习）+ 长难句入门",
                  politics: "—",
                  milestone: "极限计算正确率 ≥80%；线性表课后题全部完成"),
        MonthPlan(id: "2026-12", stage: .foundation,
                  math: "高数：一元函数微分学（同济第 2 章）；导数/微分/中值定理初步",
                  cs408: "数据结构：栈、队列、串、数组（第 3-4 章）",
                  english: "单词 Unit5-8 + 长难句每日 2 句",
                  politics: "—",
                  milestone: "求导运算准确率 ≥90%"),
        MonthPlan(id: "2027-01", stage: .foundation,
                  math: "高数：一元函数积分学（同济第 3 章）；不定/定积分、变限积分",
                  cs408: "数据结构：树与二叉树、图（第 5-6 章）",
                  english: "单词 Unit9-12 + 外刊精读 2 篇/周",
                  politics: "—",
                  milestone: "地基自测①：高数基础卷 ≥90/150"),
        MonthPlan(id: "2027-02", stage: .foundation,
                  math: "高数：多元函数微积分、常微分方程（同济第 4-5 章）",
                  cs408: "数据结构：查找、排序（第 7-8 章）+ 王道数据结构二刷",
                  english: "单词 Unit13-16 + 英语一真题阅读（2005-2010）精读",
                  politics: "—",
                  milestone: "高数基础课全部完成；数据结构一轮完成"),
        MonthPlan(id: "2027-03", stage: .roundOne,
                  math: "高数第二轮：极限 + 微分（基础讲义配套练习）",
                  cs408: "计组：计算机系统概述、数据的表示与运算（第 1-2 章）",
                  english: "英语二真题阅读 2010-2012 精读",
                  politics: "—",
                  milestone: "408 计组选择题正确率 ≥70%"),
        MonthPlan(id: "2027-04", stage: .roundOne,
                  math: "高数第二轮：积分 + 多元（基础讲义配套练习）",
                  cs408: "计组：存储系统、指令系统、CPU、总线（第 3-7 章）",
                  english: "英语二真题阅读 2013-2015",
                  politics: "—",
                  milestone: "计组一轮完成"),
        MonthPlan(id: "2027-05", stage: .roundOne,
                  math: "线代：行列式、矩阵、向量",
                  cs408: "操作系统：概述、进程管理、内存管理（第 1-3 章）+ 数据结构真题",
                  english: "英语二真题阅读 2016-2018",
                  politics: "—",
                  milestone: "线代前三章课后题完成"),
        MonthPlan(id: "2027-06", stage: .roundOne,
                  math: "线代：线性方程组、特征值特征向量、二次型",
                  cs408: "操作系统：文件管理、IO 管理（第 4-5 章）",
                  english: "英语二真题阅读 2019-2021",
                  politics: "—",
                  milestone: "数二一轮自测 ≥95/150；408 四门一轮完成"),
        MonthPlan(id: "2027-07", stage: .strengthen,
                  math: "数二强化：极限/微分/积分题型专项 + 660 题",
                  cs408: "计算机网络（王道 + 谢希仁，全章）",
                  english: "英语二真题二刷（阅读）",
                  politics: "政治强化：马原",
                  milestone: "408 全部一轮完成，进入真题阶段"),
        MonthPlan(id: "2027-08", stage: .strengthen,
                  math: "数二强化：多元/微分方程/线代题型 + 1000 题",
                  cs408: "408 真题一轮：2010-2015（限时 3h）",
                  english: "真题二刷 + 作文入门",
                  politics: "政治：毛中特、史纲",
                  milestone: "408 真题 2010-2015 均分 ≥90"),
        MonthPlan(id: "2027-09", stage: .strengthen,
                  math: "数二 1000 题收尾 + 错题重做",
                  cs408: "408 真题一轮：2016-2022（限时 3h）",
                  english: "真题三刷 + 作文模板初稿",
                  politics: "政治：思修、时政",
                  milestone: "数二强化自测 ≥110/150；核对 2028 招生简章"),
        MonthPlan(id: "2027-10", stage: .sprint,
                  math: "数二真题 2010-2016（限时 3 小时）",
                  cs408: "408 真题二刷 + 错题",
                  english: "英语二套卷 + 作文定稿",
                  politics: "肖八 + 背诵手册",
                  milestone: "完成报名；数二真题客观题 ≥65/80"),
        MonthPlan(id: "2027-11", stage: .sprint,
                  math: "数二真题 2017-2027（限时）+ 模拟卷",
                  cs408: "408 真题二刷收尾 + 模拟",
                  english: "英语二套卷限时",
                  politics: "肖四背诵（分析题）",
                  milestone: "数二模拟 ≥120/150；408 模拟 ≥105"),
        MonthPlan(id: "2027-12", stage: .examWeek,
                  math: "错题重做 + 2 套模拟（严格按考试时间）",
                  cs408: "错题重做 + 2 套模拟",
                  english: "作文模板 + 2 套套卷",
                  politics: "肖四背诵 + 时政",
                  milestone: "12/18–19 初试（预计）")
    ]

    /// 当前处于哪个月份计划
    static func currentMonth(on date: Date = Date()) -> MonthPlan? {
        let cal = CalendarHelper.shared
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let year = comps.year, let month = comps.month else { return nil }
        let key = String(format: "%04d-%02d", year, month)
        if let exact = months.first(where: { $0.id == key }) { return exact }
        // 备考尚未开始 → 返回第一期；已考完 → 返回最后一期
        if date < PlanTimeline.startDate { return months.first }
        return months.last
    }

    static func stage(for date: Date = Date()) -> PlanStage {
        currentMonth(on: date)?.stage ?? .foundation
    }
}

// MARK: - 每日课表（03 每日课表）

enum ScheduleBlockKind: String, Codable, CaseIterable {
    case english
    case math
    case cs408
    case rest       // 起床/午餐/晚餐等不计入学习时长
    case review     // 错题复盘
    case flexible   // 弹性时间

    /// 是否计入有效学习时长
    var countsAsStudy: Bool {
        switch self {
        case .rest, .flexible: return false
        default: return true
        }
    }

    var subject: Subject? {
        switch self {
        case .english: return .english
        case .math: return .math
        case .cs408: return .cs408
        case .review: return .math
        default: return nil
        }
    }
}

struct ScheduleBlock: Identifiable, Codable, Hashable {
    let id: String
    let startMinute: Int
    let endMinute: Int
    let title: String
    let detail: String
    let kind: ScheduleBlockKind

    var durationMinutes: Int { max(0, endMinute - startMinute) }
    var durationHours: Double { Double(durationMinutes) / 60.0 }
    var timeRangeText: String {
        "\(ClockFormatter.hhmm(startMinute))–\(ClockFormatter.hhmm(endMinute))"
    }
}

enum DailySchedule {
    /// 周一至周六课表（03 每日课表）
    static let weekdayBlocks: [ScheduleBlock] = [
        ScheduleBlock(id: "w-morning-wake", startMinute: 6 * 60 + 40, endMinute: 7 * 60 + 20,
                      title: "起床 · 早餐 · 英语单词 100 个",
                      detail: "单词放在早上，不占用大块时间", kind: .english),
        ScheduleBlock(id: "w-reading", startMinute: 7 * 60 + 20, endMinute: 8 * 60 + 50,
                      title: "英语：长难句 / 阅读精读",
                      detail: "1.5 小时，脑子最清醒之一", kind: .english),
        ScheduleBlock(id: "w-math", startMinute: 9 * 60, endMinute: 12 * 60,
                      title: "数学（3 小时）",
                      detail: "一天中最好的时段给最难的东西", kind: .math),
        ScheduleBlock(id: "w-lunch", startMinute: 12 * 60, endMinute: 14 * 60,
                      title: "午餐 + 午休（30 分钟）",
                      detail: "午休必须睡，否则下午报废", kind: .rest),
        ScheduleBlock(id: "w-408", startMinute: 14 * 60, endMinute: 17 * 60 + 30,
                      title: "408（3.5 小时）",
                      detail: "与数学同等优先级，绝不让位", kind: .cs408),
        ScheduleBlock(id: "w-dinner", startMinute: 17 * 60 + 30, endMinute: 19 * 60,
                      title: "晚餐 + 散步",
                      detail: "离开书桌，不刷手机", kind: .rest),
        ScheduleBlock(id: "w-review", startMinute: 19 * 60, endMinute: 20 * 60 + 30,
                      title: "当天错题复盘（数学 + 408）",
                      detail: "当天错题当天清，不过夜", kind: .review),
        ScheduleBlock(id: "w-words2", startMinute: 20 * 60 + 30, endMinute: 21 * 60 + 30,
                      title: "英语单词二刷 + 明日计划",
                      detail: "10 分钟写当日复盘，3 行即可", kind: .english),
        ScheduleBlock(id: "w-flex", startMinute: 21 * 60 + 30, endMinute: 22 * 60 + 30,
                      title: "弹性时间（补进度 / 放松）",
                      detail: "不安排硬任务，防止透支", kind: .flexible)
    ]

    /// 周日：全休（前期）/ 半天复盘（9 月起）
    static let sundayBlocks: [ScheduleBlock] = [
        ScheduleBlock(id: "s-rest", startMinute: 7 * 60, endMinute: 10 * 60,
                      title: "自然醒 · 充分休息",
                      detail: "每周必须休满一天，这是计划的一部分", kind: .rest),
        ScheduleBlock(id: "s-weekly", startMinute: 10 * 60, endMinute: 12 * 60,
                      title: "周复盘：错题回炉 + 进度对表",
                      detail: "只看错题与进度表，不学新内容", kind: .review),
        ScheduleBlock(id: "s-free", startMinute: 14 * 60, endMinute: 21 * 60,
                      title: "完全自由",
                      detail: "陪家人、运动、出门走走，别碰手机刷题群", kind: .rest)
    ]

    static func blocks(for date: Date) -> [ScheduleBlock] {
        CalendarHelper.isSunday(date) ? sundayBlocks : weekdayBlocks
    }

    /// 有效学习时长（小时/天）
    static func studyHours(for date: Date) -> Double {
        blocks(for: date).filter { $0.kind.countsAsStudy }.reduce(0) { $0 + $1.durationHours }
    }
}

// MARK: - 关键时间节点（01 总览「三、关键时间节点」）

struct Milestone: Identifiable, Codable, Hashable {
    let id: String
    let month: Int
    let day: Int
    let year: Int
    let title: String
    let action: String

    var date: Date { CalendarHelper.date(year, month, day) }

    var dateText: String {
        String(format: "%04d.%02d.%02d", year, month, day)
    }
}

enum MilestoneData {
    static let all: [Milestone] = [
        Milestone(id: "m-start", month: 11, day: 1, year: 2026,
                  title: "备考启动", action: "地基期开始：高数第一章 + 数据结构第一章"),
        Milestone(id: "m-r1", month: 3, day: 1, year: 2027,
                  title: "一轮启动", action: "数二第二轮 + 408 计组"),
        Milestone(id: "m-strengthen", month: 7, day: 1, year: 2027,
                  title: "强化启动", action: "政治正式加入；408 入门计网 + 真题"),
        Milestone(id: "m-guide", month: 9, day: 15, year: 2027,
                  title: "2028 招生简章发布", action: "核对科目是否仍为 302 数二 + 408；核对同等学力「具体学业要求」"),
        Milestone(id: "m-pre-reg", month: 10, day: 10, year: 2027,
                  title: "预报名（预计）", action: "研招网注册、填信息、准备学历材料"),
        Milestone(id: "m-reg", month: 10, day: 15, year: 2027,
                  title: "正式报名（预计）", action: "逾期不补办，务必提前完成"),
        Milestone(id: "m-confirm", month: 11, day: 5, year: 2027,
                  title: "网上确认", action: "户口本 / 学历证明 / 照片，同等学力按往届生要求"),
        Milestone(id: "m-ticket", month: 12, day: 5, year: 2027,
                  title: "打印准考证", action: "A4 白纸双面打印"),
        Milestone(id: "m-exam", month: 12, day: 18, year: 2027,
                  title: "初试", action: "政治 / 英语二 / 数学二 / 408"),
        Milestone(id: "m-score", month: 2, day: 25, year: 2028,
                  title: "初试成绩", action: "—"),
        Milestone(id: "m-list", month: 3, day: 15, year: 2028,
                  title: "复试线 / 复试名单", action: "河南大学人工智能学院官网"),
        Milestone(id: "m-interview", month: 3, day: 25, year: 2028,
                  title: "复试", action: "机试 30% + 英语 10% + 面试 60% + 同等学力加试两门")
    ]

    /// 未来最近的一个节点
    static func next(after date: Date = Date()) -> Milestone? {
        all.filter { $0.date >= CalendarHelper.startOfDay(date) }.min { $0.date < $1.date }
    }
}

// MARK: - 每日复盘的三条铁律

enum IronRules {
    static let all: [String] = [
        "身份已确定是同等学力。2027 年 9 月新简章出来后，务必再次确认「具体学业要求」，并提前打电话给研招办（0371-22867269）。",
        "408 从第一天起与数学并行。150 分、四门课，最容易被拖到下半年，也最容易崩在这里。",
        "可持续优先于突击。14 个月真正的对手不是难度，是中途放弃。每周固定休一天，每月一次限时自测。"
    ]
}
