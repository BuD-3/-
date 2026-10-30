//
//  Models.swift
//  KaoyanWorkbench
//
//  持久化的业务实体。全部 Codable，便于用 JSON 存在 Documents 目录。
//

import Foundation

// MARK: - 日期键

/// "yyyy-MM-dd" 字符串，用作每日记录的稳定主键（与设备语言/时区无关）。
enum DateKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }
}

// MARK: - 每日打卡

struct DayCheckIn: Codable, Identifiable, Hashable {
    var id: String { dateKey }
    let dateKey: String
    /// 已勾选的课表区块 id
    var completedBlockIDs: Set<String> = []
    /// 手动补记的学习分钟数（课表之外）
    var extraStudyMinutes: Int = 0
    /// 今日复盘（3 行即可）
    var reflection: String = ""
    /// 今日健康记录
    var health: HealthEntry = HealthEntry()
    var updatedAt: Date = Date()

    static func empty(dateKey: String) -> DayCheckIn {
        DayCheckIn(dateKey: dateKey)
    }
}

// MARK: - 健康运动

struct HealthEntry: Codable, Hashable {
    var didExercise: Bool = false
    var exerciseMinutes: Int = 0
    var exerciseType: String = ""
    var walkedMinutes: Int = 0
    var sleepHours: Double = 0
    var waterCups: Int = 0
    var note: String = ""

    var isLogged: Bool {
        didExercise || exerciseMinutes > 0 || walkedMinutes > 0 || sleepHours > 0 || waterCups > 0
    }
}

enum ExerciseType: String, CaseIterable, Identifiable {
    case walk = "散步"
    case run = "跑步"
    case cycle = "骑行"
    case strength = "力量"
    case rope = "跳绳"
    case ball = "球类"
    case stretch = "拉伸"
    case other = "其他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .cycle: return "figure.outdoor.cycle"
        case .strength: return "figure.strengthtraining.traditional"
        case .rope: return "figure.jumprope"
        case .ball: return "figure.basketball"
        case .stretch: return "figure.flexibility"
        case .other: return "figure.mixed.cardio"
        }
    }
}

// MARK: - 错题本

enum MistakeType: String, CaseIterable, Codable, Identifiable {
    case calculation = "计算错"
    case concept = "概念错"
    case method = "方法错"
    case careless = "看错题"
    case blank = "完全不会"
    case time = "时间不够"

    var id: String { rawValue }
}

enum ReviewStatus: String, CaseIterable, Codable, Identifiable {
    case fresh = "待回炉①"
    case pendingDay = "待回炉②"
    case mastered = "已掌握"

    var id: String { rawValue }
}

struct Mistake: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var subject: Subject
    var source: String            // 题号 / 卷子
    var point: String             // 考点
    var errorType: MistakeType
    var correctIdea: String       // 正确思路（一句话）

    /// 回炉①：当天完成
    var didSameDayReview: Bool = false
    var sameDayReviewedAt: Date?
    /// 回炉②：第 7 天完成
    var didWeekReview: Bool = false
    var weekReviewedAt: Date?

    /// 回炉②的应做日期 = 录入日 + 7 天
    var weekReviewDue: Date {
        CalendarHelper.shared.date(byAdding: .day, value: 7, to: CalendarHelper.startOfDay(createdAt)) ?? createdAt
    }

    var status: ReviewStatus {
        if !didSameDayReview { return .fresh }
        if !didWeekReview { return .pendingDay }
        return .mastered
    }

    /// 到期待回炉（只算已过当日回炉关的）
    func isWeekReviewDue(on date: Date = Date()) -> Bool {
        guard didSameDayReview, !didWeekReview else { return false }
        return CalendarHelper.startOfDay(date) >= CalendarHelper.startOfDay(weekReviewDue)
    }

    var displaySource: String {
        let t = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "未填来源" : t
    }
}

// MARK: - 进度追踪（04 进度追踪）

