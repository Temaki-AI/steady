# Steady Flow — Habit Tracker

> *The habit tracker that respects you.*

**Free. No ads. No limits. No accounts. Open source.**

## Quick Start (Xcode)

### Option 1: Create Xcode Project (Recommended)

1. Open **Xcode 15+**
2. File → New → Project → **iOS App**
3. Product Name: `SteadyFlow`
4. Bundle Identifier: `com.steadyflow.habits`
5. Interface: **SwiftUI**
6. Storage: **SwiftData**
7. Check: **Include Widget Extension**
8. Minimum Deployment: **iOS 17.0**
9. Delete the auto-generated files (ContentView.swift, Item.swift, etc.)
10. Drag the `SteadyFlow/` folder into the project navigator
11. Drag the `SteadyFlowWidget/` folder into the widget extension target
12. Build & Run

### Option 2: Clone and Open

```bash
git clone https://github.com/Temaki-AI/steady.git
cd steady
# Then follow Option 1 steps 2-12 above
```

### Required Xcode Configuration

1. **App Group**: Add `group.com.steadyflow.habits` to both app and widget targets
2. **CloudKit**: Enable iCloud capability → check CloudKit → container: `iCloud.com.steadyflow.habits`
3. **Push Notifications**: Enable for background refresh (notifications)
4. **Background Modes**: Enable Background Fetch

## Architecture

```
SteadyFlow/
├── SteadyFlowApp.swift          # App entry + SwiftData container
├── Models/
│   ├── Habit.swift               # Core habit model
│   ├── Completion.swift          # Date-based completions
│   ├── DailyNote.swift           # One note per day
│   └── HabitSchedule.swift       # Flexible scheduling enum
├── Views/
│   ├── Today/                    # Main tab
│   ├── Progress/                 # Stats + heatmap
│   ├── Settings/                 # Export, appearance, archive
│   ├── Shared/                   # Create/edit forms
│   ├── Components/               # Reusable UI (CheckCircle, StreakBadge)
│   └── DesignSystem.swift        # Design tokens
├── Services/
│   ├── HabitService.swift        # Business logic
│   ├── StreakCalculator.swift    # Streak computation
│   ├── HeatmapDataProvider.swift # Contribution graph data
│   ├── NotificationManager.swift # Smart notification scheduling
│   └── ExportService.swift       # JSON/CSV export
SteadyFlowWidget/
└── SteadyFlowWidget.swift        # Home screen widgets
```

## Tech Stack

- **SwiftUI** + **SwiftData** + **CloudKit**
- iOS 17+ (for interactive widgets, @Observable)
- Zero external dependencies
- Zero analytics / telemetry

## License

GPLv3
