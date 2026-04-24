import AppKit
import SwiftUI

/// Borderless `NSPanel` host for `AuroraHaloView`. Non-activating, floats
/// over every space, transparent background, mouse-transparent.
@MainActor
final class OverlayWindow {
    private let panel: NSPanel
    private let hosting: NSHostingView<AuroraHaloHost>

    init(controller: OverlayController) {
        let contentSize = NSSize(width: 360, height: 360)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        let hosting = NSHostingView(rootView: AuroraHaloHost(controller: controller))
        hosting.frame = NSRect(origin: .zero, size: contentSize)
        panel.contentView = hosting

        self.panel = panel
        self.hosting = hosting
    }

    func present() {
        centerOnActiveScreen()
        panel.orderFrontRegardless()
    }

    func dismiss() {
        panel.orderOut(nil)
    }

    private func centerOnActiveScreen() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

/// SwiftUI wrapper that drives `AuroraHaloView` from the controller's
/// reactive state. `TimelineView(.animation)` gives smooth halo tweening
/// without the controller needing an every-frame tick timer.
struct AuroraHaloHost: View {
    let controller: OverlayController

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let _ = context.date
            AuroraHaloView(
                mode: controller.mode,
                progress: controller.currentProgress(),
                appName: controller.appName
            )
        }
        .frame(width: 360, height: 360)
    }
}
