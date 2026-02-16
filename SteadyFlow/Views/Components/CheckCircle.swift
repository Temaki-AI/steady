import SwiftUI

/// Animated check-off circle with haptic feedback
/// Performance: must respond in < 16ms (single frame)
struct CheckCircle: View {
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    let onToggle: () -> Void
    
    @State private var bounceScale: CGFloat = 1.0

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
    
    // Desaturate color for unchecked border
    private var desaturatedColor: Color {
        color.opacity(0.4)
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
                // Unchecked: dashed border, inviting
                if !isCompleted {
                    Circle()
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [4, 3]
                            )
                        )
                        .foregroundColor(desaturatedColor)
                        .frame(width: size, height: size)
                }

                // Checked: solid fill with bounce
                if isCompleted {
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .scaleEffect(bounceScale)

                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(bounceScale)
                }
            }
            .animation(DesignSystem.Animation.respectingMotion(.spring(response: 0.2, dampingFraction: 0.7)), value: isCompleted)
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
