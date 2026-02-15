import SwiftUI

/// Subtle streak indicator: 🔥 14
struct StreakBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 2) {
                Text("🔥")
                    .font(.caption2)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
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
