import SwiftUI
#if os(macOS)
import AppKit

struct WindowAccessor: ViewModifier {
    var onResolve: (NSWindow) -> Void

    func body(content: Content) -> some View {
        content
            .background(WindowResolver(onResolve: onResolve))
    }
}

private struct WindowResolver: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if let w = nsView.window {
            onResolve(w)
        }
    }
}
#endif

