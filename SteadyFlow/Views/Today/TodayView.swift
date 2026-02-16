import SwiftUI
import SwiftData

/// Main tab — shows today's habits grouped by time of day
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.position)
    private var habits: [Habit]

    @State private var selectedDate = Date()
    @State private var showCreateSheet = false
    @State private var showJournalSheet = false
    @State private var streaks: [UUID: Int] = [:]

    private let streakCalculator = StreakCalculator()

    private var habitsByGroup: [TimeOfDay: [Habit]] {
        Dictionary(grouping: habits, by: \.timeOfDay)
    }

    private var todayCompletedCount: Int {
        habits.filter { $0.isCompleted(for: selectedDate) }.count
    }

    private var todayScheduledCount: Int {
        habits.filter { $0.isScheduled(for: selectedDate) && $0.existedOn(date: selectedDate) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Date Bar
                    DateBarView(selectedDate: $selectedDate)
                        .padding(.vertical, 8)

                    Divider()
                        .padding(.horizontal, 16)

                    // Progress summary
                    if todayScheduledCount > 0 {
                        HStack {
                            Text("\(todayCompletedCount)/\(todayScheduledCount) completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // Time-of-day groups
                    ForEach(TimeOfDay.allCases.sorted(), id: \.self) { timeOfDay in
                        let groupHabits = (habitsByGroup[timeOfDay] ?? [])
                            .filter { $0.existedOn(date: selectedDate) }

                        TimeGroupView(
                            timeOfDay: timeOfDay,
                            habits: groupHabits,
                            date: selectedDate,
                            streaks: streaks,
                            onToggle: { habit in
                                toggleHabit(habit)
                            }
                        )
                    }

                    // Empty state
                    if habits.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [DesignSystem.Colors.primaryGreen, DesignSystem.Colors.darkGreen],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.bottom, 8)

                            Text("Add your first habit")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Tap + to start building steady habits")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button {
                                showCreateSheet = true
                            } label: {
                                Text("Add Habit")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(DesignSystem.Colors.primaryGreen)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }
                        .padding(.top, 80)
                    }

                    // Daily note preview
                    DailyNotePreview(date: selectedDate, onTap: { showJournalSheet = true })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    Spacer(minLength: 80)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button("Today") {
                            withAnimation {
                                selectedDate = Date()
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                HabitFormView()
            }
            .sheet(isPresented: $showJournalSheet) {
                DailyNoteSheet(date: selectedDate)
            }
            .onAppear {
                recalculateStreaks()
            }
            .onChange(of: habits.flatMap(\.safeCompletions).count) {
                recalculateStreaks()
            }
        }
    }

    private var navigationTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    private func toggleHabit(_ habit: Habit) {
        let service = HabitService(modelContext: modelContext)
        let wasCompleted = service.toggleCompletion(for: habit, on: selectedDate)
        // Recalculate streak for this habit
        let result = streakCalculator.calculate(for: habit)
        streaks[habit.id] = result.current
        
        // Celebrate when ALL habits for the day are done
        if wasCompleted {
            let dateString = Habit.dateString(from: selectedDate)
            let activeHabits = service.activeHabits()
            let allDone = activeHabits.allSatisfy { h in
                h.safeCompletions.contains { $0.date == dateString }
            }
            if allDone && !activeHabits.isEmpty {
                HapticEngine.allComplete()
            }
        }
    }

    private func recalculateStreaks() {
        // Run on background to keep UI snappy
        Task.detached(priority: .userInitiated) {
            var newStreaks: [UUID: Int] = [:]
            let calc = StreakCalculator()
            for habit in habits {
                newStreaks[habit.id] = calc.calculate(for: habit).current
            }
            await MainActor.run {
                streaks = newStreaks
            }
        }
    }
}

// MARK: - Daily Note Preview

struct DailyNotePreview: View {
    let date: Date
    let onTap: () -> Void

    @Query private var notes: [DailyNote]

    private var noteForDate: DailyNote? {
        let dateString = Habit.dateString(from: date)
        return notes.first { $0.date == dateString }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.body)
                    .foregroundStyle(DesignSystem.Colors.accentWarm)

                if let note = noteForDate, !note.text.isEmpty {
                    Text(note.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                } else {
                    Text("Add a note about today...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.accentWarm.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.accentWarm.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily Note Sheet

struct DailyNoteSheet: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .onChange(of: text) {
                        text = String(text.prefix(500))
                    }

                HStack {
                    Spacer()
                    Text("\(text.count)/500")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Daily Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let service = HabitService(modelContext: modelContext)
                        service.saveDailyNote(text: text, for: date)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let service = HabitService(modelContext: modelContext)
                text = service.dailyNote(for: date)?.text ?? ""
            }
        }
        .presentationDetents([.medium])
    }
}
