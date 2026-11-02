//
//  SubjectFlipCard.swift
//  KaoyanWorkbench
//
//  计划页月份卡里的「科目小卡」：正面只显示关键词，点一下翻转看本月完整安排。
//

import SwiftUI

struct SubjectFlipCard: View {
    let subject: Subject
    /// 正面关键词（自动从长文本压缩而来）
    let short: String
    /// 背面完整内容
    let full: String
    /// 本月该科目没有安排
    var isIdle: Bool = false

    @State private var flipped = false

    var body: some View {
        if isIdle {
            idleCard
        } else {
            FlipCard(isFlipped: $flipped) {
                frontCard
            } back: {
                backCard
            }
        }
    }

    private var idleCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            SubjectBadge(subject: subject, compact: true)
            Text("本月未安排")
                .font(.footnote)
                .foregroundStyle(Theme.tertiaryLabel)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .background(Theme.tertiaryCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var frontCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                SubjectBadge(subject: subject, compact: true)
                Spacer(minLength: 0)
                Image(systemName: "rotate.3d")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.tertiaryLabel)
            }

            Text(short)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.label)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .background(Theme.tertiaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var backCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                SubjectBadge(subject: subject, compact: true)
                Spacer(minLength: 0)
                Button {
                    flipped = false
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            Text(full)
                .font(.footnote)
                .foregroundStyle(Theme.label)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .background(Theme.color(for: subject).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
