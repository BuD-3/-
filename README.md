> 这是 iOS 原生 SwiftUI 工程（你需要一台 Mac + Xcode 才能编译安装）。

# 考研工作台 · KaoyanWorkbench

2028 考研（河南大学 085410 人工智能 · 专硕）脱产 14 个月的手机端工作台。
所有内容都从你的 `2028考研_河南大学人工智能_脱产14个月作战计划.xlsx` 平移过来，
不是通用模板。

## 运行要求

| 项目 | 要求 |
| --- | --- |
| Xcode | **16.0 或更新**（工程用了 Xcode 16 的「同步文件夹」格式） |
| iOS | 17.0+ |
| 设备 | iPhone（模拟器也能跑） |
| 账号 | 免费 Apple ID 即可装到自己手机上（7 天有效期，需重签） |

## 三步跑起来

1. 把整个 `kaoyan-workbench-ios` 文件夹拷到 Mac 上。
2. 双击 `KaoyanWorkbench.xcodeproj`。
3. 选中 `KaoyanWorkbench` target → **Signing & Capabilities** → Team 选你自己的 Apple ID；
   然后顶部选你的 iPhone，按 `⌘R`。

> 第一次装到真机会提示「不受信任的开发者」：iPhone 设置 → 通用 → VPN与设备管理 → 信任。

如果在 Xcode 里提示 Bundle Identifier 冲突，把
`PRODUCT_BUNDLE_IDENTIFIER` 从 `com.kaoyan.workbench` 改成 `com.你的名字.kaoyanworkbench`。

## 五个页面

### 今日
- **倒计时**：距 2027-12-18 初试天数、已坚持天数、连续打卡、累计专注时长
- **当前阶段**：自动判断你处在「地基期 / 一轮期 / 强化期 / 冲刺期 / 考前」，
  并显示本月该推进的数学、408、英语、政治内容 + 本月里程碑
- **今日课表**：复刻「03 每日课表」的 9 个时间段，逐项打勾，自动累计学习时长；
  周日自动切换成休息版课表
- 额外补记时长、今日复盘（三行）、本周柱状图

### 计划
- **逐月路线**：14 个月 × 四个科目的完整内容，当前月高亮
- **关键节点**：12 个节点（报名、确认、打印准考证、初试、复试…），显示还有几天
- **目标分数**：四科目标/冲刺/底线分数条 + 报考信息 + 研招办电话

### 错题本
复刻你表里的核心机制：**当天录入 → 当日回炉① → 第 7 天回炉② → 两次都过才算掌握**。
- 到期未回炉的题会自动进入提醒队列
- 每题记「错误类型」和「正确思路（一句话）」

### 进度
「04 进度追踪」的 40 个进度项全部预置，按科目/模块折叠，
自动算各科完成率和总体完成度；顶部单独列出「本月该推进」的项。

### 我的
- **健康运动**（你新增的模块）：运动类型/时长、散步、睡眠、饮水，
  本周运动天数与平均睡眠、健康分、历史记录、脱产期间的身体底线提醒
- **预算**：2 万元弹药看板，实时余额、月均可动用、分类支出、资料清单
- 通用待办、复盘历史、JSON 导出备份、清空数据

## 数据来源对照

| App 模块 | Excel 来源 |
| --- | --- |
| 当前阶段 / 逐月路线 | `02 14个月计划` |
| 今日课表 | `03 每日课表` |
| 进度 40 项 | `04 进度追踪` |
| 预算 / 资料清单 | `05 两万块预算` |
| 错题回炉逻辑 | `06 错题本` |
| 倒计时 / 节点 / 目标分 | `01 总览` |

## 工程结构

```
KaoyanWorkbench/
├── KaoyanWorkbenchApp.swift      App 入口 + 五栏 TabView
├── Models/
│   ├── ExamPlan.swift            计划静态数据（阶段/课表/节点/铁律）
│   ├── Models.swift              业务实体（打卡/错题/进度/预算/待办）
│   ├── ViewModels.swift          视图聚合结构体
│   └── CalendarHelper.swift      日期计算 + 格式化
├── Data/SeedData.swift           40 个进度项的初始数据
├── Stores/
│   ├── AppStore.swift            单一数据源，全部 @Published
│   └── Persistence.swift         JSON 落盘（Documents 目录）
├── DesignSystem/Theme.swift      配色、卡片、进度条、统计小卡
└── Features/
    ├── Today/     TodayView.swift
    ├── Plan/      PlanView.swift
    ├── Review/    ReviewView.swift
    ├── Progress/  ProgressView.swift
    ├── Health/    HealthView.swift
    ├── Budget/    BudgetView.swift
    └── Inbox/     ProfileView.swift
```

## 已知限制（请先看这几条）

1. **编译状态：已通过云端验证。** 在 `macos-15` + Xcode 16.4 + iOS 18.5 SDK 上，
   `xcodebuild build`（模拟器、arm64 + x86_64）编译成功，耗时约 84 秒。
   注意：**只验证了能编译**，没有在实机/模拟器上跑过 UI，交互逻辑未做运行时测试。
2. **初试日期按 2027-12-18 计算**。你的表格写的是「预计 12/18–19」，
   官方公告出来后如有变动，改 `Models/ExamPlan.swift` 里的 `PlanTimeline.examDate` 即可。
3. **数据只存本机**（Documents/WorkbenchData），随 iCloud 备份，不联网、不上传。
4. 没有做通知推送。错题回炉提醒是「打开 App 时看到到期队列」，不是手机弹窗；
   需要真弹窗的话我可以加 `UserNotifications`。

## 云端编译（不需要本地有 Mac）

工程已带 `.github/workflows/ios-build.yml`：推到 GitHub 后，
每次 push 都会在 **macOS 15 + Xcode 16** 的云端机器上跑一次 `xcodebuild build`
（模拟器目标、不签名），把编译器能看见的错误全部摊开。

会做四件事：

1. 打印 Xcode / Swift 版本
2. `plutil -lint` 校验 `project.pbxproj` 格式
3. `xcodebuild -list` 确认 scheme 能被识别
4. `xcodebuild build` 真编译，失败时把 `error:` 行和第一处上下文单独打印，
   并把完整 `build.log` 作为工件上传

看结果的地方：仓库 → **Actions** 标签页 → 点最新一次运行 →
失败时展开「提取编译错误」，或用「xcodebuild-log」工件下载完整日志。

当前状态：**已通过**（run #2，84 秒，Xcode 16.4 / iOS 18.5 SDK）。

