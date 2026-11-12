import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var controller: AppController
    private var localization: AppLocalization { controller.localization }
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            controller.markMainWindowPresented()
            MainWindowPresentation.open(using: openWindow)
        } label: {
            Label(localization.text("打开"), systemImage: "macwindow")
                .labelStyle(.titleAndIcon)
        }
        .accessibilityLabel(localization.text("打开"))
        .accessibilityHint(localization.text("打开 Ordo 主界面"))

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label(localization.text("退出"), systemImage: "power")
                .labelStyle(.titleAndIcon)
        }
        .accessibilityLabel(localization.text("退出"))
    }
}
