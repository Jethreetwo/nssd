import SwiftUI
import SwiftData

struct DeadlinesView: View {
    @Query private var tasks: [TaskEntity]
    @State private var range: Int = 7

    var upcoming: [TaskEntity] {
        let cutoff = Calendar.current.date(byAdding: .day, value: range, to: Date()) ?? Date()
        return tasks.filter { task in
            if let deadline = task.deadline {
                return deadline <= cutoff
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Range", selection: $range) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(groupedByDay.keys.sorted(), id: \.self) { day in
                        Section(day) {
                            ForEach(groupedByDay[day] ?? []) { task in
                                HStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.stackAccent)
                                        .frame(width: 6)
                                    Text(task.title)
                                    Spacer()
                                    if let deadline = task.deadline {
                                        Text(deadline, style: .time)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.stackBackground.ignoresSafeArea())
            .navigationTitle("Deadlines")
        }
    }

    private var groupedByDay: [String: [TaskEntity]] {
        Dictionary(grouping: upcoming) { task in
            guard let deadline = task.deadline else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: deadline)
        }
    }
}
