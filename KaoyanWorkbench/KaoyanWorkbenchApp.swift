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
    @State private var selection: Int = 0

    var body: some View {
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
