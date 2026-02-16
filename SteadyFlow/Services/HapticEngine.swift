import SwiftUI
import UIKit

/// Steady Flow haptic feedback — smooth, cozy, never jarring.
///
/// Design philosophy: haptics should feel like a gentle nudge from a friend,
/// not a phone vibrating on a table. Every feedback is intentional.
enum HapticEngine {
    
    // MARK: - Pre-warmed Generators (avoid allocation lag)
    
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let selectionFeedback = UISelectionFeedbackGenerator()
    private static let notificationFeedback = UINotificationFeedbackGenerator()
    
    /// Warm up generators on app launch for zero-lag first feedback
    static func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        selectionFeedback.prepare()
    }
    
    // MARK: - Habit Completion ✓
    
    /// The star of the show — checking off a habit.
    /// Soft impact + slight delay + light tap = "settled" feeling.
    static func habitCompleted() {
        softImpact.impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            lightImpact.impactOccurred(intensity: 0.4)
        }
    }
    
    /// Unchecking a habit — gentle, no judgment.
    static func habitUnchecked() {
        softImpact.impactOccurred(intensity: 0.35)
    }
    
    // MARK: - Streaks & Milestones 🔥
    
    /// All habits done for the day — warm celebration pulse.
    static func allComplete() {
        mediumImpact.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightImpact.impactOccurred(intensity: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            softImpact.impactOccurred(intensity: 0.3)
        }
    }
    
    /// Streak milestone (7, 14, 21, 30 days...) — gentle celebration.
    static func streakMilestone() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    // MARK: - Navigation & Selection
    
    /// Scrolling through dates in the date bar.
    static func dateSelection() {
        selectionFeedback.selectionChanged()
    }
    
    /// Tapping a tab or navigation element.
    static func tabTap() {
        lightImpact.impactOccurred(intensity: 0.4)
    }
    
    /// Opening/closing a time group (morning/afternoon/evening).
    static func toggleGroup() {
        softImpact.impactOccurred(intensity: 0.3)
    }
    
    // MARK: - Forms & Editing
    
    /// Saving a new habit or edit — confirmation.
    static func saved() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Deleting something — slight warning feel.
    static func deleted() {
        rigidImpact.impactOccurred(intensity: 0.4)
    }
    
    /// Picking a color in the color picker.
    static func colorPick() {
        selectionFeedback.selectionChanged()
    }
    
    /// Picking an icon.
    static func iconPick() {
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Drag & Reorder
    
    /// Starting to drag a habit for reordering.
    static func dragStart() {
        mediumImpact.impactOccurred(intensity: 0.5)
    }
    
    /// Dropping a habit into its new position.
    static func dragDrop() {
        lightImpact.impactOccurred(intensity: 0.5)
    }
}
