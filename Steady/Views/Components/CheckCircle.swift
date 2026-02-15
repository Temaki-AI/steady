import SwiftUI

/// Animated check-off circle with haptic feedback
/// Performance: must respond in < 16ms (single frame)
struct CheckCircle: View {
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    let onToggle: () -> Void

    init(
        isCompleted: Bool,
        color: Color = .green,
        size: CGFloat = 28,
        onToggle: @escaping () -> Void
    ) {
        self.isCompleted = isCompleted
        self.color = color
        self.size = size
        self.onToggle = onToggle
    }

    var body: some View {
        Button {
            // Haptic first — feels instant
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onToggle()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(isCompleted ? color : Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: size, height: size)

                if isCompleted {
                    Circle()
                        .fill(color)
                        .frame(width: size - 4, height: size - 4)
                        .transition(.scale.combined(with: .opacity))

                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale)
                }
            }
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isCompleted)
        }
        .buttonStyle(.plain)
        .frame(width: max(44, size), height: max(44, size)) // Min 44pt tap target
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 20) {
        CheckCircle(isCompleted: false, color: .green) {}
        CheckCircle(isCompleted: true, color: .blue) {}
        CheckCircle(isCompleted: true, color: .orange, size: 36) {}
    }
}
