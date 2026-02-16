import SwiftUI

/// Horizontal scrollable week date picker
struct DateBarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Previous week
            Button {
                withAnimation {
                    selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 44)
            }

            // Week days
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isTodayDate = calendar.isDateInToday(date)
                let isFuture = date > Date()

                Button {
                    HapticEngine.dateSelection()
                    withAnimation(DesignSystem.Animation.respectingMotion(.easeInOut(duration: 0.15)) ?? .easeInOut(duration: 0.15)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayOfWeek(date))
                            .font(.caption2)
                            .fontWeight(.regular)
                            .foregroundStyle(isSelected ? .white : .secondary.opacity(0.7))

                        Text(dayNumber(date))
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .white : (isFuture ? Color.primary.opacity(0.3) : .primary))
                        
                        // Today indicator dot
                        if isTodayDate && !isSelected {
                            Circle()
                                .fill(DesignSystem.Colors.primaryGreen)
                                .frame(width: 4, height: 4)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .frame(minHeight: 64) // Better tap target
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(DesignSystem.Colors.primaryGreen)
                        }
                    }
                }
                .disabled(isFuture)
            }

            // Next week
            Button {
                withAnimation {
                    selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 44)
            }
            // Disable forward past current week
            .disabled(!calendar.isDate(
                calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate,
                equalTo: Date(),
                toGranularity: .weekOfYear
            ) && (calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate) > Date())
        }
        .padding(.horizontal, 8)
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
