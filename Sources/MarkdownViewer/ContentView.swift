import SwiftUI
import MarkdownKit

// MARK: - File tree data

private struct FileTreeItem: Identifiable {
    let id: String
    let name: String
    let url: URL?               // non-nil for files
    var children: [FileTreeItem]?  // non-nil for folders
}

// Recursive view for rendering nested folders
private struct FileTreeRows: View {
    let items: [FileTreeItem]

    var body: some View {
        ForEach(items) { item in
            if let children = item.children {
                DisclosureGroup {
                    FileTreeRows(items: children)
                } label: {
                    Label(item.name, systemImage: "folder")
                }
            } else if let url = item.url {
                Text(item.name)
                    .lineLimit(1)
                    .tag(url)
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    let model: ViewerModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            detailView
        }
        .onChange(of: model.openFolders.count) { oldCount, newCount in
            if newCount > oldCount {
                withAnimation { columnVisibility = .doubleColumn }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        Group {
            if !model.hasOpenFolders {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No Folder Open")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("Open Folder...") { model.openFolder() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: Binding(
                    get: { model.fileURL },
                    set: { url in if let url { model.loadFile(url) } }
                )) {
                    ForEach(model.openFolders, id: \.self) { folder in
                        let files = model.folderFileMap[folder] ?? []
                        DisclosureGroup {
                            if files.isEmpty {
                                Text("No .md files")
                                    .foregroundStyle(.secondary)
                            } else {
                                FileTreeRows(items: buildFileTree(folder: folder, files: files))
                            }
                        } label: {
                            HStack {
                                Label(folder.lastPathComponent, systemImage: "folder.fill")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    model.removeFolder(folder)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Remove folder")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Files")
        .toolbar {
            ToolbarItem {
                Button { model.openFolder() } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Open Folder")
            }
        }
    }

    private func buildFileTree(folder: URL, files: [URL]) -> [FileTreeItem] {
        class Node {
            let name: String
            var files: [URL] = []
            var dirs: [String: Node] = [:]
            init(name: String) { self.name = name }
        }

        let root = Node(name: "")
        let baseCount = folder.standardizedFileURL.pathComponents.count

        for file in files {
            let parts = file.standardizedFileURL.pathComponents
            let dirParts = parts.dropFirst(baseCount).dropLast()
            var node = root
            for dir in dirParts {
                if node.dirs[dir] == nil {
                    node.dirs[dir] = Node(name: dir)
                }
                node = node.dirs[dir]!
            }
            node.files.append(file)
        }

        let folderID = folder.absoluteString
        func convert(_ node: Node, prefix: String) -> [FileTreeItem] {
            var items: [FileTreeItem] = []

            for name in node.dirs.keys.sorted(by: {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }) {
                let path = prefix.isEmpty ? name : "\(prefix)/\(name)"
                let children = convert(node.dirs[name]!, prefix: path)
                items.append(FileTreeItem(
                    id: "\(folderID)#dir:\(path)", name: name, url: nil, children: children
                ))
            }

            for file in node.files.sorted(by: {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }) {
                items.append(FileTreeItem(
                    id: file.absoluteString,
                    name: file.deletingPathExtension().lastPathComponent,
                    url: file,
                    children: nil
                ))
            }

            return items
        }

        return convert(root, prefix: "")
    }

    // MARK: - Detail

    private var detailView: some View {
        Group {
            if model.markdown.isEmpty {
                emptyState
            } else {
                markdownContent
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Open a Markdown file")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Drop a .md file here or press Cmd+O")
                .font(.callout)
                .foregroundStyle(.tertiary)
            Button("Open File...") { model.openFile() }
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var markdownContent: some View {
        VStack(spacing: 0) {
            if let url = model.fileURL {
                titleBar(url: url)
                Divider()
            }

            MarkdownView(text: model.markdown)
                .onLinkTap { url in handleLink(url) }
                .padding(.horizontal, 8)
        }
    }

    private func handleLink(_ url: URL) {
        // Relative link to a local .md file → open in app
        if let fileURL = model.fileURL {
            let resolved = URL(filePath: url.path, relativeTo: fileURL.deletingLastPathComponent())
                .standardizedFileURL
            let ext = resolved.pathExtension.lowercased()
            if (ext == "md" || ext == "markdown"),
               FileManager.default.fileExists(atPath: resolved.path) {
                model.loadFile(resolved)
                return
            }
        }
        // External link → open in browser
        NSWorkspace.shared.open(url)
    }

    private func titleBar(url: URL) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
            Text(url.lastPathComponent)
                .font(.callout.bold())
            Text(url.deletingLastPathComponent().path(percentEncoded: false))
                .font(.callout)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.head)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
