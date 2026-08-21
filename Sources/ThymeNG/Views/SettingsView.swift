import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }

            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 460)
    }
}

private struct GeneralSettingsView: View {
    let model: AppModel

    var body: some View {
        @Bindable var preferences = model.preferences
        @Bindable var loginItem = model.loginItem

        Form {
            Section("Timer") {
                Toggle("Pause during sleep", isOn: $preferences.pauseOnSleep)
                Toggle("Pause during screensaver or screen lock", isOn: $preferences.pauseOnScreensaver)
                Toggle("Ask for a tag when a session finishes", isOn: $preferences.askForTagOnFinish)
            }

            Section("Sessions") {
                Toggle("Delete old sessions automatically", isOn: $preferences.limitsStoredSessions)

                if preferences.limitsStoredSessions {
                    Stepper(value: $preferences.maxStoredSessions, in: 1 ... 500) {
                        Text("Keep the last \(preferences.maxStoredSessions) sessions")
                    }
                }
            }

            Section("Startup") {
                Toggle("Start thyme-ng at login", isOn: $loginItem.isEnabled)

                if let error = loginItem.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: preferences.maxStoredSessions) {
            model.applySessionLimit()
        }
    }
}

private struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Start / Pause:", name: .toggle)
                KeyboardShortcuts.Recorder("Restart:", name: .restart)
                KeyboardShortcuts.Recorder("Finish:", name: .finish)
            } footer: {
                Text("These shortcuts work in every application.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
