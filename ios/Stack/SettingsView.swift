import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Server URL", text: $appState.serverURL)
                        .textInputAutocapitalization(.never)
                    SecureField("Token", text: $appState.token)
                }
                Section("Mode") {
                    Picker("Mode", selection: $appState.mode) {
                        Text("Focus").tag("focus")
                        Text("Quick").tag("quick")
                        Text("Deep").tag("deep")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Status") {
                    Text(appState.lastSyncStatus)
                }
                Section("Remote mode") {
                    Text("Use HTTPS + a reverse proxy (Caddy/Nginx). Keep your token private.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
