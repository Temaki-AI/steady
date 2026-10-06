import SwiftUI

/// Animated check-off circle with haptic feedback
/// Shows the habit icon when unchecked, checkmark when completed.
/// Performance: must respond in < 16ms (single frame)
struct CheckCircle: View {
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    let icon: String
    /// Spoken by VoiceOver, e.g. the habit name
    let accessibilityName: String
    let onToggle: () -> Void

    @State private var bounceScale: CGFloat = 1.0

    init(
        isCompleted: Bool,
        color: Color = .green,
        size: CGFloat = 36,
        icon: String = "checkmark",
        accessibilityName: String = "Habit",
        onToggle: @escaping () -> Void
    ) {
        self.isCompleted = isCompleted
        self.color = color
        self.size = size
        self.icon = icon
        self.accessibilityName = accessibilityName
        self.onToggle = onToggle
    }

    var body: some View {
        Button {
            // Haptic first — feels instant
            if !isCompleted {
                HapticEngine.habitCompleted()
            } else {
                HapticEngine.habitUnchecked()
            }

            // Bounce animation on check
            if !isCompleted {
                withAnimation(DesignSystem.Animation.respectingMotion(.spring(response: 0.3, dampingFraction: 0.5))) {
                    bounceScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(DesignSystem.Animation.respectingMotion(.spring(response: 0.3, dampingFraction: 0.7))) {
                        bounceScale = 1.0
                    }
                }
            }

            onToggle()
        } label: {
            ZStack {
                if isCompleted {
                    // Checked: solid fill with checkmark
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .scaleEffect(bounceScale)

                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(bounceScale)
                } else {
                    // Unchecked: dashed outline with habit icon
                    Circle()
                        .strokeBorder(color.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: size, height: size)

                    Image(systemName: icon)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(color.opacity(0.6))
                }
            }
            .animation(DesignSystem.Animation.respectingMotion(.spring(response: 0.2, dampingFraction: 0.7)), value: isCompleted)
        }
        .buttonStyle(.plain)
        .frame(width: max(44, size), height: max(44, size)) // Min 44pt tap target
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(isCompleted ? "Double-tap to mark as not done" : "Double-tap to mark as done")
    }
}

#Preview {
    VStack(spacing: 20) {
        CheckCircle(isCompleted: false, color: .green, icon: "figure.run") {}
        CheckCircle(isCompleted: true, color: .blue, icon: "book.fill") {}
        CheckCircle(isCompleted: false, color: .orange, icon: "drop.fill") {}
    }
}
