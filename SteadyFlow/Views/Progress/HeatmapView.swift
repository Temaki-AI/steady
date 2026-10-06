import SwiftUI

/// Contribution heatmap — months side by side, horizontal scroll.
/// Each month block: header "MMM" + day labels M T W T F S S + week rows.
/// Newest month on the left, oldest on the right.
struct HeatmapView: View {
    let data: [HeatmapDataProvider.DayData]
    var accentColor: Color = DesignSystem.Colors.primaryGreen

    let cellSize: CGFloat = 13
    let cellSpacing: CGFloat = 3

    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    /// Only include days up to and including today
    private var pastData: [HeatmapDataProvider.DayData] {
        let today = Calendar.current.startOfDay(for: Date())
        return data.filter { Calendar.current.startOfDay(for: $0.date) <= today }
    }

    /// Lookup by date string for fast access
    private var lookup: [String: HeatmapDataProvider.DayData] {
        var dict: [String: HeatmapDataProvider.DayData] = [:]
        for day in pastData { dict[day.id] = day }
        return dict
    }

    /// Group weeks by month, newest month first.
    /// Each month: (title, [[DayData?]]) where inner arrays are week rows [Mon..Sun].
    private var monthBlocks: [(title: String, weeks: [[HeatmapDataProvider.DayData?]])] {
        let calendar = Calendar.current
        guard let newestDate = pastData.max(by: { $0.date < $1.date })?.date,
              let oldestDate = pastData.min(by: { $0.date < $1.date })?.date else { return [] }

        let titleFmt = DateFormatter()
        titleFmt.dateFormat = "MMM"

        let lk = lookup

        // Find Monday of the oldest week and Monday of the newest week
        let newestWd = calendar.component(.weekday, from: newestDate)
        let newestFromMon = (newestWd + 5) % 7
        guard let startOfNewestWeek = calendar.date(byAdding: .day, value: -newestFromMon, to: newestDate) else { return [] }

        let oldestWd = calendar.component(.weekday, from: oldestDate)
        let oldestFromMon = (oldestWd + 5) % 7
        guard let startOfOldestWeek = calendar.date(byAdding: .day, value: -oldestFromMon, to: oldestDate) else { return [] }

        // Build all weeks oldest-first
        var allWeeks: [(mondayDate: Date, days: [HeatmapDataProvider.DayData?])] = []
        var weekStart = startOfOldestWeek

        while weekStart <= startOfNewestWeek {
            var week: [HeatmapDataProvider.DayData?] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    week.append(nil)
                    continue
                }
                if date > Date() {
                    week.append(nil)
                } else {
                    week.append(lk[Habit.dateString(from: date)])
                }
            }
            allWeeks.append((weekStart, week))
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = nextWeek
        }

        // Group weeks by month (using the Thursday of each week to determine which month it belongs to)
        var monthMap: [(yearMonth: Int, title: String, weeks: [[HeatmapDataProvider.DayData?]])] = []

        for (mondayDate, week) in allWeeks {
            // Use Thursday (offset 3 from Monday) to determine the month — ISO week convention
            let thursdayDate = calendar.date(byAdding: .day, value: 3, to: mondayDate) ?? mondayDate
            let year = calendar.component(.year, from: thursdayDate)
            let month = calendar.component(.month, from: thursdayDate)
            let yearMonth = year * 100 + month

            if let lastIndex = monthMap.indices.last, monthMap[lastIndex].yearMonth == yearMonth {
                monthMap[lastIndex].weeks.append(week)
            } else {
                let title = titleFmt.string(from: thursdayDate)
                monthMap.append((yearMonth, title, [week]))
            }
        }

        // Reverse so newest month is first (left)
        return monthMap.reversed().map { ($0.title, $0.weeks) }
    }

    private func colorFor(_ day: HeatmapDataProvider.DayData?) -> Color {
        guard let day else { return .clear }
        switch day.intensity {
        case 0: return DesignSystem.Colors.emptyCells
        case 1: return accentColor.opacity(0.25)
        case 2: return accentColor.opacity(0.5)
        case 3: return accentColor.opacity(0.75)
        default: return accentColor
        }
    }

    /// One month block: title + day headers + week rows
    private func monthView(title: String, weeks: [[HeatmapDataProvider.DayData?]]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Month title
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

            // Day headers: M T W T F S S
            HStack(spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayHeaders[i])
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                        .frame(width: cellSize, height: 10)
                }
            }

            // Week rows
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorFor(week[dayIndex]))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(monthBlocks.enumerated()), id: \.offset) { _, block in
                    monthView(title: block.title, weeks: block.weeks)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Range options

enum HeatmapRange: Int, CaseIterable, Identifiable {
    case thirtyDays = 30
    case ninetyDays = 90
    case oneYear = 360

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .thirtyDays: return "30d"
        case .ninetyDays: return "90d"
        case .oneYear: return "1y"
        }
    }
}

/// Interactive heatmap with range toggle
struct InteractiveHeatmapView: View {
    let habits: [Habit]
    var accentColor: Color = DesignSystem.Colors.primaryGreen
    var singleHabit: Habit? = nil

    @State private var selectedRange: HeatmapRange = .thirtyDays
    @State private var heatmapData: [HeatmapDataProvider.DayData] = []
    @State private var isLoading = true

    private let heatmapProvider = HeatmapDataProvider()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Range picker
            HStack {
                Picker("Range", selection: $selectedRange) {
                    ForEach(HeatmapRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer()
            }
            .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .frame(height: 130)
            } else {
                HeatmapView(data: heatmapData, accentColor: accentColor)
                    .frame(height: 150)
            }

            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(level == 0 ? DesignSystem.Colors.emptyCells : accentColor.opacity(0.25 * Double(level)))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedRange) {
            Task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        let days = selectedRange.rawValue

        let data: [HeatmapDataProvider.DayData]
        if let habit = singleHabit {
            data = heatmapProvider.generateHabitHeatmap(habit: habit, days: days)
        } else {
            data = heatmapProvider.generateHeatmap(habits: habits, days: days)
        }

        await MainActor.run {
            heatmapData = data
            isLoading = false
        }
    }
}
