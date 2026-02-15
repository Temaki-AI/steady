import SwiftUI
import SwiftData

/// Settings tab
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("endOfDayHour") private var endOfDayHour = 3
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek = 1 // 1 = Sunday
    @AppStorage("accentColorHex") private var accentColorHex = "#81C784"

    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showEraseConfirmation = false
    @State private var showArchivedHabits = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // Branded header
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.primaryGreen, DesignSystem.Colors.darkGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Steady")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                // General
                Section("General") {
                    Stepper("End of day: \(endOfDayHour):00 AM", value: $endOfDayHour, in: 0...5)
                    Picker("Week starts on", selection: $firstDayOfWeek) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                        Text("Saturday").tag(7)
                    }
                }

                // Appearance
                Section("Appearance") {
                    // Accent color picker
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 4), spacing: 10) {
                            ForEach(HabitColor.allCases.prefix(8), id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color.rawValue) ?? .gray)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: color.rawValue == accentColorHex ? 2 : 0)
                                    }
                                    .overlay {
                                        if color.rawValue == accentColorHex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                        }
                                    }
                                    .scaleEffect(color.rawValue == accentColorHex ? 1.1 : 1.0)
                                    .animation(DesignSystem.Animation.respectingMotion(.spring(response: 0.3, dampingFraction: 0.6)), value: accentColorHex)
                                    .onTapGesture {
                                        accentColorHex = color.rawValue
                                    }
                            }
                        }
                        .frame(width: 160)
                    }
                }

                // Data
                Section("Data") {
                    Button("Export as JSON") {
                        exportData(format: .json)
                    }
                    Button("Export as CSV") {
                        exportData(format: .csv)
                    }

                    Button("Erase All Data", role: .destructive) {
                        showEraseConfirmation = true
                    }
                }

                // Sync
                Section("Sync") {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud.fill")
                        Spacer()
                        Text("Automatic")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Archived
                Section {
                    NavigationLink {
                        ArchivedHabitsView()
                    } label: {
                        Label("Archived Habits", systemImage: "archivebox")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/steady-app/steady")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Erase All Data?", isPresented: $showEraseConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Erase Everything", role: .destructive) {
                    eraseAllData()
                }
            } message: {
                Text("This will permanently delete all habits, completions, and notes. This cannot be undone.")
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(url: url)
            }
        }
    }

    private enum ExportFormat { case json, csv }

    private func exportData(format: ExportFormat) {
        let exportService = ExportService()
        let habitsDescriptor = FetchDescriptor<Habit>()
        let notesDescriptor = FetchDescriptor<DailyNote>()
        let habits = (try? modelContext.fetch(habitsDescriptor)) ?? []
        let notes = (try? modelContext.fetch(notesDescriptor)) ?? []

        let data: Data?
        let filename: String

        switch format {
        case .json:
            data = exportService.exportJSON(habits: habits, notes: notes)
            filename = "steady-export-\(Habit.dateString(from: Date())).json"
        case .csv:
            data = exportService.exportCSV(habits: habits, notes: notes)
            filename = "steady-export-\(Habit.dateString(from: Date())).csv"
        }

        guard let data else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        exportURL = tempURL
    }

    private func eraseAllData() {
        try? modelContext.delete(model: Completion.self)
        try? modelContext.delete(model: DailyNote.self)
        try? modelContext.delete(model: Habit.self)
        try? modelContext.save()
    }
}

// MARK: - URL Identifiable conformance for sheet

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Archived Habits View

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \Habit.updatedAt, order: .reverse)
    private var archivedHabits: [Habit]

    var body: some View {
        List {
            if archivedHabits.isEmpty {
                Text("No archived habits")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(archivedHabits) { habit in
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundStyle(Color(hex: habit.colorHex) ?? .gray)
                        Text(habit.name)
                        Spacer()
                        Button("Restore") {
                            let service = HabitService(modelContext: modelContext)
                            service.unarchiveHabit(habit)
                        }
                        .font(.caption)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let service = HabitService(modelContext: modelContext)
                        service.deleteHabit(archivedHabits[index])
                    }
                }
            }
        }
        .navigationTitle("Archived Habits")
    }
}
