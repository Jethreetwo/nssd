import SwiftUI
import SwiftData

@main
struct StackApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TaskEntity.self, DependencyEntity.self, HistoryEventEntity.self, PendingSyncEvent.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
