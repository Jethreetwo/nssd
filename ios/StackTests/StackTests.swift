import XCTest
import SwiftData
@testable import Stack

final class StackTests: XCTestCase {
    func testPersistenceInsert() throws {
        let schema = Schema([TaskEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let store = DataStore(context: context)
        _ = store.addTask(title: "Test", deadline: nil, estimateMinutes: 5, energy: .low, tags: [])
        XCTAssertEqual(store.fetchTasks().count, 1)
    }

    func testOrderingAvailable() throws {
        let schema = Schema([TaskEntity.self, DependencyEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let store = DataStore(context: context)
        let first = store.addTask(title: "First", deadline: nil, estimateMinutes: nil, energy: nil, tags: [])
        let second = store.addTask(title: "Second", deadline: nil, estimateMinutes: nil, energy: nil, tags: [])
        store.addDependency(beforeId: first.id, afterId: second.id)
        let viewModel = StackViewModel()
        viewModel.refresh(context: context)
        XCTAssertEqual(viewModel.availableTasks.first?.id, first.id)
    }
}
