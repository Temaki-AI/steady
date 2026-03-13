import SwiftUI

/// Horizontal scrollable week date picker
struct DateBarView: View {
    @Binding var selectedDate: Date
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek = 1

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = firstDayOfWeek
        return cal
    }

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
                goToPreviousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 44)
            }
            .buttonStyle(.borderless)

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
                .buttonStyle(.borderless)
                .disabled(isFuture)
            }

            // Next week
            Button {
                goToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 44)
            }
            .buttonStyle(.borderless)
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right → previous week
                        goToPreviousWeek()
                    } else if value.translation.width < -50 && canGoForward {
                        // Swipe left → next week
                        goToNextWeek()
                    }
                }
        )
    }

    private var canGoForward: Bool {
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        // Allow if next week contains today or is in the past
        return calendar.isDate(nextWeek, equalTo: Date(), toGranularity: .weekOfYear) || nextWeek <= Date()
    }

    private func goToPreviousWeek() {
        HapticEngine.dateSelection()
        withAnimation {
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func goToNextWeek() {
        guard canGoForward else { return }
        HapticEngine.dateSelection()
        withAnimation {
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        }
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
