import SwiftUI
import MarkdownKit

struct ContentView: View {
    let model: ViewerModel

    var body: some View {
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
                .padding(.horizontal, 8)
        }
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
