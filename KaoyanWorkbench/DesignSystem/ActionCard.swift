//
//  ActionCard.swift
//  KaoyanWorkbench
//
//  首页行动卡：一张卡只讲一件事 —— 现在要做什么、做了多少、点一下去哪。
//  参考同类产品首页的做法：顶部不放仪表盘，只放 2 个「下一步动作」。
//

import SwiftUI

struct ActionCard: View {
    let title: String
    let value: String
    /// 底部一行提示，通常是下一步动作或状态
    let hint: String
    var tint: Color = Theme.accent
    var symbol: String = "circle"
    var isDone: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryLabel)
                    Spacer(minLength: 0)
                }

                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 3) {
                    Text(hint)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isDone ? Theme.tertiaryLabel : tint)
                        .lineLimit(1)
                    if !isDone {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
