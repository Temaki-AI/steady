import SwiftUI
import SwiftData

/// Progress tab — heatmap, stats, per-habit details
struct SteadyFlowProgressView: View {
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
                VStack(spacing: 32) {
                    // Summary Cards
                    HStack(spacing: 12) {
                        StatCard(title: "Today", value: "\(todayCompleted)/\(todayScheduled)", icon: "checkmark.circle")
                        StatCard(title: "This Week", value: "\(weekCompleted)/\(weekScheduled)", icon: "calendar")
                        StatCard(title: "Best Streak", value: "\(bestStreakOverall)", icon: "flame.fill")
                    }
                    .padding(.horizontal)

                    // Overall Heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contribution Graph")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
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
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DesignSystem.Colors.primaryGreen)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.surface,
                    DesignSystem.Colors.surface.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primaryGreen.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Habit Stat Row

struct HabitStatRow: View {
    let habit: Habit
    let streakCalculator: StreakCalculator

    private var streak: StreakCalculator.StreakResult {
        streakCalculator.calculate(for: habit)
    }
    
    private var completionRate: Int {
        let total = habit.completions.count
        guard total > 0 else { return 0 }
        
        // Calculate scheduled days in the past 30 days
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var scheduledDays = 0
        
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: thirtyDaysAgo),
               date <= Date(),
               habit.isScheduled(for: date),
               habit.existedOn(date: date) {
                scheduledDays += 1
            }
        }
        
        guard scheduledDays > 0 else { return 0 }
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let startStr = fmt.string(from: thirtyDaysAgo)
        let endStr = fmt.string(from: Date())
        let completedInPeriod = habit.completions.filter {
            $0.date >= startStr && $0.date <= endStr
        }.count
        
        return min(100, Int((Double(completedInPeriod) / Double(scheduledDays)) * 100))
    }
    
    private var habitColor: Color {
        Color(hex: habit.colorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon with circular background
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: habit.icon)
                    .font(.body)
                    .foregroundStyle(habitColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(habit.schedule.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.accentWarm)
                    Text("\(streak.current)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Text("\(completionRate)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.5))
        )
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
    
    private var habitColor: Color {
        Color(hex: habit.colorHex)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(habitColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(habitColor)
                    }

                    Text(habit.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(habit.schedule.displayText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats
                HStack(spacing: 12) {
                    StatCard(title: "Current Streak", value: "\(streak.current)", icon: "flame.fill")
                    StatCard(title: "Best Streak", value: "\(streak.best)", icon: "trophy.fill")
                    StatCard(title: "Total", value: "\(totalCompletions)", icon: "checkmark.circle.fill")
                }
                .padding(.horizontal)

                // Heatmap
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)

                    InteractiveHeatmapView(
                        data: heatmapData,
                        accentColor: habitColor
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
