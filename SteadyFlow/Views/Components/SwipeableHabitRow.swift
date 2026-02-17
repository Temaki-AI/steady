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
    
    /// Shared across all rows — only one can be open at a time
    @Binding var activeSwipeID: UUID?
    
    @State private var offset: CGFloat = 0
    
    private let actionWidth: CGFloat = 72
    
    private var isActive: Bool { activeSwipeID == habit.id }
    
    var body: some View {
        ZStack(alignment: .center) {
            // TRAILING action: Archive (revealed when swiping LEFT)
            HStack {
                Spacer()
                Button {
                    close()
                    onArchive()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "archivebox.fill")
                            .font(.body)
                        Text("Archive")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                }
                .background(.orange)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .opacity(offset < 0 ? 1 : 0)
            
            // LEADING action: Edit (revealed when swiping RIGHT)
            HStack {
                Button {
                    close()
                    onEdit()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.body)
                        Text("Edit")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                }
                .background(DesignSystem.Colors.primaryGreen)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .opacity(offset > 0 ? 1 : 0)
            
            // Foreground: the actual habit row
            HabitRowView(
                habit: habit,
                date: date,
                streak: streak,
                onToggle: onToggle
            )
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surface)
            )
            .offset(x: offset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Close other open rows
                        if !isActive && activeSwipeID != nil {
                            activeSwipeID = nil
                        }
                        
                        var newOffset = value.translation.width
                        
                        // If already snapped open, add to that position
                        if isActive {
                            newOffset += (offset > 0 ? actionWidth : -actionWidth)
                        }
                        
                        // Rubber-band resistance past thresholds
                        let limit = actionWidth * 1.2
                        if newOffset > limit {
                            newOffset = limit + (newOffset - limit) * 0.15
                        } else if newOffset < -limit {
                            newOffset = -limit + (newOffset + limit) * 0.15
                        }
                        
                        offset = newOffset
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if offset > actionWidth * 0.5 || velocity > 300 {
                                // Snap open: edit
                                offset = actionWidth
                                activeSwipeID = habit.id
                                HapticEngine.tabTap()
                            } else if offset < -actionWidth * 0.5 || velocity < -300 {
                                // Snap open: archive
                                offset = -actionWidth
                                activeSwipeID = habit.id
                                HapticEngine.tabTap()
                            } else {
                                // Snap closed
                                offset = 0
                                if isActive { activeSwipeID = nil }
                            }
                        }
                    }
            )
            // Tap anywhere on the row to close when open
            .onTapGesture {
                if isActive {
                    close()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        // Close when another row becomes active
        .onChange(of: activeSwipeID) { _, newValue in
            if newValue != habit.id && offset != 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
        }
    }
    
    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            activeSwipeID = nil
        }
    }
}
