//
//  BudgetView.swift
//  KaoyanWorkbench
//
//  预算看板：2 万元撑 14 个月，实时显示弹药余量。
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                fundsCard
                categoryCard
                recentCard
                materialCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .navigationTitle("预算")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("记一笔支出")
            }
        }
        .sheet(isPresented: $showingEditor) {
            BudgetEditorView { entry in
                store.addBudgetEntry(entry)
            }
        }
    }

    // MARK: - 弹药

    private var fundsCard: some View {
        let status = store.budgetStatus
        let tint = Theme.color(for: status)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("剩余弹药")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                        Text(ClockFormatter.currency(store.remainingFunds))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(store.remainingFunds < 0 ? .red : Theme.label)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("总弹药 \(ClockFormatter.currency(BudgetPlan.totalFunds))")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: status.symbolName)
                            .font(.footnote)
                        Text(status.title)
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.13))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
                }

                VStack(spacing: 8) {
                    ProgressBar(value: store.spentRatio, tint: tint, height: 10)
                    HStack {
                        Text("已花 \(ClockFormatter.currency(store.totalSpent))")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                        Spacer()
                        Text("计划线 \(ClockFormatter.currency(BudgetPlan.plannedSpend))")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }

                Divider()

                HStack(spacing: 8) {
                    StatTile(title: "本月已花",
                             value: ClockFormatter.currency(store.spentThisMonth()),
                             caption: "实时",
                             tint: .orange,
                             symbol: "calendar")
                    StatTile(title: "月均可动用",
                             value: ClockFormatter.currency(store.monthlyAllowance),
                             caption: "剩余 \(max(0, 14 - store.elapsedMonths + 1)) 个月",
                             tint: Theme.accent,
                             symbol: "chart.pie.fill")
                    StatTile(title: "已备考",
                             value: "第 \(store.elapsedMonths) 月",
                             caption: "共 14 月",
                             tint: .purple,
                             symbol: "hourglass")
                }
            }
        }
    }

    // MARK: - 分类

    private var categoryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("分类支出")
                    .font(.headline)

                ForEach(BudgetCategory.allCases) { category in
                    let spent = store.spent(for: category)
                    if spent > 0 || category.planAmount != nil {
                        HStack(spacing: 8) {
                            Image(systemName: category.symbolName)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.secondaryLabel)
                                .frame(width: 18)
                            Text(category.rawValue)
                                .font(.footnote)
                                .foregroundStyle(Theme.label)
                            Spacer()
                            if let plan = category.planAmount, plan > 0 {
                                Text(ClockFormatter.currency(spent) + " / " + ClockFormatter.currency(Double(plan)))
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(spent > Double(plan) ? .red : Theme.tertiaryLabel)
                            } else {
                                Text(ClockFormatter.currency(spent))
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Theme.secondaryLabel)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - 最近流水

    private var recentCard: some View {
        let recent = store.budgetEntries.sorted { $0.date > $1.date }.prefix(8)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("最近流水")
                        .font(.headline)
                    Spacer()
                    if !store.budgetEntries.isEmpty {
                        Text("共 \(store.budgetEntries.count) 笔")
                            .font(.footnote)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }

                if recent.isEmpty {
                    Text("还没有记支出。记一笔试试。")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(Array(recent)) { entry in
                        HStack(spacing: 8) {
                            Image(systemName: entry.category.symbolName)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.secondaryLabel)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.note.isEmpty ? entry.category.rawValue : entry.note)
                                    .font(.footnote)
                                    .lineLimit(1)
                                Text(ClockFormatter.monthDay(entry.date))
                                    .font(.footnote)
                                    .foregroundStyle(Theme.tertiaryLabel)
                            }
                            Spacer()
                            Text("- " + ClockFormatter.currency(entry.amount))
                                .font(.footnote.weight(.medium).monospacedDigit())
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteBudgetEntry(entry)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 资料清单

    private var materialCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("资料清单（省钱版）")
                        .font(.headline)
                    Spacer()
                    Text("预算 \(ClockFormatter.currency(790))")
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Text("B 站免费课足够，不报任何付费班。二手能省一半。")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)

                ForEach(BudgetPlan.materialChecklist.indices, id: \.self) { index in
                    let item = BudgetPlan.materialChecklist[index]
                    HStack(spacing: 8) {
                        Text(item.subject)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.tertiaryCard)
                            .foregroundStyle(Theme.secondaryLabel)
                            .clipShape(Capsule())
                            .frame(width: 38)
                        Text(item.name)
                            .font(.footnote)
                            .foregroundStyle(Theme.label)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.budget) 元")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                    .padding(.vertical, 1)
                }

                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text("2 万元是全部弹药。开始前就和家人明确「吃住归家里、2 万只用于学习和应急」。")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - 记一笔

struct BudgetEditorView: View {
    var onSave: (BudgetEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var category: BudgetCategory = .food
    @State private var note = ""
    @State private var date = Date()

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("¥")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.secondaryLabel)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                    }
                } header: {
                    Text("金额")
                }

                Section {
                    Picker("分类", selection: $category) {
                        ForEach(BudgetCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.symbolName).tag(c)
                        }
                    }
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section {
                    TextField("备注（如 打印真题 40 元）", text: $note)
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(BudgetEntry(date: date,
                                           category: category,
                                           amount: amount,
                                           note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount <= 0)
                }
            }
        }
    }
}
