import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    @Published var clockWindows: [ClockNSWindow] = []
    @Published var isClockVisible: Bool = true
    @Published var displaySettings: [DisplaySetting] = []
    private var screenChangeTimer: Timer?
    
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
                // Scale padding based on screen size for better positioning on different monitors
                let scaledPadding = min(padding, screenFrame.width * 0.02) // Max 2% of screen width
                switch self {
                case .topLeft:
                    return NSPoint(x: screenFrame.minX + scaledPadding, y: screenFrame.maxY - windowSize.height - scaledPadding)
                case .topRight:
                    return NSPoint(x: screenFrame.maxX - windowSize.width - scaledPadding, y: screenFrame.maxY - windowSize.height - scaledPadding)
                case .topCenter:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.maxY - windowSize.height - scaledPadding)
                case .bottomLeft:
                    return NSPoint(x: screenFrame.minX + scaledPadding, y: screenFrame.minY + scaledPadding)
                case .bottomRight:
                    return NSPoint(x: screenFrame.maxX - windowSize.width - scaledPadding, y: screenFrame.minY + scaledPadding)
                case .bottomCenter:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.minY + scaledPadding)
                case .center:
                    return NSPoint(x: screenFrame.midX - windowSize.width / 2, y: screenFrame.midY - windowSize.height / 2)
                case .menuBarOverlay:
                    // Scale menu bar padding based on screen size
                    let scaledRightPadding = min(10.0, screenFrame.width * 0.01) // Max 1% of screen width
                    let verticalOffset: CGFloat = 4
                    return NSPoint(
                        x: screenFrame.maxX - windowSize.width - scaledRightPadding,
                        y: screenFrame.maxY - windowSize.height - verticalOffset
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
        screenChangeTimer?.invalidate()
        screenChangeTimer = nil
        closeClockWindows()
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
        // Debounce screen change notifications to prevent rapid recreation
        screenChangeTimer?.invalidate()
        screenChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recreateClockWindows()
            }
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
        
        // Use the screen's frame directly for positioning calculations
        let screenFrame = screen.frame
        
        // Size to match menu bar clock dimensions
        let windowSize = CGSize(width: 150, height: 30)
        
        // Calculate position relative to the specific screen
        let origin = displaySetting.position.calculateOrigin(
            for: screenFrame,
            windowSize: windowSize
        )
        
        // Create window with absolute coordinates
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
        
        // Ensure window is properly initialized before showing
        DispatchQueue.main.async {
            window.orderFront(nil)
            self.clockWindows.append(window)
        }
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
        // Properly close and remove windows
        for window in clockWindows {
            window.orderOut(nil)
            window.close()
        }
        clockWindows.removeAll()
        
        // Force a run loop cycle to ensure windows are properly deallocated
        DispatchQueue.main.async {
            // This ensures the window deallocation completes
        }
    }
    
    private func recreateClockWindows() {
        let wasVisible = isClockVisible
        closeClockWindows()
        setupDisplaySettings()
        
        // Add a small delay to ensure proper window cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if wasVisible {
                self.createClockWindows()
            }
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
