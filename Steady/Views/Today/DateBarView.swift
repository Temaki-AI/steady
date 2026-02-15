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
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayOfWeek(date))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(isSelected ? .primary : .secondary)

                        Text(dayNumber(date))
                            .font(.callout)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? .primary : (isFuture ? .tertiary : .secondary))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay {
                        if isTodayDate && !isSelected {
                            Circle()
                                .fill(.primary)
                                .frame(width: 4, height: 4)
                                .offset(y: 18)
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
