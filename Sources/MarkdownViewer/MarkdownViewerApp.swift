import SwiftUI
import AppKit

@main
struct MarkdownViewerApp: App {
    @State private var model = ViewerModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(minWidth: 600, minHeight: 400)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    model.handleDrop(providers)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") { model.openFile() }
                    .keyboardShortcut("o")
                Button("Open Folder...") { model.openFolder() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }
}
