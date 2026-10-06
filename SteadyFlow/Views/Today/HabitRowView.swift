import SwiftUI

/// Single habit row — the most tapped element in the app
struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let streak: Int
    let onToggle: () -> Void

    private var isCompleted: Bool {
        habit.isCompleted(for: date)
    }

    private var isScheduled: Bool {
        habit.isScheduled(for: date)
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

            Text(habit.name)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            StreakBadge(count: streak)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.5))
        )
        .opacity(isCompleted ? 0.6 : (isScheduled ? 1.0 : 0.5))
        .contentShape(Rectangle())
    }
}

// Color(hex:) is defined in DesignSystem.swift
