import AppKit
import SwiftUI

struct TypeAheadKeyCapture: NSViewRepresentable {
    var onCharacter: (String) -> Bool

    func makeNSView(context: Context) -> TypeAheadKeyCaptureView {
        let view = TypeAheadKeyCaptureView()
        view.onCharacter = onCharacter
        return view
    }

    func updateNSView(_ nsView: TypeAheadKeyCaptureView, context: Context) {
        nsView.onCharacter = onCharacter
    }
}

extension View {
    func onTypeAheadCharacter(_ handler: @escaping (String) -> Bool) -> some View {
        background(TypeAheadKeyCapture(onCharacter: handler).frame(width: 0, height: 0))
    }
}

final class TypeAheadKeyCaptureView: NSView {
    var onCharacter: ((String) -> Bool)?

    nonisolated(unsafe) private var monitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard
                let self,
                self.shouldReceive(event),
                let character = Self.typeAheadCharacter(from: event)
            else {
                return event
            }

            return self.onCharacter?(character) == true ? nil : event
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func shouldReceive(_ event: NSEvent) -> Bool {
        guard let window else { return false }
        guard !(window.firstResponder is NSTextView) else { return false }
        return event.window === window && window.isKeyWindow
    }

    private static func typeAheadCharacter(from event: NSEvent) -> String? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.intersection([.command, .control, .option]).isEmpty else { return nil }
        guard
            let characters = event.charactersIgnoringModifiers,
            characters.count == 1,
            let scalar = characters.unicodeScalars.first,
            !CharacterSet.controlCharacters.contains(scalar),
            !CharacterSet.newlines.contains(scalar)
        else {
            return nil
        }
        return characters
    }
}
