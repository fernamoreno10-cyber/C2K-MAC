import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor private var statusBarController: StatusBarController!

    @MainActor
    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        statusBarController.setup()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
