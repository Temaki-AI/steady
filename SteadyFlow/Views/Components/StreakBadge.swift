import SwiftUI

/// Polished streak indicator with warm amber flame
struct StreakBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.accentWarm)
                
                Text("\(count)")
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
        }
    }
}

#Preview {
    VStack {
        StreakBadge(count: 14)
        StreakBadge(count: 0)
        StreakBadge(count: 100)
    }
}
