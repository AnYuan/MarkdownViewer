import Foundation

/// Watches a file for changes using GCD dispatch sources.
final class FileWatcher: @unchecked Sendable {
    private var source: DispatchSourceFileSystemObject?

    init(url: URL, onChange: @escaping @Sendable () -> Void) {
        let fd = open(url.path(percentEncoded: false), O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { onChange() }
        source.setCancelHandler { close(fd) }
        source.resume()

        self.source = source
    }

    deinit {
        source?.cancel()
    }
}
