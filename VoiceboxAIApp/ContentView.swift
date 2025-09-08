import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let gemini = GeminiService()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("VoiceboxAI")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SettingsButton()
            }

            TextEditor(text: $inputText)
                .scrollContentBackground(.hidden)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(minWidth: 520, maxWidth: 640, minHeight: 120, maxHeight: 160)
                .overlay(alignment: .topLeading) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("在这里输入中文/英文/混合，转成自然日语（Slack 语气）…")
                            .foregroundStyle(.tertiary)
                            .padding(8)
                    }
                }

            HStack(spacing: 8) {
                Button(action: translate) {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("转成日语（Slack 语气）")
                            .fontWeight(.semibold)
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || appState.apiKey.isEmpty || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(action: { inputText.removeAll() }) {
                    Text("清空")
                }
                .disabled(isLoading || inputText.isEmpty)

                Spacer()

                Button(action: copyOutput) {
                    Label("复制结果", systemImage: "doc.on.doc")
                }
                .disabled(outputText.isEmpty)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("结果")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                ScrollView {
                    Text(outputText.isEmpty ? "" : outputText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(minHeight: 120, maxHeight: 220)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let err = errorMessage {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
        }
        .padding(16)
        .background(EffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(8)
        .modifier(WindowAccessor(onResolve: { window in
            window.level = .floating
            window.isOpaque = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }))
    }

    private func translate() {
        guard !appState.apiKey.isEmpty else {
            errorMessage = "请先在设置中填写 Google Gemini API Key"
            return
        }
        errorMessage = nil
        outputText.removeAll()
        isLoading = true

        Task {
            do {
                let result = try await gemini.rewriteToJapanese(
                    input: inputText,
                    apiKey: appState.apiKey,
                    model: appState.modelName,
                    temperature: appState.temperature
                )
                await MainActor.run {
                    outputText = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
    }
}

private struct SettingsButton: View {
    var body: some View {
        Button(action: {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }) {
            Image(systemName: "gearshape")
                .imageScale(.medium)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("打开设置")
    }
}

private struct EffectBackground: View {
    var body: some View {
        #if os(macOS)
        VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        #else
        Color.clear
        #endif
    }
}

#if os(macOS)
import AppKit
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

