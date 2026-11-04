import AppKit
import SwiftUI

/// 分页只在当前进程中保留；首次展示由权限状态决定。
enum MainWindowPage: String, CaseIterable {
    case basic, features, about

    var title: String {
        switch self {
        case .basic: "基础"
        case .features: "功能"
        case .about: "关于"
        }
    }
}

struct MainView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Group {
            switch controller.mainWindowPage {
            case .basic: BasicSettingsView(controller: controller).padding(28)
            case .features: FeatureSettingsView(controller: controller).padding(28)
            case .about: Color.clear
            }
        }
        .frame(width: MainWindowBehavior.contentSize.width, height: MainWindowBehavior.contentSize.height)
        .background {
            if controller.mainWindowPage == .about {
                AboutView()
                    .ignoresSafeArea(.container, edges: .top)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(MainWindowConfigurator(controller: controller))
        .toolbarBackground(.hidden, for: .windowToolbar)
        .modifier(MainWindowTitleVisibility())
        .onAppear {
            controller.refreshPermissions()
            controller.refreshLoginItemStatus()
        }
    }
}

/// 在 SwiftUI 层也移除默认标题，避免材质与外观更新恢复原生标题行。
private struct MainWindowTitleVisibility: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.toolbar(removing: .title)
        } else {
            content
        }
    }
}

struct BasicSettingsView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard {
                SettingsRow(title: "开机自启") {
                    Toggle("开机自启", isOn: Binding(
                        get: { controller.isLaunchAtLoginEnabled },
                        set: { controller.setLaunchAtLoginEnabled($0) }
                    ))
                    .labelsHidden()
                    .accessibilityIdentifier("ordo.launchAtLogin")
                    .help("登录当前用户后在后台启动 Ordo")
                }
                Divider()
                SettingsRow(title: "显示菜单栏图标") {
                    Toggle("显示菜单栏图标", isOn: Binding(
                        get: { controller.isMenuBarIconVisible },
                        set: { controller.setMenuBarIconVisible($0) }
                    ))
                    .labelsHidden()
                    .accessibilityIdentifier("ordo.menuBarIconVisible")
                    .help("隐藏后，可通过 Finder 或 Spotlight 再次打开 Ordo 主窗口")
                    .accessibilityHint("隐藏后，可通过 Finder 或 Spotlight 再次打开 Ordo 主窗口")
                }
                Divider()
                SettingsRow(title: "静默启动") {
                    Toggle("静默启动", isOn: Binding(
                        get: { controller.isSilentLaunchEnabled },
                        set: { controller.setSilentLaunchEnabled($0) }
                    ))
                    .labelsHidden()
                    .accessibilityIdentifier("ordo.silentLaunch")
                    .help("启动时不显示主窗口；运行中再次打开 Ordo 仍会显示主窗口")
                    .accessibilityHint("启动时不显示主窗口；运行中再次打开 Ordo 仍会显示主窗口")
                }
            }

            loginItemNotice
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .toggleStyle(.switch)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ordo.page.basic")
    }

    @ViewBuilder
    private var loginItemNotice: some View {
        if let message = controller.loginItemErrorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ordo.loginItemError")
        } else if controller.loginItemStatus == .requiresApproval {
            HStack {
                Label("开机自启等待批准", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.orange)
                Spacer()
                Button("打开登录项设置") { controller.openLoginItemSettings() }
                    .ordoGlassButton()
            }
            .accessibilityIdentifier("ordo.loginItemApproval")
        }
    }
}

struct FeatureSettingsView: View {
    @ObservedObject var controller: AppController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var keyFeedback = ModifierKeyFeedback()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard {
                SettingsRow(title: "启用窗口管理") {
                    Toggle("启用窗口管理", isOn: $controller.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityIdentifier("ordo.enabled")
                        .accessibilityHint("关闭后，Ordo 不再响应窗口手势")
                }
                Divider()
                SettingsRow(title: "排布动画") {
                    Toggle("排布动画", isOn: Binding(
                        get: { controller.isSnapAnimationEnabled },
                        set: { controller.setSnapAnimationEnabled($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityIdentifier("ordo.snapAnimation")
                    .accessibilityHint(
                        reduceMotion
                            ? "系统已开启减少动态效果，排布动画暂时停用"
                            : "启用后，松开组合键时窗口平滑移动并调整到目标大小"
                    )
                }
                if !controller.accessibilityGranted {
                    Divider()
                    AccessibilityPermissionSection(controller: controller)
                }
            }

            SettingsCard {
                GestureSettingsView(controller: controller, pressedModifiers: keyFeedback.pressedModifiers)
            }
            Spacer(minLength: 0)

            Button("重置快捷键", role: .destructive) {
                controller.resetGestureSettingsToDefaults()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 14)
            .accessibilityIdentifier("ordo.resetGestureSettings")
            .accessibilityHint("仅恢复三组默认快捷键")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ordo.page.features")
        .modifier(ModifierKeyFeedbackObserver(feedback: $keyFeedback))
    }

}

struct AboutView: View {
    @ObservedObject var playback: AboutSketchPlayback = .shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !playback.isRunning)) { _ in
                AboutSketchPage(angle: playback.angle(), canvasSize: geometry.size)
            }
        }
        .background(AboutSketchWindowObserver(playback: playback))
        .onAppear {
            playback.setReducedMotion(reduceMotion)
            playback.setPageVisible(true)
        }
        .onDisappear { playback.setPageVisible(false) }
        .onChange(of: reduceMotion) { _, value in playback.setReducedMotion(value) }
    }
}

/// 静态构图与播放生命周期分离，便于固定角度的布局和主题验收。
struct AboutSketchPage: View {
    let angle: Double
    var canvasSize = MainWindowBehavior.contentSize
    @Environment(\.colorScheme) private var colorScheme
    private let bundle = Bundle.main
    private let projectURL = URL(string: "https://github.com/vo1dGhost/Ordo")!

    var body: some View {
        ZStack {
            AboutSketchDrawing(angle: angle)
            VStack(spacing: 14) {
                Text("Ordo")
                    .font(.system(size: 26, weight: .semibold))
                Text(versionText)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("ordo.about.version")

                Link(destination: projectURL) {
                    Text("GitHub 项目")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                }
                    .ordoGlassButton()
                    .padding(.top, 8)
                    .help(projectURL.absoluteString)
                    .accessibilityIdentifier("ordo.about.project")

                Text("© 2026 voidGhost · MIT License")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 212, height: 212)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ordo.page.about")
    }

    private var versionText: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "版本 \(version)（\(build)）"
    }
}
