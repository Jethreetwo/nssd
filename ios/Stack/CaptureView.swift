import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @State private var title: String = ""
    @State private var deadline: Date = Date()
    @State private var includeDeadline = false
    @State private var estimate: Double = 15
    @State private var includeEstimate = false
    @State private var energy: EnergyLevel = .med
    @State private var includeEnergy = false
    @State private var tags: String = ""
    @State private var beforeTask: TaskEntity?
    @State private var afterTask: TaskEntity?

    let appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Add task", text: $title)
                        .font(.title2.bold())
                        .padding()
                        .background(Color.stackCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Task title")

                    Toggle("Deadline", isOn: $includeDeadline)
                    if includeDeadline {
                        DatePicker("", selection: $deadline)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    }

                    Toggle("Estimate", isOn: $includeEstimate)
                    if includeEstimate {
                        HStack {
                            Slider(value: $estimate, in: 5...120, step: 5)
                            Text("\(Int(estimate)) min")
                        }
                    }

                    Toggle("Energy", isOn: $includeEnergy)
                    if includeEnergy {
                        Picker("Energy", selection: $energy) {
                            ForEach(EnergyLevel.allCases) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TextField("Tags (comma separated)", text: $tags)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.stackCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    DependencyPicker(beforeTask: $beforeTask, afterTask: $afterTask)

                    Button(action: saveTask) {
                        Text("Add")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.stackAccent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .accessibilityHint("Adds task to the stack")
                }
                .padding()
            }
            .navigationTitle("Capture")
            .background(Color.stackBackground.ignoresSafeArea())
        }
    }

    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let store = DataStore(context: context)
        let task = store.addTask(
            title: title,
            deadline: includeDeadline ? deadline : nil,
            estimateMinutes: includeEstimate ? Int(estimate) : nil,
            energy: includeEnergy ? energy : nil,
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        )
        if let beforeTask, let afterTask {
            store.addDependency(beforeId: beforeTask.id, afterId: afterTask.id)
        }
        title = ""
        beforeTask = nil
        afterTask = nil
        Task {
            await appState.sync(context: context)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

struct DependencyPicker: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskEntity]
    @Binding var beforeTask: TaskEntity?
    @Binding var afterTask: TaskEntity?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dependency")
                .font(.headline)
            Picker("Must happen before", selection: $beforeTask) {
                Text("None").tag(TaskEntity?.none)
                ForEach(tasks) { task in
                    Text(task.title).tag(Optional(task))
                }
            }
            Picker("Must happen after", selection: $afterTask) {
                Text("None").tag(TaskEntity?.none)
                ForEach(tasks) { task in
                    Text(task.title).tag(Optional(task))
                }
            }
        }
        .padding()
        .background(Color.stackCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
