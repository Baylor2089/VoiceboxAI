import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKeyInput: String = ""
    @State private var modelInput: String = ""
    @State private var tempInput: Double = 0.3
    @State private var saved: Bool = false

    var body: some View {
        Form {
            Section("Google Gemini") {
                SecureField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                HStack {
                    Text("模型名")
                    TextField("gemini-2.5-flash-lite", text: $modelInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("温度")
                        Slider(value: $tempInput, in: 0...1, step: 0.05)
                        Text(String(format: "%.2f", tempInput))
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    Text("越低越稳健，越高越有创造性。建议 0.2–0.4。")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                HStack {
                    Button("保存") { save() }
                        .buttonStyle(.borderedProminent)
                    if saved { Text("已保存").foregroundStyle(.secondary) }
                    Spacer()
                    Button("清除 Keychain 中的 Key", role: .destructive) { clearKey() }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 520)
        .onAppear {
            apiKeyInput = appState.apiKey
            modelInput = appState.modelName
            tempInput = appState.temperature
        }
    }

    private func save() {
        if !apiKeyInput.isEmpty {
            KeychainHelper.shared.save(apiKeyInput, service: KeychainHelper.service, account: KeychainHelper.account)
            appState.apiKey = apiKeyInput
        }
        let model = modelInput.isEmpty ? "gemini-2.5-flash-lite" : modelInput
        appState.modelName = model
        UserDefaults.standard.set(model, forKey: UserDefaultsKeys.modelName)
        appState.temperature = tempInput
        UserDefaults.standard.set(tempInput, forKey: UserDefaultsKeys.temperature)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { saved = false }
    }

    private func clearKey() {
        KeychainHelper.shared.delete(service: KeychainHelper.service, account: KeychainHelper.account)
        appState.apiKey = ""
        apiKeyInput = ""
    }
}

