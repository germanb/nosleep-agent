import SwiftUI

struct IconOption: Identifiable {
    let id = UUID()
    let name: String
    let activeIcon: String
    let inactiveIcon: String
    let description: String
}

struct IconPreviewApp: App {
    let options = [
        IconOption(
            name: "Coffee/Caffeinate",
            activeIcon: "cup.and.saucer.fill",
            inactiveIcon: "cup.and.saucer",
            description: "Matches 'caffeinate' command theme"
        ),
        IconOption(
            name: "Eye/Awake",
            activeIcon: "eye.fill",
            inactiveIcon: "eye.slash",
            description: "Open eye = awake, slashed = sleeping"
        ),
        IconOption(
            name: "Moon/No Sleep",
            activeIcon: "moon.zzz.fill",
            inactiveIcon: "moon",
            description: "Moon with zzz when active"
        ),
        IconOption(
            name: "Power/Energy",
            activeIcon: "bolt.fill",
            inactiveIcon: "bolt",
            description: "Lightning bolt for energy/power"
        ),
        IconOption(
            name: "Simple Dot",
            activeIcon: "circle.fill",
            inactiveIcon: "circle",
            description: "Minimal on/off indicator"
        ),
        IconOption(
            name: "Mug/Coffee",
            activeIcon: "mug.fill",
            inactiveIcon: "mug",
            description: "Coffee mug variant"
        ),
        IconOption(
            name: "Sun/Awake",
            activeIcon: "sun.max.fill",
            inactiveIcon: "moon.fill",
            description: "Sun = awake, Moon = sleeping"
        )
    ]

    var body: some Scene {
        WindowGroup {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("NoSleepAgent Icon Options")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)

                    ForEach(options) { option in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(option.name)
                                .font(.headline)

                            HStack(spacing: 40) {
                                VStack {
                                    Image(systemName: option.activeIcon)
                                        .font(.system(size: 40))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.green)
                                    Text("Active (Green)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                VStack {
                                    Image(systemName: option.inactiveIcon)
                                        .font(.system(size: 40))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)
                                    Text("Inactive (Gray)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(option.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 5)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .frame(minWidth: 600, minHeight: 800)
        }
    }
}

@main
struct PreviewWrapper {
    static func main() {
        IconPreviewApp.main()
    }
}
