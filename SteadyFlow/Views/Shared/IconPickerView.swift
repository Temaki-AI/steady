import SwiftUI

/// SF Symbol icon picker with search
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// Curated SF Symbols suitable for habits
    private static let icons: [String] = [
        // Fitness & Health
        "figure.run", "figure.walk", "figure.yoga", "dumbbell.fill",
        "heart.fill", "brain.head.profile", "lungs.fill", "bed.double.fill",
        "drop.fill", "cross.case.fill",
        // Mind & Learning
        "book.fill", "pencil", "brain", "lightbulb.fill",
        "graduationcap.fill", "text.book.closed.fill", "doc.text.fill",
        // Food & Drink
        "cup.and.saucer.fill", "fork.knife", "carrot.fill", "leaf.fill",
        // Lifestyle
        "house.fill", "music.note", "paintbrush.fill", "camera.fill",
        "gamecontroller.fill", "guitars.fill", "theatermasks.fill",
        // Productivity
        "checkmark.circle.fill", "clock.fill", "calendar", "alarm.fill",
        "deskclock.fill", "timer", "stopwatch.fill",
        // Social
        "phone.fill", "envelope.fill", "message.fill", "person.2.fill",
        "hand.raised.fill", "figure.2.arms.open",
        // Nature
        "sun.max.fill", "moon.fill", "star.fill", "cloud.fill",
        "snowflake", "flame.fill", "bolt.fill",
        // Wellness
        "cross.fill", "pills.fill", "stethoscope", "bandage.fill",
        "eye.fill", "ear.fill", "nose.fill",
        // Money & Work
        "dollarsign.circle.fill", "briefcase.fill", "chart.line.uptrend.xyaxis",
        "laptopcomputer", "keyboard.fill",
        // Symbols
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill",
        "hexagon.fill", "pentagon.fill", "seal.fill",
        // Transportation
        "bicycle", "car.fill", "bus.fill", "airplane",
        // Misc
        "gift.fill", "bag.fill", "cart.fill", "wrench.fill",
        "hammer.fill", "scissors", "paintpalette.fill",
        "globe.americas.fill", "map.fill", "flag.fill"
    ]

    private var filteredIcons: [String] {
        if searchText.isEmpty { return Self.icons }
        return Self.icons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(selectedIcon == icon ? .primary : .secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search icons")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
