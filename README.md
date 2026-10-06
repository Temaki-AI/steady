# Steady Flow — Habit Tracker

> *The habit tracker that respects you.*

**Free. No ads. No limits. No accounts. Open source.**

## Quick Start (Xcode)

1. Clone the repo and open `SteadyFlow.xcodeproj` in **Xcode 15+** (iOS 17+ deployment target)
2. Select the **SteadyFlow** and **SteadyFlowWidget** targets → Signing & Capabilities → set your Team
3. Build & Run the **SteadyFlow** scheme (the widget is embedded automatically)

```bash
git clone https://github.com/Temaki-AI/steady.git
```

The project is the source of truth; there is no project generator. Capabilities already
configured in the project:

- **App Group** `group.com.steadyflow.habits` on the app and widget (shared SwiftData store)
- **iCloud / CloudKit** container `iCloud.com.steadyflow.habits`
- **Push Notifications** and **Background Modes → Remote notifications** (CloudKit sync pushes)

### Before releasing

- In the CloudKit Console, **deploy the schema to Production**. TestFlight and App Store
  builds use the Production environment and won't sync until it's deployed.

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
│   ├── NotificationManager.swift # Rolling 7-day reminder scheduling
│   ├── SharedModelContainer.swift # SwiftData store shared with the widget
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
