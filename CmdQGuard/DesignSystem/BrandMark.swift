import SwiftUI

/// CmdQGuard brand mark — a macOS squircle with a stylized Q-with-guard-slash
/// glyph, per the HTML prototype's `BrandMark` component. Scales to any size.
struct BrandMark: View {
    var size: CGFloat = 44
    var shadow: Bool = true

    var body: some View {
        // Use a 64-pt design space then scale; keeps all strokes metrically
        // correct at arbitrary sizes.
        let design: CGFloat = 64

        ZStack {
            squircle
                .fill(backgroundGradient)
                .overlay(bottomBloom.clipShape(SquircleShape()))
                .overlay(topHighlight.clipShape(SquircleShape()))
                .overlay(
                    // Hairline inside border.
                    SquircleShape()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                )

            glyph(in: design)
        }
        .frame(width: design, height: design)
        .scaleEffect(size / design)
        .frame(width: size, height: size)
        .shadow(
            color: shadow ? Color(red: 0.24, green: 0.20, blue: 0.55).opacity(0.35) : .clear,
            radius: max(4, size * 0.18),
            x: 0,
            y: max(2, size * 0.08)
        )
    }

    private var squircle: some Shape { SquircleShape() }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hue: 275/360, saturation: 0.30, brightness: 0.78), location: 0.0),
                .init(color: Color(hue: 278/360, saturation: 0.60, brightness: 0.55), location: 0.55),
                .init(color: Color(hue: 280/360, saturation: 0.55, brightness: 0.38), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var bottomBloom: some View {
        Circle()
            .fill(Color(hue: 300/360, saturation: 0.60, brightness: 0.80).opacity(0.35))
            .frame(width: 52, height: 52)
            .offset(x: 20, y: 22)
            .blur(radius: 0)
    }

    private var topHighlight: some View {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.55), location: 0.0),
                .init(color: Color.white.opacity(0.05), location: 0.45),
                .init(color: Color.white.opacity(0.0), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func glyph(in size: CGFloat) -> some View {
        // Outer Q ring.
        Circle()
            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .frame(width: 29, height: 29)
            .offset(y: -1)

        // Q tail — diagonal slash.
        Path { path in
            path.move(to: CGPoint(x: 40, y: 40))
            path.addLine(to: CGPoint(x: 49, y: 49))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))

        // Small command-key accent dot.
        Circle()
            .fill(Color(hue: 275/360, saturation: 0.18, brightness: 0.96))
            .frame(width: 3.6, height: 3.6)
            .offset(x: 17, y: 17)
    }
}

/// Approximates a macOS 22.8 %-radius squircle with a rounded rectangle.
/// Pure SwiftUI, no SVG, no Core Graphics path math.
private struct SquircleShape: Shape, InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = inset.width * 0.228
        return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: inset)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    HStack(spacing: 20) {
        BrandMark(size: 32)
        BrandMark(size: 44)
        BrandMark(size: 72)
    }
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}
