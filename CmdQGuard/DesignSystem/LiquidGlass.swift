import SwiftUI

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
