import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var appState = AppState()

    var body: some View {
        TabView {
            CaptureView(appState: appState)
                .tabItem { Label("Capture", systemImage: "plus.circle") }
            StackView(appState: appState)
                .tabItem { Label("Stack", systemImage: "rectangle.stack") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
            DeadlinesView()
                .tabItem { Label("Deadlines", systemImage: "calendar") }
            SettingsView(appState: appState)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.stackAccent)
        .task {
            await appState.sync(context: context)
        }
    }
}
