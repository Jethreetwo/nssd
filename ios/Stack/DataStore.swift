import Foundation
import SwiftData

@MainActor
final class DataStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addTask(title: String, deadline: Date?, estimateMinutes: Int?, energy: EnergyLevel?, tags: [String]) -> TaskEntity {
        let task = TaskEntity(title: title, deadline: deadline, estimateMinutes: estimateMinutes, energy: energy, tags: tags)
        context.insert(task)
        addHistory(taskId: task.id, eventType: "created")
        return task
    }

    func addDependency(beforeId: String, afterId: String) {
        let dep = DependencyEntity(beforeId: beforeId, afterId: afterId)
        context.insert(dep)
    }

    func markDone(task: TaskEntity) {
        task.status = .done
        addHistory(taskId: task.id, eventType: "done")
    }

    func markSkipped(task: TaskEntity) {
        task.lastSkippedAt = Date()
        task.skipCount += 1
        addHistory(taskId: task.id, eventType: "skipped")
    }

    func addHistory(taskId: String, eventType: String) {
        let bucket = Self.dateBucket(for: Date())
        let event = HistoryEventEntity(taskId: taskId, eventType: eventType, dateBucket: bucket)
        context.insert(event)
    }

    func queueSyncEvent(_ payload: SyncRequestPayload) {
        guard let data = try? JSONEncoder.iso8601.encode(payload) else { return }
        let pending = PendingSyncEvent(payload: data)
        context.insert(pending)
    }

    func fetchTasks() -> [TaskEntity] {
        (try? context.fetch(FetchDescriptor<TaskEntity>())) ?? []
    }

    func fetchDeps() -> [DependencyEntity] {
        (try? context.fetch(FetchDescriptor<DependencyEntity>())) ?? []
    }

    func fetchHistory() -> [HistoryEventEntity] {
        (try? context.fetch(FetchDescriptor<HistoryEventEntity>())) ?? []
    }

    static func dateBucket(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
