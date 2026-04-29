# Keyboard Cleaner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar app that blocks all keyboard input during a configurable countdown timer so the user can safely clean the keyboard.

**Architecture:** Swift Package Manager project with a `KeyboardCleanerLib` library target (all app logic + SwiftUI views) and a thin `KeyboardCleaner` executable target (just `main.swift`). CGEventTap intercepts keyboard events system-wide at `.cgSessionEventTap` level. A borderless `NSWindow` at `.screenSaver` level provides the fullscreen overlay. A `build-app.sh` script assembles and ad-hoc signs the `.app` bundle.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, CGEventTap (CoreGraphics), Swift Package Manager

---

## File Map

| File | Target | Responsibility |
|---|---|---|
| `Package.swift` | — | SPM targets, platforms, dependencies |
| `Sources/KeyboardCleaner/main.swift` | Executable | Entry point: boot NSApp, set activation policy, run |
| `Sources/KeyboardCleanerLib/AppDelegate.swift` | Library | NSApplicationDelegate, owns StatusBarController |
| `Sources/KeyboardCleanerLib/AppState.swift` | Library | ObservableObject: timer countdown, duration, UserDefaults |
| `Sources/KeyboardCleanerLib/KeyboardBlocker.swift` | Library | CGEventTap start/stop, Accessibility permission prompt |
| `Sources/KeyboardCleanerLib/OverlayView.swift` | Library | SwiftUI fullscreen cleaning UI + Color(hex:) helper |
| `Sources/KeyboardCleanerLib/OverlayWindowController.swift` | Library | NSWindow at .screenSaver level, hosts OverlayView |
| `Sources/KeyboardCleanerLib/SettingsView.swift` | Library | SwiftUI duration slider panel |
| `Sources/KeyboardCleanerLib/StatusBarController.swift` | Library | NSStatusItem menu bar icon + contextual menu |
| `Tests/KeyboardCleanerTests/AppStateTests.swift` | Tests | Unit tests: timer formatting, UserDefaults persistence |
| `scripts/build-app.sh` | — | Release build → .app bundle → ad-hoc codesign |

---

### Task 1: Project scaffold

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/KeyboardCleaner/` (directory + placeholder)
- Create: `Sources/KeyboardCleanerLib/` (directory + placeholder)
- Create: `Tests/KeyboardCleanerTests/` (directory)
- Create: `scripts/` (directory)

- [ ] **Step 1: Create directories**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
mkdir -p Sources/KeyboardCleaner Sources/KeyboardCleanerLib Tests/KeyboardCleanerTests scripts
```

- [ ] **Step 2: Write Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "KeyboardCleanerLib",
            path: "Sources/KeyboardCleanerLib"
        ),
        .executableTarget(
            name: "KeyboardCleaner",
            dependencies: ["KeyboardCleanerLib"],
            path: "Sources/KeyboardCleaner"
        ),
        .testTarget(
            name: "KeyboardCleanerTests",
            dependencies: ["KeyboardCleanerLib"],
            path: "Tests/KeyboardCleanerTests"
        )
    ]
)
```

- [ ] **Step 3: Write placeholder files so targets are non-empty**

`Sources/KeyboardCleaner/main.swift`:
```swift
import Cocoa
// wired in Task 8
```

`Sources/KeyboardCleanerLib/Placeholder.swift`:
```swift
// deleted in Task 2
```

- [ ] **Step 4: Write .gitignore**

```
.build/
KeyboardCleaner.app/
.superpowers/
*.xcodeproj
*.xcworkspace
.DS_Store
```

- [ ] **Step 5: Init git and verify the package resolves**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git init
swift package resolve 2>&1
```

Expected: no errors, `.build/` directory created.

- [ ] **Step 6: Commit scaffold**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Package.swift .gitignore Sources/ Tests/ scripts/ docs/
git commit -m "chore: scaffold KeyboardCleaner SPM project"
```

---

### Task 2: AppState (TDD)

**Files:**
- Create: `Sources/KeyboardCleanerLib/AppState.swift`
- Create: `Tests/KeyboardCleanerTests/AppStateTests.swift`
- Delete: `Sources/KeyboardCleanerLib/Placeholder.swift`

- [ ] **Step 1: Write failing tests**

`Tests/KeyboardCleanerTests/AppStateTests.swift`:

```swift
import XCTest
@testable import KeyboardCleanerLib

