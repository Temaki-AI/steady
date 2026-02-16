//
//  ScreenshotPreviews.swift
//  Steady Flow
//
//  Demo-ready preview screens for App Store screenshots.
//  These use static data — no SwiftData dependency.
//

import SwiftUI

// MARK: - 1. Today View (Light Mode) — Morning habits partially done

struct ScreenshotTodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Date bar
                    ScreenshotDateBar()
                        .padding(.vertical, 8)
                    
                    Divider().padding(.horizontal, 16)
                    
                    // Progress
                    HStack {
                        Text("5/8 completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Morning group — 2/3 done
                    ScreenshotTimeGroup(
                        icon: "sun.max.fill",
                        title: "Morning",
                        completed: 2,
                        total: 3,
                        habits: [
                            .init(name: "Meditate", icon: "brain.head.profile", color: "#7986CB", done: true, streak: 14),
                            .init(name: "Exercise", icon: "figure.run", color: "#4DB6AC", done: true, streak: 7),
                            .init(name: "Journal", icon: "book.fill", color: "#FFB74D", done: false, streak: 3),
                        ]
                    )
                    
                    // Afternoon group — 2/3 done
                    ScreenshotTimeGroup(
                        icon: "sun.haze.fill",
                        title: "Afternoon",
                        completed: 2,
                        total: 3,
                        habits: [
                            .init(name: "Read 30 min", icon: "book.closed.fill", color: "#64B5F6", done: true, streak: 21),
                            .init(name: "Deep work block", icon: "laptopcomputer", color: "#BA68C8", done: false, streak: 0),
                            .init(name: "Drink 2L water", icon: "drop.fill", color: "#4DB6AC", done: true, streak: 9),
                        ]
                    )
                    
                    // Evening group — 1/2 done
                    ScreenshotTimeGroup(
                        icon: "moon.stars.fill",
                        title: "Evening",
                        completed: 1,
                        total: 2,
                        habits: [
                            .init(name: "No phone after 9", icon: "iphone.slash", color: "#81C784", done: true, streak: 45),
                            .init(name: "Stretch", icon: "figure.flexibility", color: "#F06292", done: false, streak: 5),
                        ]
                    )
                    
                    // Daily note
                    HStack(spacing: 8) {
                        Text("📝")
                            .font(.caption)
                        Text("Had a great workout this morning...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(12)
                    .background(DesignSystem.Colors.surface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .strokeBorder(DesignSystem.Colors.accentWarm.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primaryGreen)
                }
            }
        }
        .tint(DesignSystem.Colors.primaryGreen)
    }
}

// MARK: - 2. Heatmap / Progress (Dark Mode)

struct ScreenshotProgressView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxxl) {
                    // Summary cards
                    HStack(spacing: 12) {
                        ScreenshotStatCard(title: "Today", value: "5/8", icon: "checkmark.circle", gradient: [.green.opacity(0.15), .green.opacity(0.05)])
                        ScreenshotStatCard(title: "This Week", value: "32/48", icon: "calendar", gradient: [.blue.opacity(0.15), .blue.opacity(0.05)])
                        ScreenshotStatCard(title: "Best Streak", value: "45", icon: "flame.fill", gradient: [DesignSystem.Colors.accentWarm.opacity(0.15), DesignSystem.Colors.accentWarm.opacity(0.05)])
                    }
                    .padding(.horizontal)
                    
                    // Heatmap
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contribution Graph")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScreenshotHeatmap()
                    }
                    
                    // Per-habit stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Habits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScreenshotHabitStatRow(name: "Meditate", icon: "brain.head.profile", color: "#7986CB", streak: 14, best: 28, rate: 82)
                        ScreenshotHabitStatRow(name: "Exercise", icon: "figure.run", color: "#4DB6AC", streak: 7, best: 21, rate: 71)
                        ScreenshotHabitStatRow(name: "Read 30 min", icon: "book.closed.fill", color: "#64B5F6", streak: 21, best: 21, rate: 90)
                        ScreenshotHabitStatRow(name: "No phone after 9", icon: "iphone.slash", color: "#81C784", streak: 45, best: 45, rate: 95)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
        .tint(DesignSystem.Colors.primaryGreen)
        .preferredColorScheme(.dark)
    }
}

