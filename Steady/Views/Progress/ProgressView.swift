import SwiftUI
import SwiftData

/// Progress tab — heatmap, stats, per-habit details
struct SteadyProgressView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.position)
    private var habits: [Habit]

    @State private var heatmapData: [HeatmapDataProvider.DayData] = []
    @State private var isLoading = true

    private let heatmapProvider = HeatmapDataProvider()
    private let streakCalculator = StreakCalculator()

    private var todayCompleted: Int {
        habits.filter { $0.isCompleted(for: Date()) }.count
    }

    private var todayScheduled: Int {
        habits.filter { $0.isScheduled(for: Date()) }.count
    }

    private var weekCompleted: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var count = 0
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek),
                  date <= Date() else { continue }
            count += habits.filter { $0.isCompleted(for: date) }.count
        }
        return count
    }

    private var weekScheduled: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var count = 0
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek),
                  date <= Date() else { continue }
            count += habits.filter { $0.isScheduled(for: date) && $0.existedOn(date: date) }.count
        }
        return count
    }

    private var bestStreakOverall: Int {
        habits.map { streakCalculator.calculate(for: $0).best }.max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    HStack(spacing: 12) {
                        StatCard(title: "Today", value: "\(todayCompleted)/\(todayScheduled)", icon: "checkmark.circle")
                        StatCard(title: "This Week", value: "\(weekCompleted)/\(weekScheduled)", icon: "calendar")
                        StatCard(title: "Best Streak", value: "\(bestStreakOverall)", icon: "flame.fill")
                    }
                    .padding(.horizontal)

                    // Overall Heatmap
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contribution Graph")
                            .font(.headline)
                            .padding(.horizontal)

                        if isLoading {
                            ProgressView()
                                .frame(height: 100)
                        } else {
                            InteractiveHeatmapView(data: heatmapData)
                        }
                    }

                    // Per-habit stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Habits")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(habits) { habit in
                            NavigationLink {
                                HabitDetailView(habit: habit)
                            } label: {
                                HabitStatRow(habit: habit, streakCalculator: streakCalculator)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .task {
                await loadHeatmap()
            }
        }
    }

    private func loadHeatmap() async {
        let data = heatmapProvider.generateHeatmap(habits: habits)
        await MainActor.run {
            heatmapData = data
            isLoading = false
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Habit Stat Row

struct HabitStatRow: View {
    let habit: Habit
    let streakCalculator: StreakCalculator

    private var streak: StreakCalculator.StreakResult {
        streakCalculator.calculate(for: habit)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.body)
                .foregroundStyle(Color(hex: habit.colorHex) ?? .green)
                .frame(width: 32, height: 32)
                .background((Color(hex: habit.colorHex) ?? .green).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(habit.schedule.displayText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text("🔥")
                        .font(.caption2)
                    Text("\(streak.current)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("Best: \(streak.best)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Habit Detail View

struct HabitDetailView: View {
    let habit: Habit

    @State private var heatmapData: [HeatmapDataProvider.DayData] = []
    private let heatmapProvider = HeatmapDataProvider()
    private let streakCalculator = StreakCalculator()

    private var streak: StreakCalculator.StreakResult {
        streakCalculator.calculate(for: habit)
    }

    private var totalCompletions: Int {
        habit.completions.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: habit.icon)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: habit.colorHex) ?? .green)

                    Text(habit.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(habit.schedule.displayText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats
                HStack(spacing: 16) {
                    StatCard(title: "Current Streak", value: "\(streak.current)", icon: "flame.fill")
                    StatCard(title: "Best Streak", value: "\(streak.best)", icon: "trophy.fill")
                    StatCard(title: "Total", value: "\(totalCompletions)", icon: "checkmark.circle.fill")
                }
                .padding(.horizontal)

                // Heatmap
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.headline)
                        .padding(.horizontal)

                    InteractiveHeatmapView(
                        data: heatmapData,
                        accentColor: Color(hex: habit.colorHex) ?? .green
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            heatmapData = heatmapProvider.generateHabitHeatmap(habit: habit)
        }
    }
}
