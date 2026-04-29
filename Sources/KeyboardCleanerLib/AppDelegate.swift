import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = MainActor.assumeIsolated { StatusBarController() }

    @MainActor
    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.setup()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
