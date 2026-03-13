import SwiftUI

/// Collapsible time-of-day group (Morning, Afternoon, Evening, Anytime)
/// Designed to be used inside a List — outputs a Section with native swipe actions.
struct TimeGroupView: View {
    let timeOfDay: TimeOfDay
    let habits: [Habit]
    let date: Date
    let streaks: [UUID: Int]
    let onToggle: (Habit) -> Void
    let onEdit: (Habit) -> Void
    let onArchive: (Habit) -> Void

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
            Section {
                // Section Header (collapsible)
                Button {
                    HapticEngine.toggleGroup()
                    withAnimation(DesignSystem.Animation.respectingMotion(.spring(response: 0.3, dampingFraction: 0.7)) ?? .easeInOut(duration: 0.2)) {
                        toggleCollapsed()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: timeOfDay.icon)
                                .font(.subheadline)
                                .foregroundStyle(allDone ? DesignSystem.Colors.primaryGreen : .secondary)

                            Text(timeOfDay.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(allDone ? DesignSystem.Colors.primaryGreen : .primary)

                            Spacer()

                            Text("\(completedCount)/\(habits.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        // Mini progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(DesignSystem.Colors.emptyCells)
                                    .frame(height: 3)

                                Capsule()
                                    .fill(allDone ? DesignSystem.Colors.primaryGreen : DesignSystem.Colors.primaryGreen.opacity(0.6))
                                    .frame(width: geometry.size.width * CGFloat(completedCount) / CGFloat(habits.count), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(.vertical, 10)
                    .background(
                        allDone ? DesignSystem.Colors.primaryGreen.opacity(0.08) : Color.clear
                    )
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 0, trailing: 16))

                // Habit rows with native swipe actions
                if !isCollapsed {
                    ForEach(habits.sorted(by: { $0.position < $1.position })) { habit in
                        HabitRowView(
                            habit: habit,
                            date: date,
                            streak: streaks[habit.id] ?? 0,
                            onToggle: { onToggle(habit) }
                        )
                        .onTapGesture {
                            onEdit(habit)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                onArchive(habit)
                            } label: {
                                Label("Archive", systemImage: "archivebox.fill")
                            }
                            .tint(.orange)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    }
                }
            }
        }
    }
}
