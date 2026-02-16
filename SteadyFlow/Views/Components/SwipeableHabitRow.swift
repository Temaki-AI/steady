import SwiftUI

/// Habit row with swipe gestures — swipe left to archive, swipe right to edit.
/// Custom implementation because `.swipeActions` only works inside `List`.
struct SwipeableHabitRow: View {
    let habit: Habit
    let date: Date
    let streak: Int
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    
    // Thresholds
    private let editThreshold: CGFloat = 70
    private let archiveThreshold: CGFloat = -70
    private let snapThreshold: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Background actions revealed on swipe
            HStack(spacing: 0) {
                // Edit action (swipe right reveals on left)
                Button {
                    resetOffset()
                    onEdit()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.body.bold())
                        Text("Edit")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: editThreshold)
                    .frame(maxHeight: .infinity)
                    .background(DesignSystem.Colors.primaryGreen)
                }
                
                Spacer()
                
                // Archive action (swipe left reveals on right)
                Button {
                    resetOffset()
                    onArchive()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "archivebox")
                            .font(.body.bold())
                        Text("Archive")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: abs(archiveThreshold))
                    .frame(maxHeight: .infinity)
                    .background(.orange)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            
            // Foreground: the actual habit row
            HabitRowView(
                habit: habit,
                date: date,
                streak: streak,
                onToggle: onToggle
            )
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        let newOffset = lastOffset + value.translation.width
                        // Resistance at edges
                        if newOffset > editThreshold {
                            offset = editThreshold + (newOffset - editThreshold) * 0.2
                        } else if newOffset < archiveThreshold {
                            offset = archiveThreshold + (newOffset - archiveThreshold) * 0.2
                        } else {
                            offset = newOffset
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if offset > snapThreshold || velocity > 200 {
                                // Snapped to edit position
                                offset = editThreshold
                                lastOffset = editThreshold
                                HapticEngine.tabTap()
                            } else if offset < -snapThreshold || velocity < -200 {
                                // Snapped to archive position
                                offset = archiveThreshold
                                lastOffset = archiveThreshold
                                HapticEngine.tabTap()
                            } else {
                                // Snap back
                                offset = 0
                                lastOffset = 0
                            }
                        }
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
    
    private func resetOffset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            lastOffset = 0
        }
    }
}
