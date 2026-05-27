import AppKit
import SwiftUI

/// QuitCue brand mark from the app's Icon Composer `.icon` resource.
struct BrandMark: View {
    var size: CGFloat = 44
    var shadow: Bool = true

    var body: some View {
        Image(nsImage: iconImage)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .shadow(
            color: shadow ? Color(red: 20/255, green: 20/255, blue: 50/255).opacity(0.28) : .clear,
            radius: max(4, size * 0.14),
            x: 0,
            y: max(2, size * 0.06)
        )
    }

    private var iconImage: NSImage {
        NSImage(named: "QuitCue") ?? NSApp.applicationIconImage
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
