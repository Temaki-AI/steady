import SwiftUI

/// Collapsible time-of-day group (Morning, Afternoon, Evening, Anytime)
struct TimeGroupView: View {
    let timeOfDay: TimeOfDay
    let habits: [Habit]
    let date: Date
    let streaks: [UUID: Int]
    let onToggle: (Habit) -> Void

    @AppStorage("collapsed_\(TimeOfDay.morning.rawValue)") private var collapsedMorning = false
    @AppStorage("collapsed_\(TimeOfDay.afternoon.rawValue)") private var collapsedAfternoon = false
    @AppStorage("collapsed_\(TimeOfDay.evening.rawValue)") private var collapsedEvening = false
    @AppStorage("collapsed_\(TimeOfDay.anytime.rawValue)") private var collapsedAnytime = false

    private var isCollapsed: Bool {
        switch timeOfDay {
        case .morning: return collapsedMorning
        case .afternoon: return collapsedAfternoon
        case .evening: return collapsedEvening
        case .anytime: return collapsedAnytime
        }
    }

    private func toggleCollapsed() {
        switch timeOfDay {
        case .morning: collapsedMorning.toggle()
        case .afternoon: collapsedAfternoon.toggle()
        case .evening: collapsedEvening.toggle()
        case .anytime: collapsedAnytime.toggle()
        }
    }

    private var completedCount: Int {
        habits.filter { $0.isCompleted(for: date) }.count
    }

    private var allDone: Bool {
        !habits.isEmpty && completedCount == habits.count
    }

    var body: some View {
        if !habits.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Section Header
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        toggleCollapsed()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: timeOfDay.icon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(timeOfDay.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text("(\(completedCount)/\(habits.count))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        if allDone {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                // Habit List
                if !isCollapsed {
                    ForEach(habits.sorted(by: { $0.position < $1.position })) { habit in
                        HabitRowView(
                            habit: habit,
                            date: date,
                            streak: streaks[habit.id] ?? 0,
                            onToggle: { onToggle(habit) }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}
