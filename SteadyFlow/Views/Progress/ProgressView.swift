import SwiftUI
import SwiftData

/// Progress tab — heatmap, stats, per-habit details
struct SteadyFlowProgressView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.position)
    private var habits: [Habit]

    private let streakCalculator = StreakCalculator()

    private var todayCompleted: Int {
        habits.filter { $0.isScheduled(for: Date()) && $0.isCompleted(for: Date()) }.count
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
            count += habits.filter {
                $0.isScheduled(for: date) && $0.existedOn(date: date) && $0.isCompleted(for: date)
            }.count
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
                    // Title
                    HStack {
                        Text("Progress")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

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

                        InteractiveHeatmapView(habits: habits)
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
                .padding(.bottom)
            }
            .toolbar(.hidden, for: .navigationBar)
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
    
    /// Share of scheduled days completed over the last 30 days (including today)
    private var completionRate: Int {
        let calendar = Calendar.current
        let completed = habit.completedDates
        var scheduledDays = 0
        var completedDays = 0

        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  habit.existedOn(date: date),
                  habit.isScheduled(for: date) else { continue }
            scheduledDays += 1
            if completed.contains(Habit.dateString(from: date)) {
                completedDays += 1
            }
        }

        guard scheduledDays > 0 else { return 0 }
        return Int((Double(completedDays) / Double(scheduledDays)) * 100)
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

    private let streakCalculator = StreakCalculator()

    private var streak: StreakCalculator.StreakResult {
        streakCalculator.calculate(for: habit)
    }

    private var totalCompletions: Int {
        habit.completedDates.count
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
                        habits: [],
                        accentColor: habitColor,
                        singleHabit: habit
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
