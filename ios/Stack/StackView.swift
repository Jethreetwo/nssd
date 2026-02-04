import SwiftUI
import SwiftData

struct StackView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = StackViewModel()
    @GestureState private var dragOffset: CGSize = .zero

    let appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.stackBackground.ignoresSafeArea()
                if let task = viewModel.availableTasks.first {
                    TaskCard(task: task)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    handleSwipe(value: value, task: task)
                                }
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
                } else {
                    Text("All caught up")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Stack")
            .toolbar {
                Button("Sync") {
                    Task { await appState.sync(context: context) }
                }
            }
            .onAppear { viewModel.refresh(context: context) }
        }
    }

    private func handleSwipe(value: DragGesture.Value, task: TaskEntity) {
        if value.translation.width > 120 {
            viewModel.swipeDone(task: task, context: context)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else if value.translation.width < -120 {
            viewModel.swipeSkip(task: task, context: context)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

struct TaskCard: View {
    let task: TaskEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.title)
                .font(.largeTitle.bold())
                .accessibilityLabel(task.title)
            HStack(spacing: 12) {
                if let deadline = task.deadline {
                    Label(deadline, systemImage: "calendar")
                        .labelStyle(.titleAndIcon)
                }
                if let estimate = task.estimateMinutes {
                    Label("\(estimate) min", systemImage: "timer")
                }
                if let energy = task.energy {
                    Label(energy.rawValue.capitalized, systemImage: "bolt.heart")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let micro = task.nextMicroStep {
                Text(micro)
                    .font(.headline)
                    .padding(12)
                    .background(Color.stackBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
            HStack {
                Label("Not now", systemImage: "xmark")
                Spacer()
                Label("Done", systemImage: "checkmark")
            }
            .font(.headline)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: 520)
        .background(Color.stackCard)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding()
        .accessibilityHint("Swipe right to complete, left to skip")
    }
}
