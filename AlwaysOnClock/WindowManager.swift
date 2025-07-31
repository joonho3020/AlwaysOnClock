import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    @Published var clockWindows: [ClockNSWindow] = []
    @Published var isClockVisible: Bool = true
    @Published var displaySettings: [DisplaySetting] = []
    
    struct DisplaySetting: Identifiable {
        let id = UUID()
        let screen: NSScreen
        var isEnabled: Bool = true
        var position: WindowPosition = .menuBarOverlay
        
        enum WindowPosition: String, CaseIterable {
            case topLeft = "Top Left"
            case topRight = "Top Right"
            case topCenter = "Top Center"
            case bottomLeft = "Bottom Left"
            case bottomRight = "Bottom Right"
            case bottomCenter = "Bottom Center"
            case center = "Center"
            case menuBarOverlay = "Menu Bar Overlay"
            
            func calculateOrigin(for screenFrame: NSRect, windowSize: NSSize, padding: CGFloat = 20) -> NSPoint {
                switch self {
                case .topLeft:
                    return NSPoint(x: screenFrame.minX + padding, y: screenFrame.maxY - windowSize.height - padding)
                case .topRight:
                    return NSPoint(x: screenFrame.maxX - windowSize.width - padding, y: screenFrame.maxY - windowSize.height - padding)
                case .topCenter:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.maxY - windowSize.height - padding)
                case .bottomLeft:
                    return NSPoint(x: screenFrame.minX + padding, y: screenFrame.minY + padding)
                case .bottomRight:
                    return NSPoint(x: screenFrame.maxX - windowSize.width - padding, y: screenFrame.minY + padding)
                case .bottomCenter:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.minY + padding)
                case .center:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.midY - windowSize.height / 2)
                case .menuBarOverlay:
                    print("menuBarOverlay")
                    // We must receive the full frame, not visibleFrame!
                    let menuBarHeight = screenFrame.height - NSScreen.main!.visibleFrame.height
                    let rightPadding: CGFloat = 8
                    let verticalOffset: CGFloat = 2
                    print("menuBarHeight: \(menuBarHeight)")
                    print("rightPadding: \(rightPadding)")
                    print("verticalOffset: \(verticalOffset)")  
                    return NSPoint(
                        x: screenFrame.maxX - windowSize.width - rightPadding,
                        y: screenFrame.maxY - windowSize.height + verticalOffset
                    )
                }
            }
        }
    }
    
    init() {
        setupDisplaySettings()
        setupScreenChangeNotifications()
        loadPreferences()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupDisplaySettings() {
        displaySettings = NSScreen.screens.map { screen in
            DisplaySetting(screen: screen)
        }
    }
    
    private func setupScreenChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screensDidChange() {
        DispatchQueue.main.async {
            self.recreateClockWindows()
        }
    }
    
    func createClockWindows() {
        closeClockWindows()
        
        // Ensure we have screens available
        guard !NSScreen.screens.isEmpty else { return }
        
        for displaySetting in displaySettings where displaySetting.isEnabled {
            createClockWindow(for: displaySetting)
        }
    }
    
    private func createClockWindow(for displaySetting: DisplaySetting) {
        let screen = displaySetting.screen
        // Always use full screen frame for menu bar overlay to position at the very top
        let screenFrame = displaySetting.position == .menuBarOverlay ? screen.frame : screen.visibleFrame
        // let screenFrame = screen.frame

        // Size to match menu bar clock dimensions
        let windowSize = CGSize(width: 110, height: 30)
        
        let origin = displaySetting.position.calculateOrigin(
            for: screenFrame,
            windowSize: windowSize
        )
        
        let window = ClockNSWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        let clockView = ClockWindow()
        let hostingView = NSHostingView(rootView: clockView)
        hostingView.frame = window.contentView?.bounds ?? NSRect.zero
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        
        if screen != NSScreen.main, let mainScreen = NSScreen.main {
            let screenFrame = screen.frame
            let adjustedOrigin = NSPoint(
                x: screenFrame.minX + origin.x - mainScreen.frame.minX,
                y: origin.y
            )
            window.setFrameOrigin(adjustedOrigin)
        }
        
        window.orderFront(nil)
        clockWindows.append(window)
    }
    
    func showClockWindows() {
        if clockWindows.isEmpty {
            createClockWindows()
        } else {
            clockWindows.forEach { $0.orderFront(nil) }
        }
        isClockVisible = true
        savePreferences()
    }
    
    func hideClockWindows() {
        clockWindows.forEach { $0.orderOut(nil) }
        isClockVisible = false
        savePreferences()
    }
    
    func closeClockWindows() {
        clockWindows.forEach { $0.close() }
        clockWindows.removeAll()
    }
    
    private func recreateClockWindows() {
        let wasVisible = isClockVisible
        closeClockWindows()
        setupDisplaySettings()
        
        if wasVisible {
            createClockWindows()
        }
    }
    
    func toggleDisplay(_ displayId: UUID, enabled: Bool) {
        if let index = displaySettings.firstIndex(where: { $0.id == displayId }) {
            displaySettings[index].isEnabled = enabled
            savePreferences()
            
            if isClockVisible {
                recreateClockWindows()
            }
        }
    }

    private func menuBarHeight(for screen: NSScreen) -> CGFloat {
        return screen.frame.height - screen.visibleFrame.height
    }
    
    func setPosition(_ displayId: UUID, position: DisplaySetting.WindowPosition) {
        if let index = displaySettings.firstIndex(where: { $0.id == displayId }) {
            displaySettings[index].position = position
            savePreferences()
            
            if isClockVisible {
                recreateClockWindows()
            }
        }
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        isClockVisible = defaults.object(forKey: "isClockVisible") as? Bool ?? true
        
        // Don't create windows during init - wait for AppKit to be ready
        // Windows will be created later by AppDelegate.setupWindowManager()
    }
    
    private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(isClockVisible, forKey: "isClockVisible")
    }
}
