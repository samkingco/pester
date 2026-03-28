import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?

    init(directory: URL, callback: @escaping () -> Void) {
        let path = directory.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { callback() }
        source.setCancelHandler { close(fd) }
        source.resume()

        self.source = source
    }

    deinit {
        source?.cancel()
    }
}