final class AppStateTests: XCTestCase {

    func test_formattedTime_twoMinutes() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 120
        XCTAssertEqual(state.formattedTime(), "2:00")
    }

    func test_formattedTime_oneMinuteThirty() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 90
        XCTAssertEqual(state.formattedTime(), "1:30")
    }

    func test_formattedTime_zero() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 0
        XCTAssertEqual(state.formattedTime(), "0:00")
    }

    func test_duration_defaultIs120WhenNoValue() {
        let defaults = makeDefaults()
        defaults.removeObject(forKey: "cleanDuration")
        let state = AppState(defaults: defaults)
        XCTAssertEqual(state.duration, 120)
    }

    func test_duration_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let state = AppState(defaults: defaults)
        state.duration = 300
        XCTAssertEqual(defaults.integer(forKey: "cleanDuration"), 300)
    }

    func test_duration_readsFromUserDefaults() {
        let defaults = makeDefaults()
        defaults.set(180, forKey: "cleanDuration")
        let state = AppState(defaults: defaults)
        XCTAssertEqual(state.duration, 180)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }
}
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift test --filter AppStateTests 2>&1
```

Expected: build error `cannot find type 'AppState' in scope`.

- [ ] **Step 3: Delete placeholder, write AppState**

Delete `Sources/KeyboardCleanerLib/Placeholder.swift`.

`Sources/KeyboardCleanerLib/AppState.swift`:

```swift
import Foundation
import Combine

public class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var isLocked: Bool = false
    @Published public var timeRemaining: Int = 0
    public var onUnlock: (() -> Void)?

    private let defaults: UserDefaults
    private var timerCancellable: AnyCancellable?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var duration: Int {
        get {
            let v = defaults.integer(forKey: "cleanDuration")
            return v == 0 ? 120 : v
        }
        set { defaults.set(newValue, forKey: "cleanDuration") }
    }

    public func startCleaning() {
        timeRemaining = duration
        isLocked = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopCleaning()
                }
            }
    }

    public func stopCleaning() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isLocked = false
        onUnlock?()
        NSSound.beep()
    }

    public func formattedTime() -> String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
```

- [ ] **Step 4: Run tests — verify they PASS**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift test --filter AppStateTests 2>&1
```

Expected: `Test Suite 'AppStateTests' passed` — 6 tests passing.

- [ ] **Step 5: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/AppState.swift Tests/KeyboardCleanerTests/AppStateTests.swift
git rm Sources/KeyboardCleanerLib/Placeholder.swift
git commit -m "feat: add AppState with timer logic and UserDefaults persistence"
```

---

### Task 3: KeyboardBlocker

**Files:**
- Create: `Sources/KeyboardCleanerLib/KeyboardBlocker.swift`

- [ ] **Step 1: Write KeyboardBlocker**

`Sources/KeyboardCleanerLib/KeyboardBlocker.swift`:

```swift
import Cocoa

class KeyboardBlocker {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool { eventTap != nil }

    func start() -> Bool {
        guard AXIsProcessTrusted() else {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
            return false
        }

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, _, _ in return nil },
            userInfo: nil
        ) else { return false }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        CFMachPortInvalidate(tap)
        eventTap = nil
        runLoopSource = nil
    }
}
```

- [ ] **Step 2: Verify library builds**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build --target KeyboardCleanerLib 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/KeyboardBlocker.swift
git commit -m "feat: add KeyboardBlocker with CGEventTap system-level interception"
```

---

### Task 4: OverlayView

**Files:**
- Create: `Sources/KeyboardCleanerLib/OverlayView.swift`

- [ ] **Step 1: Write OverlayView**

`Sources/KeyboardCleanerLib/OverlayView.swift`:

