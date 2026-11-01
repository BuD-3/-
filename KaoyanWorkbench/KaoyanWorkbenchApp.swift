//
//  KaoyanWorkbenchApp.swift
//  KaoyanWorkbench
//
//  App 入口 + 五栏主界面：今日 / 计划 / 错题 / 进度 / 我的
//

import SwiftUI

@main
struct KaoyanWorkbenchApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.accent)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: Int = RootView.initialTab

    /// 允许用启动参数指定初始页签，供自动化截图使用：
    ///   xcrun simctl launch booted com.kaoyan.workbench --tab 2
    /// 只认 0...4，其余情况回落到首页。
    static var initialTab: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "--tab"),
              idx + 1 < args.count,
              let value = Int(args[idx + 1]),
              (0...4).contains(value) else {
            return 0
        }
        return value
    }

    /// 自动化截图专用：直接把资料库当作根视图打开
    static var isLibraryPreview: Bool {
        ProcessInfo.processInfo.arguments.contains("--library-preview")
    }

    /// 自动化截图专用：直接打开学习周报
    static var isReportPreview: Bool {
        ProcessInfo.processInfo.arguments.contains("--report-preview")
    }

    var body: some View {
        Group {
            if RootView.isLibraryPreview {
                NavigationStack {
                    LibraryView()
                }
            } else if RootView.isReportPreview {
                NavigationStack {
                    WeeklyReportView()
                }
            } else {
                TabView(selection: $selection) {
                    TodayView()
                        .tabItem { Label("今日", systemImage: "sun.max.fill") }
                        .tag(0)

                    PlanView()
                        .tabItem { Label("计划", systemImage: "calendar") }
                        .tag(1)

                    ReviewView()
                        .tabItem { Label("错题", systemImage: "arrow.triangle.2.circlepath") }
                        .badge(store.dueWeekReviews.count)
                        .tag(2)

                    ProgressView()
                        .tabItem { Label("进度", systemImage: "chart.bar.fill") }
                        .tag(3)

                    ProfileView()
                        .tabItem { Label("我的", systemImage: "person.crop.circle") }
                        .tag(4)
                }
            }
        }
    }
}
