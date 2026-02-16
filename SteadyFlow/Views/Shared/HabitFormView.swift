import SwiftUI
import SwiftData

/// Create/edit habit sheet
struct HabitFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingHabit: Habit?

    @State private var name: String = ""
    @State private var icon: String = "circle.fill"
    @State private var color: HabitColor = .green
    @State private var schedule: HabitSchedule = .daily
    @State private var timeOfDay: TimeOfDay = .anytime
    @State private var reminders: [ReminderTime] = []
    @State private var showIconPicker = false

    // Schedule-specific state
    @State private var selectedDays: Set<Weekday> = []
    @State private var timesPerWeek: Int = 3
    @State private var timesPerMonth: Int = 10
    @State private var intervalDays: Int = 2
    @State private var scheduleType: ScheduleType = .daily

    enum ScheduleType: String, CaseIterable {
        case daily = "Every Day"
        case specificDays = "Specific Days"
        case timesPerWeek = "Times per Week"
        case timesPerMonth = "Times per Month"
        case interval = "Every X Days"
    }

    private var isEditing: Bool { editingHabit != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("Name") {
                    TextField("Habit name", text: $name)
                        .onChange(of: name) { name = String(name.prefix(50)) }
                }

                // Icon & Color
                Section("Appearance") {
                    HStack {
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: color.rawValue))
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: color.rawValue).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Text("Choose Icon")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    // Color palette
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(HabitColor.allCases, id: \.self) { c in
                            Circle()
                                .fill(Color(hex: c.rawValue))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if c == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { HapticEngine.colorPick(); color = c }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Schedule
                Section("Schedule") {
                    Picker("Frequency", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    switch scheduleType {
                    case .daily:
                        EmptyView()
                    case .specificDays:
                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                let isSelected = selectedDays.contains(day)
                                Text(String(day.shortName.prefix(1)))
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background(isSelected ? (Color(hex: color.rawValue)) : Color.secondary.opacity(0.15))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        if isSelected { selectedDays.remove(day) }
                                        else { selectedDays.insert(day) }
                                    }
                            }
                        }
                    case .timesPerWeek:
                        Stepper("**\(timesPerWeek)** times per week", value: $timesPerWeek, in: 1...7)
                    case .timesPerMonth:
                        Stepper("**\(timesPerMonth)** times per month", value: $timesPerMonth, in: 1...31)
                    case .interval:
                        Stepper("Every **\(intervalDays)** days", value: $intervalDays, in: 2...90)
                    }
                }

                // Time of Day
                Section("Time of Day") {
                    Picker("When", selection: $timeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { tod in
                            Label(tod.displayName, systemImage: tod.icon).tag(tod)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Reminders (simplified for MVP)
                Section("Reminder") {
                    if reminders.isEmpty {
                        Button("Add Reminder") {
                            reminders.append(ReminderTime(hour: 9, minute: 0))
                        }
                    } else {
                        ForEach(reminders.indices, id: \.self) { index in
                            HStack {
                                DatePicker(
                                    "Time",
                                    selection: Binding(
                                        get: {
                                            Calendar.current.date(from: DateComponents(
                                                hour: reminders[index].hour,
                                                minute: reminders[index].minute
                                            )) ?? Date()
                                        },
                                        set: { newDate in
                                            reminders[index].hour = Calendar.current.component(.hour, from: newDate)
                                            reminders[index].minute = Calendar.current.component(.minute, from: newDate)
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )

                                Button(role: .destructive) {
                                    reminders.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                            }
                        }

                        if reminders.count < 3 {
                            Button("Add Another") {
                                reminders.append(ReminderTime(hour: 9, minute: 0))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
            .onAppear { loadEditingHabit() }
        }
    }

    private func computedSchedule() -> HabitSchedule {
        switch scheduleType {
        case .daily: return .daily
        case .specificDays: return .specificDays(selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays)
        case .timesPerWeek: return .timesPerWeek(timesPerWeek)
        case .timesPerMonth: return .timesPerMonth(timesPerMonth)
        case .interval: return .interval(days: intervalDays)
        }
    }

    private func save() {
        let service = HabitService(modelContext: modelContext)

        if let habit = editingHabit {
            habit.name = String(name.prefix(50))
            habit.icon = icon
            habit.color = color
            habit.schedule = computedSchedule()
            habit.timeOfDay = timeOfDay
            habit.reminders = reminders
            service.updateHabit(habit)
        } else {
            service.createHabit(
                name: name,
                icon: icon,
                color: color,
                schedule: computedSchedule(),
                timeOfDay: timeOfDay,
                reminders: reminders
            )
        }

        HapticEngine.saved()
        dismiss()
    }

    private func loadEditingHabit() {
        guard let habit = editingHabit else { return }
        name = habit.name
        icon = habit.icon
        color = habit.color
        timeOfDay = habit.timeOfDay
        reminders = habit.reminders

        switch habit.schedule {
        case .daily:
            scheduleType = .daily
        case .specificDays(let days):
            scheduleType = .specificDays
            selectedDays = days
        case .timesPerWeek(let count):
            scheduleType = .timesPerWeek
            timesPerWeek = count
        case .timesPerMonth(let count):
            scheduleType = .timesPerMonth
            timesPerMonth = count
        case .interval(let days):
            scheduleType = .interval
            intervalDays = days
        }
    }
}
