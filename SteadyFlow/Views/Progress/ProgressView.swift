import SwiftUI
import SwiftData

/// Progress tab — heatmap, stats, per-habit details
struct SteadyFlowProgressView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.position)
    private var habits: [Habit]

    private let streakCalculator = StreakCalculator()

    private var todayCompleted: Int {
        habits.filter { $0.isDue(on: Date()) && $0.isCompleted(for: Date()) }.count
    }

    private var todayScheduled: Int {
        habits.filter { $0.isDue(on: Date()) }.count
    }

    /// This week's (completed, due). Fixed-day habits count each due day so far;
    /// weekly targets count their target once; monthly targets are left out.
    private var weekProgress: (completed: Int, due: Int) {
        let calendar = Habit.periodCalendar
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return (0, 0) }
        var completed = 0
        var due = 0

        for habit in habits {
            if let target = habit.schedule.periodTarget {
                guard target.period == .week else { continue }
                completed += min(habit.completedDays(in: week), target.count)
                due += target.count
                continue
            }
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: week.start),
                      date <= Date(),
                      habit.existedOn(date: date),
                      habit.isScheduled(for: date) else { continue }
                due += 1
                if habit.isCompleted(for: date) { completed += 1 }
            }
        }
        return (completed, due)
    }

    /// Longest best streak across habits, shown with its unit (days, weeks or months)
    private var bestStreakOverall: String {
        habits.map { streakCalculator.calculate(for: $0) }
            .max { $0.best < $1.best }?
            .bestText ?? "0"
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
                        StatCard(title: "This Week", value: "\(weekProgress.completed)/\(weekProgress.due)", icon: "calendar")
                        StatCard(title: "Best Streak", value: bestStreakOverall, icon: "flame.fill")
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

                        ForEach(habits.sorted(by: Habit.displayOrder)) { habit in
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
    
    /// Share of scheduled days completed over the last 30 days (including today).
    /// "Times per" habits are measured against their target instead.
    private var completionRate: Int {
        if let target = habit.schedule.periodTarget {
            return targetCompletionRate(target)
        }

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

    /// Target met over the last 4 finished weeks (or 3 months), capped per period.
    /// A habit too new to have a finished period is measured on the current one.
    private func targetCompletionRate(_ target: (period: TargetPeriod, count: Int)) -> Int {
        let calendar = Habit.periodCalendar
        let component = target.period.calendarComponent
        let lookback = target.period == .week ? 4 : 3
        guard let current = calendar.dateInterval(of: component, for: Date()) else { return 0 }
        let createdStart = calendar.startOfDay(for: habit.createdAt)

        var periods: [DateInterval] = []
        var cursor = current.start
        while periods.count < lookback,
              let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor),
              let period = calendar.dateInterval(of: component, for: previousDay),
              period.end > createdStart {
            periods.append(period)
            cursor = period.start
        }
        if periods.isEmpty { periods = [current] }

        let done = periods.reduce(0) { $0 + min(habit.completedDays(in: $1), target.count) }
        return Int(Double(done) / Double(periods.count * target.count) * 100)
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
                    Text(streak.currentText)
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
                    StatCard(title: "Current Streak", value: streak.currentText, icon: "flame.fill")
                    StatCard(title: "Best Streak", value: streak.bestText, icon: "trophy.fill")
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
