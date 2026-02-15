import SwiftUI

/// GitHub-style contribution heatmap rendered with Canvas for performance
struct HeatmapView: View {
    let data: [HeatmapDataProvider.DayData]
    var accentColor: Color = Color(hex: "#81C784") ?? .green
    let cellSize: CGFloat = 12
    let cellSpacing: CGFloat = 2

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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Canvas { context, size in
                for (weekIndex, week) in weeks.enumerated() {
                    for (dayIndex, day) in week.enumerated() {
                        let x = CGFloat(weekIndex) * (cellSize + cellSpacing)
                        let y = CGFloat(dayIndex) * (cellSize + cellSpacing)
                        let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                        let path = RoundedRectangle(cornerRadius: 2).path(in: rect)

                        let color: Color
                        if let day {
                            switch day.intensity {
                            case 0: color = .secondary.opacity(0.1)
                            case 1: color = accentColor.opacity(0.3)
                            case 2: color = accentColor.opacity(0.6)
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
            .padding(.horizontal)
        }
    }
}

/// Interactive heatmap with tooltip on tap
struct InteractiveHeatmapView: View {
    let data: [HeatmapDataProvider.DayData]
    var accentColor: Color = Color(hex: "#81C784") ?? .green
    @State private var selectedDay: HeatmapDataProvider.DayData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tooltip
            if let day = selectedDay {
                Text("\(formattedDate(day.date)) — \(day.completedCount)/\(day.totalScheduled) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            HeatmapView(data: data, accentColor: accentColor)

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level == 0 ? Color.secondary.opacity(0.1) : accentColor.opacity(Double(level) / 3.0))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
