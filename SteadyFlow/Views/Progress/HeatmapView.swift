import SwiftUI

/// GitHub-style contribution heatmap rendered with Canvas for performance
struct HeatmapView: View {
    let data: [HeatmapDataProvider.DayData]
    var accentColor: Color = DesignSystem.Colors.primaryGreen
    let cellSize: CGFloat = 13
    let cellSpacing: CGFloat = 3
    let labelOffset: CGFloat = 20

    private var weeks: [[HeatmapDataProvider.DayData?]] {
        // Organize data into weeks (7 rows × N columns)
        var result: [[HeatmapDataProvider.DayData?]] = []
        var currentWeek: [HeatmapDataProvider.DayData?] = []
        let calendar = Calendar.current

        for day in data {
            let weekday = calendar.component(.weekday, from: day.date)
            // If this is Sunday (1) and we have data, start new week
            if weekday == 1 && !currentWeek.isEmpty {
                // Pad remaining days
                while currentWeek.count < 7 { currentWeek.append(nil) }
                result.append(currentWeek)
                currentWeek = []
            }
            // Pad leading days
            while currentWeek.count < weekday - 1 { currentWeek.append(nil) }
            currentWeek.append(day)
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 { currentWeek.append(nil) }
            result.append(currentWeek)
        }

        return result
    }
    
    private var monthLabels: [(String, CGFloat)] {
        var labels: [(String, CGFloat)] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        var lastMonth: Int?
        for (weekIndex, week) in weeks.enumerated() {
            if let firstDay = week.first(where: { $0 != nil }), let day = firstDay {
                let month = calendar.component(.month, from: day.date)
                if month != lastMonth {
                    let x = CGFloat(weekIndex) * (cellSize + cellSpacing)
                    labels.append((dateFormatter.string(from: day.date), x))
                    lastMonth = month
                }
            }
        }
        
        return labels
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                // Month labels
                ZStack(alignment: .leading) {
                    ForEach(Array(monthLabels.enumerated()), id: \.offset) { _, label in
                        Text(label.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .offset(x: labelOffset + label.1)
                    }
                }
                .frame(height: 16)
                
                HStack(spacing: 0) {
                    // Day of week labels (M, W, F)
                    VStack(alignment: .trailing, spacing: cellSpacing) {
                        Text("M")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(height: cellSize)
                        Text("")
                            .frame(height: cellSize)
                        Text("W")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(height: cellSize)
                        Text("")
                            .frame(height: cellSize)
                        Text("F")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(height: cellSize)
                        Text("")
                            .frame(height: cellSize)
                        Text("")
                            .frame(height: cellSize)
                    }
                    .frame(width: labelOffset)
                    
                    // Heatmap cells
                    Canvas { context, size in
                        for (weekIndex, week) in weeks.enumerated() {
                            for (dayIndex, day) in week.enumerated() {
                                let x = CGFloat(weekIndex) * (cellSize + cellSpacing)
                                let y = CGFloat(dayIndex) * (cellSize + cellSpacing)
                                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                                let path = RoundedRectangle(cornerRadius: 3).path(in: rect)

                                let color: Color
                                if let day {
                                    // 4 intensity levels: 25% → 50% → 75% → 100%
                                    switch day.intensity {
                                    case 0: color = DesignSystem.Colors.emptyCells
                                    case 1: color = accentColor.opacity(0.25)
                                    case 2: color = accentColor.opacity(0.5)
                                    case 3: color = accentColor.opacity(0.75)
                                    default: color = accentColor
                                    }
                                } else {
                                    color = .clear
                                }

                                context.fill(path, with: .color(color))
                            }
                        }
                    }
                    .frame(
                        width: CGFloat(weeks.count) * (cellSize + cellSpacing),
                        height: 7 * (cellSize + cellSpacing)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Interactive heatmap with tooltip on tap
struct InteractiveHeatmapView: View {
    let data: [HeatmapDataProvider.DayData]
    var accentColor: Color = DesignSystem.Colors.primaryGreen
    @State private var selectedDay: HeatmapDataProvider.DayData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tooltip
            if let day = selectedDay {
                Text("\(formattedDate(day.date)) — \(day.completedCount)/\(day.totalScheduled) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            HeatmapView(data: data, accentColor: accentColor)

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
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
