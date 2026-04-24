import SwiftUI

/// Aurora Halo overlay — the floating glass card that appears when an
/// intercepted ⌘Q needs confirmation. M1 scaffold — the animated halo,
/// hold/double-press state machines, and `NSPanel` host arrive in M3.
struct AuroraHaloView: View {
    let appName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "command")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .accentColor.opacity(0.6), radius: 28)

            Text("Hold ⌘Q to quit \(appName)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(40)
        .frame(width: 320, height: 320)
        .liquidGlass(cornerRadius: 28)
    }
}

#Preview {
    AuroraHaloView(appName: "Code Editor")
        .padding(60)
        .background(Color.black)
}
