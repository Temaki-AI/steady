import SwiftUI

/// Polished streak indicator with warm amber flame
struct StreakBadge: View {
    let count: Int
    var unit: StreakCalculator.StreakResult.Unit = .day

    private var spokenUnit: String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        }
    }

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.accentWarm)
                
                Text(StreakCalculator.StreakResult.format(count, unit))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.accentWarm)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.accentWarm.opacity(0.15))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(count) \(spokenUnit) streak")
        }
    }
}

#Preview {
    VStack {
        StreakBadge(count: 14)
        StreakBadge(count: 0)
        StreakBadge(count: 100)
        StreakBadge(count: 3, unit: .week)
    }
}
