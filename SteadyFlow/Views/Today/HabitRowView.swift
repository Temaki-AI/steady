import SwiftUI

/// Single habit row — the most tapped element in the app
struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let streak: StreakCalculator.StreakResult?
    let onToggle: () -> Void

    private var isCompleted: Bool {
        habit.isCompleted(for: date)
    }

    private var isDue: Bool {
        habit.isDue(on: date)
    }

    private var habitColor: Color {
        Color(hex: habit.colorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            CheckCircle(
                isCompleted: isCompleted,
                color: habitColor,
                icon: habit.icon,
                accessibilityName: habit.name,
                onToggle: onToggle
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // "Times per" habits show where they stand, e.g. "2/3 this week"
                if let progress = habit.periodProgress(for: date) {
                    Text("\(progress.done)/\(progress.target) this \(progress.period.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            StreakBadge(count: streak?.current ?? 0, unit: streak?.unit ?? .day)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.5))
        )
        .opacity(isCompleted ? 0.6 : (isDue ? 1.0 : 0.5))
        .contentShape(Rectangle())
    }
}

// Color(hex:) is defined in DesignSystem.swift
