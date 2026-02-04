import Foundation
import SwiftData

@MainActor
final class StackViewModel: ObservableObject {
    @Published var availableTasks: [TaskEntity] = []

    func refresh(context: ModelContext) {
        let store = DataStore(context: context)
        let tasks = store.fetchTasks()
        let deps = store.fetchDeps()
        availableTasks = Self.computeAvailable(tasks: tasks, deps: deps)
    }

    func swipeDone(task: TaskEntity, context: ModelContext) {
        let store = DataStore(context: context)
        store.markDone(task: task)
        refresh(context: context)
    }

    func swipeSkip(task: TaskEntity, context: ModelContext) {
        let store = DataStore(context: context)
        store.markSkipped(task: task)
        availableTasks = Self.reinsert(task: task, tasks: availableTasks, deps: store.fetchDeps())
    }

    private static func computeAvailable(tasks: [TaskEntity], deps: [DependencyEntity]) -> [TaskEntity] {
        let done = Set(tasks.filter { $0.status == .done }.map { $0.id })
        let incoming = deps.reduce(into: [String: Set<String>]()) { result, dep in
            result[dep.afterId, default: []].insert(dep.beforeId)
        }
        let available = tasks.filter { task in
            task.status != .done && (incoming[task.id] ?? []).isSubset(of: done)
        }
        return available.sorted { $0.createdAt < $1.createdAt }
    }

    private static func reinsert(task: TaskEntity, tasks: [TaskEntity], deps: [DependencyEntity]) -> [TaskEntity] {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return tasks }
        let order = tasks.map { $0.id }
        let descendants = descendantIds(root: task.id, deps: deps)
        var maxIndex = order.count - 1
        for (idx, id) in order.enumerated() {
            if descendants.contains(id) {
                maxIndex = min(maxIndex, idx - 1)
                break
            }
        }
        let targetIndex = min(maxIndex, index + 4)
        var newTasks = tasks.filter { $0.id != task.id }
        newTasks.insert(task, at: max(0, targetIndex))
        return newTasks
    }

    private static func descendantIds(root: String, deps: [DependencyEntity]) -> Set<String> {
        var outgoing: [String: [String]] = [:]
        for dep in deps {
            outgoing[dep.beforeId, default: []].append(dep.afterId)
        }
        var seen: Set<String> = []
        var stack = [root]
        while let node = stack.popLast() {
            for child in outgoing[node] ?? [] {
                if !seen.contains(child) {
                    seen.insert(child)
                    stack.append(child)
                }
            }
        }
        return seen
    }
}
