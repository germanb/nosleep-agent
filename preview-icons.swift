#!/usr/bin/env swift
import SwiftUI

struct IconOption {
    let name: String
    let activeIcon: String
    let inactiveIcon: String
}

struct ContentView: View {
    let options = [
        IconOption(name: "🛏️ Bed: Empty vs Filled", activeIcon: "bed.double", inactiveIcon: "bed.double.fill"),
        IconOption(name: "🛏️ Bed: Filled vs Empty", activeIcon: "bed.double.fill", inactiveIcon: "bed.double"),
        IconOption(name: "👁️ Eye vs Bed", activeIcon: "eye.fill", inactiveIcon: "bed.double.fill"),
        IconOption(name: "🚫 No-Sign vs Bed", activeIcon: "nosign", inactiveIcon: "bed.double"),
        IconOption(name: "👁️ Eye Open/Closed", activeIcon: "eye.fill", inactiveIcon: "eye.slash.fill"),
        IconOption(name: "✨ Sparkles AI", activeIcon: "sparkles", inactiveIcon: "sparkle"),
        IconOption(name: "🤖 CPU Agent", activeIcon: "cpu.fill", inactiveIcon: "cpu"),
        IconOption(name: "⚙️ Dual Gears", activeIcon: "gearshape.2.fill", inactiveIcon: "gearshape.2")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("NoSleepAgent Icon Options")
                .font(.title)
                .bold()

            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                HStack(spacing: 30) {
                    Text(option.name)
                        .frame(width: 180, alignment: .leading)

                    HStack(spacing: 40) {
                        VStack {
                            Image(systemName: option.activeIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Image(systemName: option.inactiveIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("Inactive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Text("Menu bar icons are smaller, around 16pt")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct IconPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

IconPreviewApp.main()
