import AppKit
import SwiftUI

/// Recreates the prototype's light Liquid Glass window wash:
/// a translucent white shell with subtle purple refraction behind content.
struct GlassWindowBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.pageBackground

            LinearGradient(
                colors: [
                    .glassShellTop,
                    .glassShellBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { proxy in
                let longEdge = max(proxy.size.width, proxy.size.height)

                RadialGradient(
                    colors: [
                        .glassWashPrimary.opacity(colorScheme == .dark ? 0.40 : 0.50),
                        .glassWashPrimary.opacity(0)
                    ],
                    center: UnitPoint(x: 0.2, y: 0),
                    startRadius: 0,
                    endRadius: longEdge * 0.62
                )
                .blendMode(colorScheme == .dark ? .screen : .normal)

                RadialGradient(
                    colors: [
                        .glassWashSecondary.opacity(colorScheme == .dark ? 0.30 : 0.31),
                        .glassWashSecondary.opacity(0)
                    ],
                    center: UnitPoint(x: 1, y: 1),
                    startRadius: 0,
                    endRadius: longEdge * 0.58
                )
                .blendMode(colorScheme == .dark ? .screen : .normal)
            }
        }
    }
}

/// Applies the native Liquid Glass effect on macOS 26+, falling back to
/// `.ultraThinMaterial` with a thin specular stroke on earlier versions.
///
/// Use for navigation-layer surfaces only (toolbars, floating controls, sheets,
/// overlay panels). Never apply to content-layer views such as list rows,
/// text blocks, or media.
struct LiquidGlassBackground<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(tint.map { .regular.tint($0) } ?? .regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.35),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        }
    }
}

extension View {
    /// Apply Liquid Glass (macOS 26+) with a graceful material fallback.
    ///
    /// - Parameters:
    ///   - shape: The containing shape (defaults to a continuous 16pt rounded rect).
    ///   - tint: Optional tint that flows into the glass on macOS 26.
    func liquidGlass<S: InsettableShape>(
        in shape: S,
        tint: Color? = nil
    ) -> some View {
        modifier(LiquidGlassBackground(shape: shape, tint: tint))
    }

    func liquidGlass(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        liquidGlass(
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
            tint: tint
        )
    }
}

struct OverlayScrollerConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configureScrollView(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureScrollView(for: nsView)
        }
    }

    private func configureScrollView(for view: NSView) {
        guard let scrollView = view.enclosingScrollView else { return }
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
    }
}
