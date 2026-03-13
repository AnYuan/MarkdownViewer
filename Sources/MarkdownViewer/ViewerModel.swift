import SwiftUI
import AppKit

@Observable
@MainActor
final class ViewerModel {
    var fileURL: URL?
    var markdown: String = ""
    /// Opened folders in order, keyed by standardized absolute path to avoid duplicates.
    var openFolders: [URL] = []
    var folderFileMap: [URL: [URL]] = [:]  // folder -> its .md files
    private var fileWatcher: FileWatcher?

    var hasOpenFolders: Bool { !openFolders.isEmpty }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText,
            .folder
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url)
    }

    func open(_ url: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return }
        if isDir.boolValue {
            addFolder(url)
        } else {
            loadFile(url)
        }
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

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        addFolder(url)
    }

    func addFolder(_ url: URL) {
        let standardized = url.standardizedFileURL
        // Same absolute path → refresh its files; otherwise append
        if let idx = openFolders.firstIndex(where: { $0.standardizedFileURL == standardized }) {
            folderFileMap[openFolders[idx]] = scanFiles(in: url)
        } else {
            openFolders.append(url)
            folderFileMap[url] = scanFiles(in: url)
        }
    }

    func removeFolder(_ url: URL) {
        openFolders.removeAll { $0 == url }
        folderFileMap.removeValue(forKey: url)
    }

    private func scanFiles(in folderURL: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if ext == "md" || ext == "markdown" {
                files.append(fileURL)
            }
        }

        return files.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { [weak self] data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            Task { @MainActor [weak self] in
                self?.open(url)
            }
        }
        return true
    }
}