```swift
import SwiftUI

struct OverlayView: View {
    @ObservedObject var state: AppState
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#f5f5f7").ignoresSafeArea()

            VStack(spacing: 20) {
                // Lock icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(hex: "#1d1d1f"))
                }

                Text("CLEAN MODE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(Color(hex: "#86868b"))

                Text(state.formattedTime())
                    .font(.system(size: 24, weight: .light).monospacedDigit())
                    .foregroundColor(Color(hex: "#1d1d1f"))

                // Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#e0e0e0"))
                        .frame(width: 320, height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1d1d1f"))
                        .frame(width: progressWidth, height: 6)
                        .animation(.linear(duration: 1), value: state.timeRemaining)
                }

                HStack(spacing: 24) {
                    StatusDot(color: Color(hex: "#ff3b30"), label: "Teclado bloqueado")
                    StatusDot(color: Color(hex: "#34c759"), label: "Mouse activo")
                }

                Button(action: onDone) {
                    Text("Terminado")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#86868b"))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#d0d0d0"), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    private var progressWidth: CGFloat {
        guard state.duration > 0 else { return 0 }
        return 320 * CGFloat(state.timeRemaining) / CGFloat(state.duration)
    }
}

struct StatusDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#86868b"))
        }
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: Verify library builds**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build --target KeyboardCleanerLib 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/OverlayView.swift
git commit -m "feat: add OverlayView fullscreen SwiftUI cleaning UI"
```

---

### Task 5: OverlayWindowController

**Files:**
- Create: `Sources/KeyboardCleanerLib/OverlayWindowController.swift`

- [ ] **Step 1: Write OverlayWindowController**

`Sources/KeyboardCleanerLib/OverlayWindowController.swift`:

```swift
import Cocoa
import SwiftUI

class OverlayWindowController {
    private var window: NSWindow?

    func show(state: AppState, onDone: @escaping () -> Void) {
        guard let screen = NSScreen.main else { return }

        let hosting = NSHostingController(rootView: OverlayView(state: state, onDone: onDone))

        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.isOpaque = true
        win.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        win.contentViewController = hosting
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }

    func hide() {
        window?.close()
        window = nil
    }
}
```

- [ ] **Step 2: Verify library builds**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build --target KeyboardCleanerLib 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/OverlayWindowController.swift
git commit -m "feat: add OverlayWindowController at .screenSaver window level"
```

---

### Task 6: SettingsView

**Files:**
- Create: `Sources/KeyboardCleanerLib/SettingsView.swift`

- [ ] **Step 1: Write SettingsView**

`Sources/KeyboardCleanerLib/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @State private var minutes: Double
    let onDone: () -> Void

    init(onDone: @escaping () -> Void) {
        _minutes = State(initialValue: Double(AppState.shared.duration / 60))
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Duración de limpieza")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#1d1d1f"))

            VStack(spacing: 8) {
                Slider(value: $minutes, in: 1...10, step: 1)
                    .tint(Color(hex: "#1d1d1f"))
                    .onChange(of: minutes) { newValue in
                        AppState.shared.duration = Int(newValue) * 60
                    }
                Text("\(Int(minutes)) min")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#86868b"))
            }

            Button("Listo") { onDone() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(Color(hex: "#1d1d1f"))
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(width: 260)
        .background(Color(hex: "#f5f5f7"))
    }
}
```

- [ ] **Step 2: Verify library builds**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build --target KeyboardCleanerLib 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/SettingsView.swift
git commit -m "feat: add SettingsView with duration slider"
```

---

### Task 7: StatusBarController

**Files:**
- Create: `Sources/KeyboardCleanerLib/StatusBarController.swift`

- [ ] **Step 1: Write StatusBarController**

`Sources/KeyboardCleanerLib/StatusBarController.swift`:

```swift
import Cocoa
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem!
    private let appState = AppState.shared
    private let keyboardBlocker = KeyboardBlocker()
    private let overlayController = OverlayWindowController()
    private var settingsWindow: NSWindow?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(locked: false)
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let cleanItem = NSMenuItem(
            title: "Limpiar teclado",
            action: #selector(startCleaning),
            keyEquivalent: ""
        )
        cleanItem.target = self
        menu.addItem(cleanItem)

        let settingsItem = NSMenuItem(
            title: "Configurar...",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Salir",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    @objc private func startCleaning() {
        guard !appState.isLocked else { return }
        guard keyboardBlocker.start() else { return }

        appState.onUnlock = { [weak self] in
            self?.keyboardBlocker.stop()
            self?.overlayController.hide()
            self?.updateIcon(locked: false)
        }

        appState.startCleaning()
        overlayController.show(state: appState) { [weak self] in
            self?.appState.stopCleaning()
        }
        updateIcon(locked: true)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView { [weak self] in
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
            }
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 160),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "Configurar"
            panel.contentViewController = NSHostingController(rootView: view)
            panel.center()
            panel.isReleasedWhenClosed = false
            settingsWindow = panel
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateIcon(locked: Bool) {
        let name = locked ? "lock.fill" : "keyboard"
        statusItem.button?.image = NSImage(
            systemSymbolName: name,
            accessibilityDescription: locked ? "Limpiando" : "Keyboard Cleaner"
        )
    }
}
```

