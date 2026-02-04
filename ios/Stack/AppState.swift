import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var serverURL: String = "http://localhost:8000"
    @Published var token: String = ""
    @Published var mode: String = "focus"
    @Published var lastSyncStatus: String = "Offline"

    private let syncClient = SyncClient()

    func sync(context: ModelContext) async {
        let store = DataStore(context: context)
        let tasks = store.fetchTasks().map { $0.toPayload() }
        let deps = store.fetchDeps().map { DependencyPayload(before_id: $0.beforeId, after_id: $0.afterId, type: $0.type) }
        let events = store.fetchHistory().map { $0.toPayload() }
        let payload = SyncRequestPayload(
            device_id: UIDevice.current.identifierForVendor?.uuidString ?? "ios",
            mode: mode,
            client_timestamp: Date(),
            tasks: tasks,
            deps: deps,
            events: events,
            client_state_hash: "local"
        )
        store.queueSyncEvent(payload)
        guard let url = URL(string: serverURL) else { return }
        do {
            let response = try await syncClient.sync(payload: payload, settings: SyncSettings(serverURL: url, token: token, mode: mode))
            applySyncResponse(response, context: context)
            lastSyncStatus = "Connected"
        } catch {
            lastSyncStatus = "Offline"
        }
    }

    private func applySyncResponse(_ response: SyncResponsePayload, context: ModelContext) {
        let store = DataStore(context: context)
        for task in response.tasks {
            store.upsert(taskPayload: task)
        }
        store.replaceDependencies(response.deps)
    }
}

extension DataStore {
    func upsert(taskPayload: TaskPayload) {
        if let existing = try? context.fetch(FetchDescriptor<TaskEntity>(predicate: #Predicate { $0.id == taskPayload.id })).first {
            existing.title = taskPayload.title
            existing.deadline = taskPayload.deadline
            existing.estimateMinutes = taskPayload.estimate_minutes
            existing.energy = EnergyLevel(rawValue: taskPayload.energy ?? "")
            existing.tags = taskPayload.tags
            existing.parentId = taskPayload.parent_id
            existing.status = TaskStatus(rawValue: taskPayload.status) ?? .todo
            existing.lastSkippedAt = taskPayload.last_skipped_at
            existing.skipCount = taskPayload.skip_count
            existing.nextMicroStep = taskPayload.next_micro_step
        } else {
            let task = TaskEntity(
                id: taskPayload.id,
                title: taskPayload.title,
                createdAt: taskPayload.created_at,
                deadline: taskPayload.deadline,
                estimateMinutes: taskPayload.estimate_minutes,
                energy: EnergyLevel(rawValue: taskPayload.energy ?? ""),
                tags: taskPayload.tags,
                parentId: taskPayload.parent_id,
                status: TaskStatus(rawValue: taskPayload.status) ?? .todo,
                lastSkippedAt: taskPayload.last_skipped_at,
                skipCount: taskPayload.skip_count,
                nextMicroStep: taskPayload.next_micro_step
            )
            context.insert(task)
        }
    }

    func upsert(depPayload: DependencyPayload) {
        let dep = DependencyEntity(beforeId: depPayload.before_id, afterId: depPayload.after_id, type: depPayload.type)
        context.insert(dep)
    }

    func replaceDependencies(_ payloads: [DependencyPayload]) {
        let existing = (try? context.fetch(FetchDescriptor<DependencyEntity>())) ?? []
        for dep in existing {
            context.delete(dep)
        }
        for payload in payloads {
            upsert(depPayload: payload)
        }
    }
}

extension TaskEntity {
    func toPayload() -> TaskPayload {
        TaskPayload(
            id: id,
            title: title,
            created_at: createdAt,
            deadline: deadline,
            estimate_minutes: estimateMinutes,
            energy: energy?.rawValue,
            tags: tags,
            parent_id: parentId,
            status: status.rawValue,
            last_skipped_at: lastSkippedAt,
            skip_count: skipCount,
            next_micro_step: nextMicroStep
        )
    }
}

extension HistoryEventEntity {
    func toPayload() -> HistoryPayload {
        HistoryPayload(
            id: id,
            task_id: taskId,
            event_type: eventType,
            timestamp: timestamp,
            date_bucket: dateBucket
        )
    }
}
