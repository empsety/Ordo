import AppKit
import SwiftUI
import XCTest
@testable import Ordo

@MainActor
final class AboutSketchTests: XCTestCase {
    func testFacetsUseSelectedSizeAndOrbitWithoutChangingCenter() {
        XCTAssertEqual(AboutGlassLayout.facetSize.width, 250)
        XCTAssertEqual(AboutGlassLayout.facetSize.height, 200)
        XCTAssertEqual(AboutGlassLayout.orbitRadius, 300)
        XCTAssertEqual(AboutGlassLayout.centerCornerRadius, 54)
    }

    func testOrbitPeriodAndPauseResumeExcludeHiddenTime() {
        let clock = AboutSketchPlayback()
        clock.setPageVisible(true, at: 0)
        clock.setWindowVisible(true, at: 0)
        XCTAssertEqual(clock.angle(at: 22.5), 90, accuracy: 0.001)
        clock.setWindowVisible(false, at: 22.5)
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.angle(at: 100), 90, accuracy: 0.001)
        clock.setWindowVisible(true, at: 100)
        XCTAssertEqual(clock.angle(at: 122.5), 180, accuracy: 0.001)
        clock.setPageVisible(false, at: 122.5)
        clock.setPageVisible(true, at: 200)
        XCTAssertEqual(clock.angle(at: 245), 0, accuracy: 0.001)
    }

    func testReducedMotionAndRepeatedVisibilityUpdatesPreservePhase() {
        let clock = AboutSketchPlayback()
        clock.setPageVisible(true, at: 0)
        clock.setWindowVisible(true, at: 0)
        clock.setWindowVisible(true, at: 10)
        clock.setReducedMotion(true, at: 15)
        XCTAssertEqual(clock.angle(at: 80), 60, accuracy: 0.001)
        XCTAssertFalse(clock.isRunning)
        clock.setReducedMotion(false, at: 80)
        XCTAssertEqual(clock.angle(at: 95), 120, accuracy: 0.001)
        // 外观不属于时钟输入；视图重绘和同值门控均不得重置进度。
        clock.setPageVisible(true, at: 95)
        XCTAssertEqual(clock.angle(at: 110), 180, accuracy: 0.001)
    }

    func testGeometryKeepsAllEightFacetsOutsideInformationBlock() {
        let geometry = AboutSketchGeometry()
        XCTAssertEqual(geometry.facets.count, 8)
        XCTAssertEqual(geometry.center.boundingRect, CGRect(x: -120, y: -120, width: 240, height: 240))
        for index in 0..<8 {
            XCTAssertEqual(AboutSketchGeometry.facetAngle(index), Double(index) * 45)
        }
        // 中心包围圆比外块内缘更小，任何旋转角度都不会遮挡中心。
        XCTAssertGreaterThan(AboutSketchGeometry.innerRadius, hypot(120, 120) + 15)
        XCTAssertEqual(geometry.facets.map(\.outline), AboutSketchGeometry().facets.map(\.outline))
    }

    func testAboutPageUsesFullContentArea() {
        let view = NSHostingView(rootView: AboutView(playback: AboutSketchPlayback()).frame(width: 500, height: 448))
        XCTAssertEqual(view.fittingSize.width, 500, accuracy: 0.5)
        XCTAssertEqual(view.fittingSize.height, 448, accuracy: 0.5)
    }

    func testReducedTransparencyUsesOpaqueSurfacesAndKeepsGapsClear() throws {
        for scheme in [ColorScheme.light, .dark] {
            let renderer = ImageRenderer(content: AboutGlassArtwork(angle: 0, reduceTransparency: true)
                .frame(width: 500, height: 500).environment(\.colorScheme, scheme))
            let image = try XCTUnwrap(renderer.cgImage)
            let bitmap = NSBitmapImageRep(cgImage: image)
            let center = try XCTUnwrap(bitmap.colorAt(x: 280, y: 264))
            let gap = try XCTUnwrap(bitmap.colorAt(x: 280, y: 104))
            XCTAssertEqual(center.alphaComponent, 1, accuracy: 0.01)
            XCTAssertLessThan(gap.alphaComponent, 0.05)
        }
    }

    func testWindowVisibilityNotificationsAndCloseReopenGatePlayback() async throws {
        let clock = AboutSketchPlayback()
        let window = SketchVisibilityWindow(contentRect: CGRect(x: 200, y: 200, width: 500, height: 448),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AboutView(playback: clock))
        defer { window.close() }
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertTrue(clock.isRunning)
        window.simulatedOcclusion = []
        NotificationCenter.default.post(name: NSWindow.didChangeOcclusionStateNotification, object: window)
        XCTAssertFalse(clock.isRunning)
        window.simulatedOcclusion = [.visible]
        NotificationCenter.default.post(name: NSWindow.didChangeOcclusionStateNotification, object: window)
        XCTAssertTrue(clock.isRunning)
        window.simulatedMiniaturized = true
        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)
        XCTAssertFalse(clock.isRunning)
        window.simulatedMiniaturized = false
        NotificationCenter.default.post(name: NSWindow.didDeminiaturizeNotification, object: window)
        XCTAssertTrue(clock.isRunning)
        window.orderOut(nil)
        NotificationCenter.default.post(name: NSWindow.didChangeOcclusionStateNotification, object: window)
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertFalse(clock.isRunning)
        let hiddenAngle = clock.angle()
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(clock.angle(), hiddenAngle)
        window.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: NSWindow.didChangeOcclusionStateNotification, object: window)
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertTrue(clock.isRunning)
        XCTAssertGreaterThan(clock.angle(), hiddenAngle)
        window.close()
        XCTAssertFalse(clock.isRunning)
        window.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: NSWindow.didChangeOcclusionStateNotification, object: window)
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertTrue(clock.isRunning)
        window.appearance = NSAppearance(named: .darkAqua)
        let angleBeforeTheme = clock.angle()
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertGreaterThanOrEqual(clock.angle(), angleBeforeTheme)
    }

    func testSketchSnapshotsAcrossThemesAndAngles() async throws {
        let output = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("build/AboutSketch-20261104/Previews")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            for angle in [0.0, 22.5, 45.0] {
                let window = NSWindow(contentRect: CGRect(x: 200, y: 200, width: 500, height: 448),
                                      styleMask: [.titled, .closable], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = NSAppearance(named: appearance)
                let host = NSHostingView(rootView: AboutSketchPage(angle: angle)
                    .background(Color(nsColor: .windowBackgroundColor)))
                window.contentView = host
                window.makeKeyAndOrderFront(nil)
                try await Task.sleep(for: .milliseconds(100))
                host.layoutSubtreeIfNeeded()
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                try png.write(to: output.appendingPathComponent("\(name)-\(angle).png"))
                let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                attachment.name = "关于－\(name)－\(angle)"
                attachment.lifetime = .keepAlways
                add(attachment)
                window.close()
            }
        }
    }
}

/// 桌面可能被其他窗口遮挡；用替身确定窗口服务器状态，只验证观察器的通知接线。
@MainActor
private final class SketchVisibilityWindow: NSWindow {
    var simulatedOcclusion: NSWindow.OcclusionState = [.visible]
    var simulatedMiniaturized = false
    override var occlusionState: NSWindow.OcclusionState { simulatedOcclusion }
    override var isMiniaturized: Bool { simulatedMiniaturized }
}
