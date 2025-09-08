import SwiftUI

@main
struct VoiceboxAIApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var apiKey: String = KeychainHelper.shared.read(service: KeychainHelper.service, account: KeychainHelper.account) ?? ""
    @Published var modelName: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.modelName) ?? "gemini-2.5-flash-lite"
    @Published var temperature: Double = UserDefaults.standard.object(forKey: UserDefaultsKeys.temperature) as? Double ?? 0.3
}

enum UserDefaultsKeys {
    static let modelName = "modelName"
    static let temperature = "temperature"
}

