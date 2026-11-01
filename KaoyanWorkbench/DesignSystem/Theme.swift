//
//  Theme.swift
//  KaoyanWorkbench
//
//  浅色清爽 iOS 原生风：系统色 + 圆角卡片 + SF Symbols。
//

import SwiftUI

// MARK: - 色彩

enum Theme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiaryCard = Color(uiColor: .tertiarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)

    static let accent = Color(red: 0.16, green: 0.42, blue: 0.94)

    static func color(for subject: Subject) -> Color {
        switch subject {
        case .math: return Color(red: 0.16, green: 0.42, blue: 0.94)   // 蓝
        case .cs408: return Color(red: 0.55, green: 0.32, blue: 0.86)  // 紫
        case .english: return Color(red: 0.05, green: 0.62, blue: 0.53) // 青绿
        case .politics: return Color(red: 0.86, green: 0.36, blue: 0.28) // 朱红
        }
    }

    /// 课表区块的颜色。
    /// 刻意命名为 `color(of:)` 而不是与 `color(for:)` 重载：
    /// 两者都有 `.math/.cs408/.english` 这些 case，同名的 `color(for:)` 会让
    /// `Theme.color(for: .math)` 产生 ambiguous use 编译错误。
    static func color(of kind: ScheduleBlockKind) -> Color {
        switch kind {
        case .math: return color(for: Subject.math)
        case .cs408: return color(for: Subject.cs408)
        case .english: return color(for: Subject.english)
        case .review: return Color(red: 0.85, green: 0.55, blue: 0.12)
        case .rest: return Color(uiColor: .systemGray)
        case .flexible: return Color(red: 0.42, green: 0.60, blue: 0.30)
        }
    }

    static func color(for stage: PlanStage) -> Color {
        switch stage {
        case .foundation: return Color(red: 0.20, green: 0.56, blue: 0.86)
        case .roundOne: return Color(red: 0.16, green: 0.42, blue: 0.94)
        case .strengthen: return Color(red: 0.55, green: 0.32, blue: 0.86)
        case .sprint: return Color(red: 0.85, green: 0.55, blue: 0.12)
        case .examWeek: return Color(red: 0.86, green: 0.36, blue: 0.28)
        }
    }

    static func color(for status: BudgetStatus) -> Color {
        switch status {
        case .healthy: return Color(red: 0.18, green: 0.68, blue: 0.42)
        case .warning: return Color(red: 0.90, green: 0.60, blue: 0.10)
        case .over: return Color(red: 0.85, green: 0.28, blue: 0.24)
        }
    }

    static func color(for slice: StudySlice) -> Color {
        switch slice {
        case .math: return color(for: Subject.math)
        case .cs408: return color(for: Subject.cs408)
        case .english: return color(for: Subject.english)
        case .review: return Color(red: 0.85, green: 0.55, blue: 0.12)
        case .extra: return Color(red: 0.45, green: 0.52, blue: 0.62)
        }
    }

    static let spacing: CGFloat = 16
    static let cardRadius: CGFloat = 16
}

// MARK: - 卡片容器

struct Card<Content: View>: View {
    var padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

// MARK: - 区块标题

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }
}

// MARK: - 进度条

struct ProgressBar: View {
    let value: Double
    var tint: Color = Theme.accent
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.14))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// MARK: - 环形进度

struct RingProgress: View {
    let value: Double
    var tint: Color = Theme.accent
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, value)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: value)
        }
    }
}

// MARK: - 统计小卡

struct StatTile: View {
    let title: String
    let value: String
    var caption: String?
    var tint: Color = Theme.accent
    var symbol: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.footnote)
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
            }
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.label)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 科目徽章

struct SubjectBadge: View {
    let subject: Subject
    var compact: Bool = false

    var body: some View {
        Text(compact ? subject.shortName : subject.rawValue)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.color(for: subject).opacity(0.13))
            .foregroundStyle(Theme.color(for: subject))
            .clipShape(Capsule())
    }
}

// MARK: - 空状态

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34))
                .foregroundStyle(Theme.tertiaryLabel)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }
}

// MARK: - 通用扩展

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}
