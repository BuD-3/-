//
//  ProfileView.swift
//  KaoyanWorkbench
//
//  我的：待办 / 健康 / 预算 / 复盘历史 / 数据管理
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingTodoEditor = false
    @State private var showingClearConfirm = false
    @State private var showingExport = false
    @State private var exportedText = ""
    @State private var permission: ReminderPermission = .unknown
    @State private var pendingCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    headerCard
                    moduleGrid
                    reminderCard
                    todoCard
                    reflectionHistoryCard
                    dataCard
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await refreshReminderState()
            }
            .sheet(isPresented: $showingTodoEditor) {
                TodoEditorView { todo in
                    store.addTodo(todo)
                }
            }
            .alert("清空所有数据？", isPresented: $showingClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    store.clearAllData()
                }
            } message: {
                Text("打卡、错题、预算、待办都会被清空，进度表恢复初始状态。此操作不可撤销。")
            }
            .sheet(isPresented: $showingExport) {
                ExportSheet(text: exportedText)
            }
        }
    }

    private func refreshReminderState() async {
        permission = await store.reminderPermission()
        pendingCount = await store.pendingReminderCount()
    }

    // MARK: - 头部

    private var headerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("2028 考研 · 河南大学")
                            .font(.subheadline.weight(.semibold))
                        Text("085410 人工智能（专硕）· 脱产 14 个月")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    StatTile(title: "累计专注",
                             value: ClockFormatter.hoursText(store.totalStudyHours),
                             caption: "自 2026-11-01",
                             tint: Theme.accent,
                             symbol: "clock.fill")
                    StatTile(title: "连续打卡",
                             value: "\(store.streakDays) 天",
                             caption: "别断",
                             tint: .orange,
                             symbol: "flame.fill")
                    StatTile(title: "错题未掌握",
                             value: "\(store.unmasteredMistakes.count) 题",
                             caption: "含待回炉",
                             tint: .red,
                             symbol: "book.closed.fill")
                }
            }
        }
    }

    // MARK: - 模块入口

    private var moduleGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    HealthView()
                } label: {
                    moduleTile(
                        title: "健康运动",
                        subtitle: "\(store.weekExerciseDays) 天 / 本周",
                        symbol: "figure.run",
                        tint: Color(red: 0.30, green: 0.65, blue: 0.42)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BudgetView()
                } label: {
                    moduleTile(
                        title: "预算",
                        subtitle: ClockFormatter.currency(store.remainingFunds) + " 余",
                        symbol: "yensign.circle.fill",
                        tint: Color(red: 0.90, green: 0.60, blue: 0.10)
                    )
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                LibraryView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.55, green: 0.32, blue: 0.86).opacity(0.13))
                            .frame(width: 36, height: 36)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(red: 0.55, green: 0.32, blue: 0.86))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("资料库")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.label)
                        Text(librarySubtitle)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
                .padding(14)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    /// 资料库入口的副标题：没有附件文件时不显示「0 KB」
    private var librarySubtitle: String {
        let count = "\(store.totalMaterialCount) 份"
        if store.totalMaterialBytes > 0 {
            return count + " · \(store.totalMaterialSize) · PDF / 图片 / 文字"
        }
        return count + " · PDF / 图片 / 文字"
    }

    private func moduleTile(title: String, subtitle: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.label)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    // MARK: - 提醒

    private var reminderCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                reminderHeader
                reminderToggle
                if store.settings.remindersEnabled {
                    reminderTimePicker
                }
                reminderFooter
            }
        }
    }

    private var reminderHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("错题回炉提醒")
                    .font(.headline)
                Text("到第 7 天时通知你回炉，不用主动想起来")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)
            }
            Spacer()
        }
    }

    private var reminderToggle: some View {
        Toggle(
            "开启提醒",
            isOn: Binding(
                get: { store.settings.remindersEnabled },
                set: { store.setRemindersEnabled($0) }
            )
        )
        .font(.subheadline)
    }

    private var reminderTimePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("提醒时间")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryLabel)
                Spacer()
                Text(String(format: "%02d:00", store.settings.reminderHour))
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.secondaryLabel)
            }
            Slider(
                value: Binding(
                    get: { Double(store.settings.reminderHour) },
                    set: { store.setReminderHour(Int($0.rounded())) }
                ),
                in: 6...22,
                step: 1
            )
            .tint(.orange)

            if permission == .denied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("通知权限被拒绝了，去系统设置里打开")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                    Spacer()
                    Button("去设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption2.weight(.semibold))
                }
            } else if permission == .authorized {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.42))
                    Text("已排程 \(pendingCount) 条提醒")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryLabel)
                    Spacer()
                }
            }
        }
    }

    private var reminderFooter: some View {
        Text("完成回炉①后，系统会在第 7 天按上面的时间提醒你。完成回炉②或删除错题，提醒自动取消。")
            .font(.caption2)
            .foregroundStyle(Theme.tertiaryLabel)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 待办

    private var todoCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("待办")
                        .font(.headline)
                    Spacer()
                    Button {
                        showingTodoEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("新增待办")
                }

                let open = store.openTodos
                if open.isEmpty {
                    Text("没有待办。杂事也记在这里，别占脑子。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(open.prefix(8)) { todo in
                        Button {
                            withAnimation { store.toggleTodo(todo) }
                        } label: {
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "circle")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.tertiaryLabel)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(todo.title)
                                        .font(.footnote)
                                        .foregroundStyle(Theme.label)
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 5) {
                                        Text(todo.tag.rawValue)
                                            .font(.system(size: 9, weight: .medium))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Theme.tertiaryCard)
                                            .foregroundStyle(Theme.secondaryLabel)
                                            .clipShape(Capsule())
                                        if let due = todo.dueDate {
                                            Text(ClockFormatter.monthDay(due))
                                                .font(.caption2)
                                                .foregroundStyle(todo.isOverdue ? .red : Theme.tertiaryLabel)
                                        }
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteTodo(todo)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }

                    let doneCount = store.todos.filter { $0.isDone }.count
                    if doneCount > 0 {
                        Divider()
                        Text("已完成 \(doneCount) 项")
                            .font(.caption2)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }
            }
        }
    }

    // MARK: - 复盘历史

    private var reflectionHistoryCard: some View {
        let history = store.checkIns.values
            .filter { !$0.reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .compactMap { record -> ReflectionLog? in
                guard let date = DateKey.date(from: record.dateKey) else { return nil }
                return ReflectionLog(date: date, text: record.reflection)
            }
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }

        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("复盘历史")
                    .font(.headline)

                if history.isEmpty {
                    Text("还没有复盘记录。点主页右上角的笔，写三行就好。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(history) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ClockFormatter.monthDay(item.date))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryLabel)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: - 数据

    private var dataCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("数据")
                    .font(.headline)

                Button {
                    if let data = Persistence.shared.exportAll(),
                       let text = String(data: data, encoding: .utf8) {
                        exportedText = text
                        showingExport = true
                    } else {
                        exportedText = "暂无数据可导出。"
                        showingExport = true
                    }
                } label: {
                    HStack {
                        Label("导出备份（JSON）", systemImage: "square.and.arrow.up")
                            .font(.footnote)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    showingClearConfirm = true
                } label: {
                    HStack {
                        Label("清空所有数据", systemImage: "trash")
                            .font(.footnote)
                            .foregroundStyle(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                    Text("数据只存在本机 Documents 目录，随 iCloud 备份。")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
            }
        }
    }

    // MARK: - 关于

    private var aboutCard: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("关于这套计划")
                    .font(.caption.weight(.semibold))
                Text("数据来源：2028考研_河南大学人工智能_脱产14个月作战计划.xlsx。倒计时与阶段按 2026-11-01 启动、2027-12-18 初试计算，若官方公告有变，请以后者为准。")
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 待办编辑

struct TodoEditorView: View {
    var onSave: (TodoItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var tag: TaskTag = .life
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("要做什么", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    Picker("标签", selection: $tag) {
                        ForEach(TaskTag.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    Toggle("设置截止日", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("截止", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新增待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(TodoItem(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            tag: tag,
                            dueDate: hasDueDate ? dueDate : nil
                        ))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - 导出

struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.background)
            .navigationTitle("备份内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    ShareLink(item: text) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
