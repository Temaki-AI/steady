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
        Color(hex: habit.colorHex) ?? .green
    }

    var body: some View {
        HStack(spacing: 12) {
            CheckCircle(
                isCompleted: isCompleted,
                color: habitColor,
                onToggle: onToggle
            )

            Image(systemName: habit.icon)
                .font(.body)
                .foregroundStyle(isCompleted ? habitColor : .secondary)
                .frame(width: 24)

            Text(habit.name)
                .font(.body)
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted, color: .secondary)
                .lineLimit(1)

            Spacer()

            StreakBadge(count: streak)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .opacity(isScheduled ? 1.0 : 0.5)
        .contentShape(Rectangle())
    }
}

// MARK: - Color from Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