struct ProgressItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var subject: Subject
    var module: String
    var title: String
    var planMonths: String
    var isDone: Bool = false
    var selfTestScore: String = ""
    var note: String = ""
    var completedAt: Date?

    /// 把 "2027-08~09" / "2026-11~2027-12" / "2027-05" 展开成逐月 key 列表。
    var planMonthList: [String] {
        let raw = planMonths.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty, raw != "—" else { return [] }

        let parts = raw.components(separatedBy: "~").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let first = parts.first else { return [] }
        guard parts.count > 1, let last = parts.last, last != first else {
            return Self.isMonthKey(first) ? [first] : []
        }

        // 起点必须是 "yyyy-MM"，否则无法展开
        let firstComps = first.split(separator: "-")
        guard firstComps.count == 2,
              let startYear = Int(firstComps[0]),
              let startMonth = Int(firstComps[1]) else {
            return [first, last]
        }

        // 终点可能是 "yyyy-MM" 或只有 "MM"
        var endYear: Int
        var endMonth: Int
        let lastComps = last.split(separator: "-")
        if lastComps.count == 2, let y = Int(lastComps[0]), let m = Int(lastComps[1]) {
            endYear = y
            endMonth = m
        } else if let m = Int(last) {
            endYear = startYear + (m < startMonth ? 1 : 0)
            endMonth = m
        } else {
            return [first, last]
        }

        var result: [String] = []
        var year = startYear
        var month = startMonth
        var guardCount = 0
        while (year < endYear || (year == endYear && month <= endMonth)) && guardCount < 240 {
            result.append(String(format: "%04d-%02d", year, month))
            month += 1
            if month > 12 { month = 1; year += 1 }
            guardCount += 1
        }
        return result
    }

    private static func isMonthKey(_ s: String) -> Bool {
        let comps = s.split(separator: "-")
        return comps.count == 2 && Int(comps[0]) != nil && Int(comps[1]) != nil
    }
}

// MARK: - 预算（05 两万块预算）

enum BudgetCategory: String, CaseIterable, Codable, Identifiable {
    case food = "吃饭 + 日用品"
    case transport = "交通 + 通讯"
    case study = "学习资料"
    case course = "网课"
    case fees = "报名费 + 文具"
    case interview = "复试预留"
    case emergency = "应急储备"
    case health = "健康运动"
    case other = "其他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "tram.fill"
        case .study: return "book.closed.fill"
        case .course: return "play.rectangle.fill"
        case .fees: return "doc.text.fill"
        case .interview: return "person.2.fill"
        case .emergency: return "cross.case.fill"
        case .health: return "figure.run"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// 该类别在下方的参考额度（来自表格「14 个月合计」）
    var planAmount: Int? {
        switch self {
        case .food: return 9800
        case .transport: return 1400
        case .study: return 790
        case .course: return 0
        case .fees: return 300
        case .interview: return 1500
        case .emergency: return 2000
        case .health: return nil
        case .other: return nil
        }
    }
}

struct BudgetEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var category: BudgetCategory
    var amount: Double
    var note: String = ""
}

enum BudgetPlan {
    /// 总弹药 2 万元
    static let totalFunds: Double = 20000
    /// 计划总支出
    static let plannedSpend: Double = 15800
    /// 计划可动用余额（缓冲金）
    static let plannedReserve: Double = 4200

    /// 资料清单元数据（05 表格「二、资料清单」）
    static let materialChecklist: [(subject: String, name: String, budget: Int, source: String)] = [
        ("数学", "同济《高等数学》上下册", 40, "二手 / 电子版"),
        ("数学", "武忠祥基础+强化讲义", 60, "二手或打印电子版"),
        ("数学", "《660题》+《1000题》或《880题》", 50, "二手"),
        ("数学", "数二真题 1998-2027", 40, "打印"),
        ("数学", "李永乐线代讲义", 20, "二手"),
        ("408", "王道四本（数据结构/计组/OS/计网）", 140, "二手（全新约 300）"),
        ("408", "408 真题 2010-2027", 40, "打印"),
        ("英语", "长难句 + 语法讲义", 40, "二手"),
        ("英语", "英语二真题", 40, "打印"),
        ("政治", "肖秀荣 1000 题 + 肖八 + 肖四", 120, "正版，别买盗版（勘误多）"),
        ("其他", "打印费 + 文具 + 草稿纸", 200, "学校/楼下打印店按张算")
    ]
}

// MARK: - 通用待办

enum TaskTag: String, CaseIterable, Codable, Identifiable {
    case study = "学习"
    case life = "生活"
    case health = "健康"
    case admin = "办事"
    case other = "其他"

    var id: String { rawValue }

    var subject: Subject? {
        switch self {
        case .study: return nil
        default: return nil
        }
    }
}

struct TodoItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var tag: TaskTag = .other
    var subject: Subject?
    var dueDate: Date?
    var isDone: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    var note: String = ""

    var isOverdue: Bool {
        guard !isDone, let due = dueDate else { return false }
        return CalendarHelper.startOfDay(due) < CalendarHelper.startOfDay(Date())
    }

    var isDueToday: Bool {
        guard !isDone, let due = dueDate else { return false }
        return CalendarHelper.isSameDay(due, Date())
    }
}
