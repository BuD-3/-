//
//  FlipCard.swift
//  KaoyanWorkbench
//
//  可翻转卡片：正面概览，点击翻到背面看详情。
//
//  实现思路：两段式翻转 —— 先转到 90°（侧面看不见），
//  这一刻换内容，再从 -90° 转回 0°。
//  这样始终只渲染一面，卡片高度能跟着内容自然变化，
//  不会出现「两面都在布局里、翻过去留一大块空白」的问题。
//

import SwiftUI

struct FlipCard<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool

    private let front: () -> Front
    private let back: () -> Back

    @State private var rotation: Double = 0
    @State private var showingBack: Bool = false

    /// 半圈翻转耗时
    private let halfTurn: Double = 0.16

    init(
        isFlipped: Binding<Bool>,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self._isFlipped = isFlipped
        self.front = front
        self.back = back
        self._showingBack = State(initialValue: isFlipped.wrappedValue)
    }

    var body: some View {
        Group {
            if showingBack {
                back()
            } else {
                front()
            }
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.55
        )
        .animation(.easeInOut(duration: 0.2), value: showingBack)
        .contentShape(Rectangle())
        // 只在正面响应「点一下翻面」：背面通常有自己的交互（课表打勾），
        // 背面由调用方放「收起」按钮翻回来。
        .onTapGesture {
            if !showingBack { toggle() }
        }
        .onChange(of: isFlipped) { _, newValue in
            // 外部状态变了（比如其他地方重置），同步过来
            if newValue != showingBack {
                toggle()
            }
        }
    }

    private func toggle() {
        let target = !showingBack
        withAnimation(.easeIn(duration: halfTurn)) {
            rotation = target ? -90 : 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + halfTurn) {
            showingBack = target
            rotation = target ? 90 : -90
            withAnimation(.easeOut(duration: halfTurn)) {
                rotation = 0
            }
        }
        isFlipped = target
    }
}
