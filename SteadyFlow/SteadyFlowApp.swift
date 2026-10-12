import SwiftUI
import SwiftData

@main
struct SteadyFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.makeAppContainer()
        } catch {
            // Fall back to an in-memory store so the app still opens,
            // and tell the user nothing will be saved (see ContentView)
            print("⚠️ Persistent store failed: \(error). Using in-memory store.")
            SharedModelContainer.isUsingTemporaryStore = true
            let fallback = ModelConfiguration(
                schema: SharedModelContainer.schema,
                isStoredInMemoryOnly: true
            )
            return try! ModelContainer(
                for: SharedModelContainer.schema,
                configurations: [fallback]
            )
        }
    }()
    
    init() {
        // Pre-warm haptic engines for zero-lag first feedback
        HapticEngine.prepare()
        
        // Configure tab bar appearance with warm, earthy tones
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(Color(light: "FAFAF7", dark: "1C1C1E"))
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showStorageAlert = SharedModelContainer.isUsingTemporaryStore
    @AppStorage("accentColorHex") private var accentColorHex = "#81C784"

    private var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            SteadyFlowProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticEngine.tabTap()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Reminders are scheduled a week ahead; top the window up on every launch/foreground
            if phase == .active {
                HabitService(modelContext: modelContext).refreshAllReminders()
            }
        }
        .tint(accentColor)
        #if DEBUG
        .task { DemoData.seedIfRequested(into: modelContext) }
        #endif
        .alert("Your habits couldn't be loaded", isPresented: $showStorageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Steady Habits couldn't open its data, so changes you make now won't be saved. Please close and reopen the app. If this keeps happening, contact support.")
        }
    }
}
