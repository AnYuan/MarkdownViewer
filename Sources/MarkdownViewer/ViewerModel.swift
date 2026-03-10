import SwiftUI
import AppKit

@Observable
@MainActor
final class ViewerModel {
    var fileURL: URL?
    var markdown: String = ""
    private var fileWatcher: FileWatcher?

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFile(url)
    }

    func loadFile(_ url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        fileURL = url
        markdown = content

        fileWatcher = FileWatcher(url: url) { [weak self] in
            guard let self else { return }
            if let updated = try? String(contentsOf: url, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.markdown = updated
                }
            }
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { [weak self] data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            Task { @MainActor [weak self] in
                self?.loadFile(url)
            }
        }
        return true
    }
}