// MARK: - 3. Widget Preview

struct ScreenshotWidgetView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Small widget
            ScreenshotSmallWidget()
                .frame(width: 170, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            
            // Medium widget
            ScreenshotMediumWidget()
                .frame(width: 364, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(32)
        .background(Color(hex: "F2F2F7"))
    }
}

// MARK: - 4. Create Habit Sheet

struct ScreenshotCreateHabit: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4DB6AC").opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "figure.run")
                                .font(.title3)
                                .foregroundStyle(Color(hex: "4DB6AC"))
                        }
                        
                        TextField("Habit name", text: .constant("Morning Run"))
                            .font(.body)
                    }
                }
                
                Section("Schedule") {
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text("Every day")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Time of day")
                        Spacer()
                        Text("Morning")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Reminder") {
                    HStack {
                        Text("Remind me at")
                        Spacer()
                        Text("7:00 AM")
                            .foregroundStyle(DesignSystem.Colors.primaryGreen)
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 6), spacing: 12) {
                        ForEach(HabitColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color.rawValue))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if color == .teal {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Cancel")
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primaryGreen)
                }
            }
        }
        .tint(DesignSystem.Colors.primaryGreen)
    }
}

// MARK: - Supporting Components

struct ScreenshotDateBar: View {
    private let days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    private let numbers = ["10", "11", "12", "13", "14", "15", "16"]
    private let todayIndex = 3 // Thursday
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "chevron.left")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 44)
            
            ForEach(0..<7, id: \.self) { i in
                let isSelected = i == todayIndex
                
                VStack(spacing: 4) {
                    Text(days[i])
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : .secondary)
                    
                    Text(numbers[i])
                        .font(.callout)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignSystem.Colors.primaryGreen)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 44)
        }
        .padding(.horizontal, 8)
    }
}

struct DemoHabit: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    let done: Bool
    let streak: Int
}

struct ScreenshotTimeGroup: View {
    let icon: String
    let title: String
    let completed: Int
    let total: Int
    let habits: [DemoHabit]
    
    private var allDone: Bool { completed == total }
    private var progress: CGFloat { total > 0 ? CGFloat(completed) / CGFloat(total) : 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(allDone ? (DesignSystem.Colors.primaryGreen) : .secondary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(allDone ? (DesignSystem.Colors.primaryGreen) : .secondary)
                
                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 4)
                        Capsule()
                            .fill(DesignSystem.Colors.primaryGreen)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(width: 48, height: 4)
                
                if allDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.primaryGreen)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(allDone ? (DesignSystem.Colors.primaryGreen).opacity(0.05) : .clear)
            
