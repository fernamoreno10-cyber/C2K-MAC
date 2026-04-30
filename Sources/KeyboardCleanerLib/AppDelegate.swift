import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor private var statusBarController: StatusBarController!

    @MainActor
    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        statusBarController.setup()
    }

    /// Maneja URL schemes: c2k://emergency y c2k://clean
    @MainActor
    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "c2k" else { continue }
            switch url.host {
            case "emergency":
                statusBarController.startEmergencyCleaning()
            case "clean":
                statusBarController.startEmergencyCleaning() // usa duración configurada
            default:
                break
            }
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
