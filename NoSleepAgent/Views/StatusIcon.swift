import SwiftUI

public enum IconStyle: String, CaseIterable, Identifiable {
    case coffee = "Coffee Cup"
    case sparkles = "Sparkles AI"
    case cpu = "CPU Agent"
    case gears = "Dual Gears"
    case circle = "Simple Dot"

    public var id: String { rawValue }

    public var icons: (active: String, inactive: String) {
        switch self {
        case .coffee: return ("cup.and.saucer.fill", "cup.and.saucer")
        case .sparkles: return ("sparkles", "sparkle")
        case .cpu: return ("cpu.fill", "cpu")
        case .gears: return ("gearshape.2.fill", "gearshape.2")
        case .circle: return ("circle.fill", "circle")
        }
    }
}

public struct StatusIcon: View {
    let status: ClaudeStatus
    let style: IconStyle

    public init(status: ClaudeStatus, style: IconStyle) {
        self.status = status
        self.style = style
    }

    public var body: some View {
        let icons = style.icons
        Image(systemName: status.isWorking ? icons.active : icons.inactive)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(status.isWorking ? .green : .secondary)
            .imageScale(.large)
            .font(.system(size: 18, weight: .regular))
            .contextMenu {
                Button("Quit NoSleep Agent") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
    }
}
