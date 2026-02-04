import Foundation
import SwiftData

enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low, med, high
    var id: String { rawValue }
}

enum TaskStatus: String, Codable {
    case todo, done
}

@Model
final class TaskEntity {
    @Attribute(.unique) var id: String
    var title: String
    var createdAt: Date
    var deadline: Date?
    var estimateMinutes: Int?
    var energy: EnergyLevel?
    var tags: [String]
    var parentId: String?
    var status: TaskStatus
    var lastSkippedAt: Date?
    var skipCount: Int
    var nextMicroStep: String?

    init(id: String = UUID().uuidString, title: String, createdAt: Date = Date(), deadline: Date? = nil, estimateMinutes: Int? = nil, energy: EnergyLevel? = nil, tags: [String] = [], parentId: String? = nil, status: TaskStatus = .todo, lastSkippedAt: Date? = nil, skipCount: Int = 0, nextMicroStep: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.deadline = deadline
        self.estimateMinutes = estimateMinutes
        self.energy = energy
        self.tags = tags
        self.parentId = parentId
        self.status = status
        self.lastSkippedAt = lastSkippedAt
        self.skipCount = skipCount
        self.nextMicroStep = nextMicroStep
    }
}

@Model
final class DependencyEntity {
    var beforeId: String
    var afterId: String
    var type: String

    init(beforeId: String, afterId: String, type: String = "hard") {
        self.beforeId = beforeId
        self.afterId = afterId
        self.type = type
    }
}

@Model
final class HistoryEventEntity {
    @Attribute(.unique) var id: String
    var taskId: String
    var eventType: String
    var timestamp: Date
    var dateBucket: String

    init(id: String = UUID().uuidString, taskId: String, eventType: String, timestamp: Date = Date(), dateBucket: String) {
        self.id = id
        self.taskId = taskId
        self.eventType = eventType
        self.timestamp = timestamp
        self.dateBucket = dateBucket
    }
}

@Model
final class PendingSyncEvent {
    @Attribute(.unique) var id: String
    var payload: Data
    var createdAt: Date

    init(id: String = UUID().uuidString, payload: Data, createdAt: Date = Date()) {
        self.id = id
        self.payload = payload
        self.createdAt = createdAt
    }
}

struct TaskPayload: Codable {
    var id: String
    var title: String
    var created_at: Date
    var deadline: Date?
    var estimate_minutes: Int?
    var energy: String?
    var tags: [String]
    var parent_id: String?
    var status: String
    var last_skipped_at: Date?
    var skip_count: Int
    var next_micro_step: String?
}

struct DependencyPayload: Codable {
    var before_id: String
    var after_id: String
    var type: String
}

struct HistoryPayload: Codable {
    var id: String
    var task_id: String
    var event_type: String
    var timestamp: Date
    var date_bucket: String
}

struct SyncRequestPayload: Codable {
    var device_id: String
    var mode: String
    var client_timestamp: Date
    var tasks: [TaskPayload]
    var deps: [DependencyPayload]
    var events: [HistoryPayload]
    var client_state_hash: String
}

struct TimelineBucket: Codable, Identifiable {
    var id: String { date }
    var date: String
    var due_task_ids: [String]
}

struct SyncResponsePayload: Codable {
    var server_timestamp: Date
    var tasks: [TaskPayload]
    var deps: [DependencyPayload]
    var available_order: [String]
    var scores: [String: Double]
    var timeline: [TimelineBucket]
    var cycle_error: CycleErrorPayload?
}

struct CycleErrorPayload: Codable {
    var message: String
    var cycle_edges: [DependencyPayload]
    var suggest_break: [DependencyPayload]
}
