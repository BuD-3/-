//
//  WordReviewSheet.swift
//  KaoyanWorkbench
//
//  单词回顾：今天要复习的旧词 + 导入新词。
//

import SwiftUI

struct WordReviewSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingImport = false
    @State private var importText = ""
    @State private var justReviewed: Set<UUID> = []
    @State private var importedMessage: String?

    private var due: [WordEntry] {
        store.dueWords().filter { !justReviewed.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard
                    if due.isEmpty {
                        emptyCard
                    } else {
                        ForEach(due.prefix(80)) { word in
                            wordCard(word)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("单词回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        importText = ""
                        showingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("导入新词")
                }
            }
            .sheet(isPresented: $showingImport) {
                importSheet
            }
        }
    }

    private var summaryCard: some View {
        Card {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今天要回顾")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                    Text("\(due.count) 个词")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("词库 \(store.words.count) 个")
                    Text("已掌握 \(store.masteredWordCount) 个")
                }
                .font(.footnote)
                .foregroundStyle(Theme.tertiaryLabel)
            }
        }
    }

    private var emptyCard: some View {
        Card {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.42))
                Text("今天的单词回顾清空了")
                    .font(.subheadline.weight(.medium))
                Text("明天会复习今天新录入的词")
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func wordCard(_ word: WordEntry) -> some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.text)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                    if !word.meaning.isEmpty {
                        Text(word.meaning)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    Text("回顾 \(word.reviewCount) 次 · 连对 \(word.streak)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tertiaryLabel)

                    Spacer()

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.reviewWord(word, remembered: false)
                            justReviewed.insert(word.id)
                        }
                    } label: {
                        Text("忘了")
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.reviewWord(word, remembered: true)
                            justReviewed.insert(word.id)
                        }
                    } label: {
                        Text("记住了")
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.18, green: 0.68, blue: 0.42).opacity(0.14))
                            .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.42))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var importSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("一行一个词，格式：`word | 释义`（释义可省略）")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)

                TextEditor(text: $importText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Theme.tertiaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 240)
                    .overlay(alignment: .topLeading) {
                        if importText.isEmpty {
                            Text("abandon | 放弃\nresilient | 有韧性的")
                                .font(.subheadline)
                                .foregroundStyle(Theme.tertiaryLabel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }

                if let message = importedMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.accent)
                }

                Spacer()
            }
            .padding(16)
            .background(Theme.background)
            .navigationTitle("导入新词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showingImport = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        let count = store.importWords(importText)
                        importedMessage = "已导入 \(count) 个新词"
                        showingImport = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
