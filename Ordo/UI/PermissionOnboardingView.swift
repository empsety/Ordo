import SwiftUI

/// 首次使用与后续权限管理共用功能页，不自动触发系统授权提示。
struct AccessibilityPermissionSection: View {
    @ObservedObject var controller: AppController
    private var localization: AppLocalization { controller.localization }

    var body: some View {
        // 固定两行高度，授权前后卡片高度不跳变。
        SettingsRow(
            title: localization.text("辅助功能"),
            subtitle: controller.accessibilityGranted ? nil : localization.text("允许 Ordo 移动和调整窗口。"),
            minHeight: 44
        ) {
            Label(
                controller.accessibilityGranted ? localization.text("已授权") : localization.text("未授权"),
                systemImage: controller.accessibilityGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
            )
            .font(.callout)
            .foregroundStyle(controller.accessibilityGranted ? .green : .orange)
            .accessibilityLabel(controller.accessibilityGranted ? localization.text("辅助功能权限已授权") : localization.text("辅助功能权限未授权"))
            .accessibilityIdentifier("ordo.permissionStatus")

            if !controller.accessibilityGranted {
                GlassButtonGroup {
                    Button(localization.text("重新检查")) { controller.refreshPermissions() }
                        .ordoGlassButton()
                        .accessibilityLabel(localization.text("重新检查辅助功能权限"))
                        .accessibilityIdentifier("ordo.checkPermission")
                    Button(localization.text("授权")) { controller.requestAccessibility() }
                        .ordoGlassButton(prominent: true)
                        .accessibilityLabel(localization.text("授权辅助功能"))
                        .accessibilityHint(localization.text("显示 macOS 辅助功能授权提示"))
                        .accessibilityIdentifier("ordo.requestPermission")
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