            // Habits
            ForEach(habits) { habit in
                ScreenshotHabitRow(habit: habit)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct ScreenshotHabitRow: View {
    let habit: DemoHabit
    
    private var habitColor: Color {
        Color(hex: habit.color)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Check circle
            ZStack {
                if habit.done {
                    Circle()
                        .fill(habitColor)
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(habitColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        .frame(width: 28, height: 28)
                }
            }
            .frame(width: 44, height: 44)
            
            // Icon badge
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: habit.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(habit.done ? habitColor : .secondary)
            }
            
            Text(habit.name)
                .font(.body)
                .foregroundStyle(habit.done ? .secondary : .primary)
                .opacity(habit.done ? 0.6 : 1)
                .lineLimit(1)
            
            Spacer()
            
            // Streak
            if habit.streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(DesignSystem.Colors.accentWarm)
                    Text("\(habit.streak)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignSystem.Colors.accentWarm.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

struct ScreenshotStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
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
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct ScreenshotHeatmap: View {
    let cellSize: CGFloat = 13
    let cellSpacing: CGFloat = 3
    
    // Generate realistic-looking heatmap data
    private var weeks: [[Int]] {
        var result: [[Int]] = []
        for week in 0..<26 {
            var days: [Int] = []
            for day in 0..<7 {
                // More consistent recent weeks, sparser older weeks
                let recency = Double(week) / 26.0
                let base = 0.3 + recency * 0.5
                let rand = Double.random(in: 0...1)
                let level: Int
                if rand > base { level = 0 }
                else if rand > base * 0.6 { level = 1 }
                else if rand > base * 0.3 { level = 2 }
                else { level = 3 }
                days.append(level)
            }
            result.append(days)
        }
        return result
    }
    
    private let months = ["Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb"]
    private let dayLabels = ["M", "", "W", "", "F", "", ""]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month labels
            HStack(spacing: 0) {
                // Spacer for day labels
                Color.clear.frame(width: 20)
                
                ForEach(0..<months.count, id: \.self) { i in
                    Text(months[i])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    if i < months.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 0) {
                // Day labels
                VStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(dayLabels[day])
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: cellSize + cellSpacing)
                    }
                }
                
                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    Canvas { context, size in
                        let accentColor = DesignSystem.Colors.primaryGreen
                        
                        for (weekIndex, week) in weeks.enumerated() {
                            for (dayIndex, level) in week.enumerated() {
                                let x = CGFloat(weekIndex) * (cellSize + cellSpacing)
                                let y = CGFloat(dayIndex) * (cellSize + cellSpacing)
                                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                                let path = RoundedRectangle(cornerRadius: 3).path(in: rect)
                                
                                let color: Color
                                switch level {
                                case 0: color = DesignSystem.Colors.emptyCells
                                case 1: color = accentColor.opacity(0.3)
                                case 2: color = accentColor.opacity(0.6)
                                default: color = accentColor
                                }
                                
                                context.fill(path, with: .color(color))
                            }
                        }
                    }
                    .frame(
                        width: CGFloat(weeks.count) * (cellSize + cellSpacing),
                        height: 7 * (cellSize + cellSpacing)
                    )
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal)
            
            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level == 0 ? (DesignSystem.Colors.emptyCells) : (DesignSystem.Colors.primaryGreen).opacity(Double(level) / 3.0))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
    }
}

struct ScreenshotHabitStatRow: View {
    let name: String
    let icon: String
    let color: String
    let streak: Int
    let best: Int
    let rate: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color(hex: color))
                .frame(width: 32, height: 32)
                .background(Color(hex: color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Daily")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(rate)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(DesignSystem.Colors.accentWarm)
                    Text("\(streak)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("Best: \(best)")
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

// MARK: - Widget Previews

struct ScreenshotSmallWidget: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: 0.625)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primaryGreen, DesignSystem.Colors.lightGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("5/8")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 72, height: 72)
            
            Text("Today")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FAFAF7"))
    }
}

struct ScreenshotMediumWidget: View {
    let habits: [(String, String, String, Bool)] = [
        ("Meditate", "brain.head.profile", "#7986CB", true),
        ("Exercise", "figure.run", "#4DB6AC", true),
        ("Journal", "book.fill", "#FFB74D", false),
        ("Read 30 min", "book.closed.fill", "#64B5F6", false),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Text("5/8")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            
            ForEach(0..<habits.count, id: \.self) { i in
                let h = habits[i]
                HStack(spacing: 8) {
                    Image(systemName: h.3 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(h.3 ? Color(hex: h.2) : .secondary)
                    Image(systemName: h.1)
                        .font(.caption)
                        .foregroundStyle(Color(hex: h.2))
                    Text(h.0)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(hex: "FAFAF7"))
    }
}

// MARK: - Previews

#Preview("1 — Today (Light)") {
    ScreenshotTodayView()
}

#Preview("2 — Progress (Dark)") {
    ScreenshotProgressView()
}

#Preview("3 — Widgets") {
    ScreenshotWidgetView()
}

#Preview("4 — Create Habit") {
    ScreenshotCreateHabit()
}

#Preview("5 — Progress Stats (Light)") {
    ScreenshotProgressView()
        .preferredColorScheme(.light)
}
