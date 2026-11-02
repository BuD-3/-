//
//  ScoreEditorSheet.swift
//  KaoyanWorkbench
//
//  给某个进度项录一个自测分数（决策 14 / 17）。
//

import SwiftUI

struct ScoreEditorSheet: View {
    let item: ProgressItem
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var focused: Bool

    init(item: ProgressItem, onSave: @escaping (String) -> Void) {
        self.item = item
        self.onSave = onSave
        _text = State(initialValue: item.selfTestScore)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text("\(item.subject.rawValue) · 计划 \(item.planMonths)")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                HStack(spacing: 12) {
                    TextField("分数", text: $text)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 140)
                        .padding(.vertical, 10)
                        .background(Theme.tertiaryCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("/ 100")
                        .font(.subheadline)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Text("不填就表示还没测过。分数只做记录，不参与任何打分。")
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)

                if !item.selfTestScore.isEmpty {
                    Button(role: .destructive) {
                        onSave("")
                        dismiss()
                    } label: {
                        Text("清除分数")
                            .font(.footnote)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Theme.background)
            .navigationTitle("记录分数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let cleaned = text.trimmingCharacters(in: .whitespaces)
                        let value = Int(cleaned)
                        onSave(value == nil ? "" : String(max(0, min(100, value!))))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }
}