- [ ] **Step 2: Verify library builds**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build --target KeyboardCleanerLib 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/StatusBarController.swift
git commit -m "feat: add StatusBarController with menu bar icon and contextual menu"
```

---

### Task 8: AppDelegate + main.swift — wire everything

**Files:**
- Create: `Sources/KeyboardCleanerLib/AppDelegate.swift`
- Modify: `Sources/KeyboardCleaner/main.swift`

- [ ] **Step 1: Write AppDelegate**

`Sources/KeyboardCleanerLib/AppDelegate.swift`:

```swift
import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.setup()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
```

- [ ] **Step 2: Write main.swift**

`Sources/KeyboardCleaner/main.swift`:

```swift
import Cocoa
import KeyboardCleanerLib

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 3: Build full executable**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift build 2>&1
```

Expected: `Build complete!` — no errors.

- [ ] **Step 4: Run all tests**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC" && swift test 2>&1
```

Expected: `Test Suite 'All tests' passed` — 6 tests.

- [ ] **Step 5: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add Sources/KeyboardCleanerLib/AppDelegate.swift Sources/KeyboardCleaner/main.swift
git commit -m "feat: wire AppDelegate and main entry point"
```

---

### Task 9: Build .app bundle and launch

**Files:**
- Create: `scripts/build-app.sh`

- [ ] **Step 1: Write build-app.sh**

`scripts/build-app.sh`:

```bash
#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="KeyboardCleaner"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "→ Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

BINARY=".build/release/$APP_NAME"

echo "→ Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>KeyboardCleaner</string>
    <key>CFBundleDisplayName</key>
    <string>Keyboard Cleaner</string>
    <key>CFBundleIdentifier</key>
    <string>com.keyboardcleaner.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>KeyboardCleaner</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Keyboard Cleaner necesita acceso de Accesibilidad para bloquear el teclado mientras lo limpias.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "→ Ad-hoc signing..."
codesign --sign - --force --deep "$APP_BUNDLE"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo "→ Launch: open \"$APP_BUNDLE\""
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC/scripts/build-app.sh"
```

- [ ] **Step 3: Run build script**

```bash
bash "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC/scripts/build-app.sh" 2>&1
```

Expected output ends with:
```
✓ Built: .../KeyboardCleaner.app
→ Launch: open ".../KeyboardCleaner.app"
```

- [ ] **Step 4: Launch**

```bash
open "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC/KeyboardCleaner.app"
```

Expected: keyboard icon `⌨` appears in menu bar top-right. No Dock icon.

- [ ] **Step 5: Manual verification checklist**
  1. Click keyboard icon → select "Limpiar teclado"
  2. macOS shows Accessibility permission dialog → grant it in System Settings > Privacy & Security > Accessibility
  3. Click "Limpiar teclado" again — fullscreen overlay appears, background `#f5f5f7`
  4. Try typing — nothing happens (keyboard fully blocked)
  5. Verify: "CLEAN MODE" label, countdown timer `2:00` counting down, wide progress bar, red/green dots, "Terminado" button
  6. Click "Terminado" — overlay closes, system beep plays, keyboard works again
  7. Icon reverts from `lock.fill` back to `keyboard`
  8. Click "Configurar..." — settings panel opens, drag slider to 3 min, click "Listo"
  9. Start cleaning again — timer now shows `3:00`

- [ ] **Step 6: Commit**

```bash
cd "/Users/fernandomoreno/Library/Mobile Documents/com~apple~CloudDocs/NEXO CLIENTES/C2K-MAC"
git add scripts/build-app.sh
git commit -m "feat: add build script to assemble and sign .app bundle"
```
