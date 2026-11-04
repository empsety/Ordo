import AppKit
import SwiftUI

/// 使用单调时钟累计实际播放时间；不把隐藏、关闭和减少动态效果期间算入旋转。
@MainActor
final class AboutSketchPlayback: ObservableObject {
    static let shared = AboutSketchPlayback()
    @Published private(set) var isRunning = false
    private var elapsed: TimeInterval = 0
    private var startedAt: TimeInterval?
    private var pageVisible = false
    private var windowVisible = false
    private var reducedMotion = false

    func angle(at now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Double {
        let time = elapsed + (startedAt.map { max(0, now - $0) } ?? 0)
        return time.truncatingRemainder(dividingBy: 90) * 4
    }

    func setPageVisible(_ value: Bool, at now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        pageVisible = value
        reconcile(at: now)
    }

    func setWindowVisible(_ value: Bool, at now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        windowVisible = value
        reconcile(at: now)
    }

    func setReducedMotion(_ value: Bool, at now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        reducedMotion = value
        reconcile(at: now)
    }

    private func reconcile(at now: TimeInterval) {
        let shouldRun = pageVisible && windowVisible && !reducedMotion
        guard shouldRun != isRunning else { return }
        if shouldRun {
            startedAt = now
        } else {
            elapsed += startedAt.map { max(0, now - $0) } ?? 0
            startedAt = nil
        }
        isRunning = shouldRun
    }
}

/// 继续沿用九块构图的精确路径；表面材质与旋转时钟互相独立。
struct AboutSketchGeometry {
    struct Facet {
        let outline: Path
    }
    static let innerRadius: CGFloat = 190
    static func facetAngle(_ index: Int) -> Double { Double(index) * 45 }
    let center = Path(roundedRect: CGRect(x: -120, y: -120, width: 240, height: 240), cornerRadius: 54)
    let facets: [Facet]

    init() {
        var outline = Path()
        outline.move(to: CGPoint(x: -66, y: -300))
        outline.addQuadCurve(to: CGPoint(x: -77, y: -285), control: CGPoint(x: -82, y: -300))
        outline.addLine(to: CGPoint(x: -42, y: -200))
        outline.addQuadCurve(to: CGPoint(x: -28, y: -190), control: CGPoint(x: -38, y: -190))
        outline.addLine(to: CGPoint(x: 28, y: -190))
        outline.addQuadCurve(to: CGPoint(x: 42, y: -200), control: CGPoint(x: 38, y: -190))
        outline.addLine(to: CGPoint(x: 77, y: -285))
        outline.addQuadCurve(to: CGPoint(x: 66, y: -300), control: CGPoint(x: 82, y: -300))
        outline.closeSubpath()
        facets = (0..<8).map { _ in Facet(outline: outline) }
    }
}

struct AboutSketchDrawing: View {
    let angle: Double
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        AboutGlassArtwork(angle: angle, reduceTransparency: reduceTransparency)
    }
}

enum AboutGlassLayout {
    // 外围尺寸与公转半径采用确认后的设计参数，中心圆角保持不变。
    static let facetSize = CGSize(width: 250, height: 200)
    static let orbitRadius: CGFloat = 300
    static let centerCornerRadius: CGFloat = 54
}

/// 使用系统磨砂材质，装饰不参与交互；减少透明度时退回不透明表面。
struct AboutGlassArtwork: View {
    let angle: Double
    let reduceTransparency: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    surface(AboutGlassFacet(), prominent: false)
                        .frame(width: AboutGlassLayout.facetSize.width, height: AboutGlassLayout.facetSize.height)
                        .offset(y: -AboutGlassLayout.orbitRadius)
                        .rotationEffect(.degrees(AboutSketchGeometry.facetAngle(index)))
                }
            }
            .rotationEffect(.degrees(angle))
            surface(RoundedRectangle(cornerRadius: AboutGlassLayout.centerCornerRadius, style: .continuous), prominent: true)
                .frame(width: 240, height: 240)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func surface<S: Shape>(_ shape: S, prominent: Bool) -> some View {
        let dark = colorScheme == .dark
        return Group {
            if reduceTransparency {
                shape.fill(Color(white: dark ? (prominent ? 0.22 : 0.18) : (prominent ? 0.98 : 0.91)))
            } else {
                shape.fill(.regularMaterial)
                    .overlay {
                        shape.fill(Color.white.opacity(prominent ? (dark ? 0.05 : 0.12) : 0.025))
                    }
            }
        }
        .overlay {
            // 极轻的边缘反光提供厚度，替代素描描边；不增加动态光效。
            shape.stroke(
                LinearGradient(colors: [
                    .white.opacity(dark ? 0.22 : 0.75),
                    .white.opacity(dark ? 0.04 : 0.15),
                    .black.opacity(dark ? 0.14 : 0.06)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.7
            )
        }
        .shadow(color: .black.opacity(dark ? 0.16 : 0.07), radius: prominent ? 12 : 7, y: prominent ? 5 : 3)
    }
}

private struct AboutGlassFacet: Shape {
    private static let outline = AboutSketchGeometry().facets[0].outline
    func path(in rect: CGRect) -> Path {
        Self.outline.applying(CGAffineTransform(translationX: 78, y: 300))
            .applying(CGAffineTransform(scaleX: rect.width / 156, y: rect.height / 110))
            .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }
}

/// 直接观察所属窗口，不以 App 是否为前台代替窗口可见性。
struct AboutSketchWindowObserver: NSViewRepresentable {
    let playback: AboutSketchPlayback

    func makeNSView(context: Context) -> VisibilityView { VisibilityView(playback: playback) }
    func updateNSView(_ nsView: VisibilityView, context: Context) {}
    static func dismantleNSView(_ nsView: VisibilityView, coordinator: ()) { nsView.stop() }

    @MainActor
    final class VisibilityView: NSView {
        private let playback: AboutSketchPlayback
        private var generation = 0
        init(playback: AboutSketchPlayback) {
            self.playback = playback
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self)
            generation += 1
            if let window {
                for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                             NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification] {
                    NotificationCenter.default.addObserver(self, selector: #selector(changed(_:)), name: name, object: window)
                }
                for name in [NSApplication.didHideNotification, NSApplication.didUnhideNotification] {
                    NotificationCenter.default.addObserver(self, selector: #selector(changed(_:)), name: name, object: nil)
                }
            }
            // 避免在 SwiftUI 更新视图期间同步发布状态。
            let currentGeneration = generation
            Task { @MainActor [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                self.refresh()
            }
        }

        @objc private func changed(_ notification: Notification) {
            if notification.name == NSWindow.willCloseNotification {
                playback.setWindowVisible(false)
            } else {
                refresh()
            }
        }

        private func refresh() {
            let visible = window.map {
                $0.isVisible && !$0.isMiniaturized && $0.occlusionState.contains(.visible) && !NSApp.isHidden
            } ?? false
            playback.setWindowVisible(visible)
        }

        func stop() {
            generation += 1
            NotificationCenter.default.removeObserver(self)
            playback.setWindowVisible(false)
        }
    }
}
