import SwiftUI
import AppKit

struct ClockWindow: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var isHovering = false
    
    var body: some View {
        Text(viewModel.formattedTime())
            .font(.system(size: viewModel.fontSize, weight: .medium, design: .default))
            .foregroundColor(viewModel.textColor)
            .padding(viewModel.padding)
            .background(
                RoundedRectangle(cornerRadius: viewModel.cornerRadius)
                    .fill(viewModel.backgroundColor)
                    .opacity(isHovering ? 0.3 : viewModel.opacity)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .contextMenu {
                Button("Settings") {
                    openSettings()
                }
                Divider()
                Button("Hide Clock") {
                    hideClockWindow()
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
    }
    
    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func hideClockWindow() {
        if let window = NSApp.windows.first(where: { $0.contentView?.subviews.first is NSHostingView<ClockWindow> }) {
            window.orderOut(nil)
        }
    }
}

class ClockNSWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    private var mouseMonitor: Any?
    private let menuBarHeight: CGFloat = 30 // Approximate menu bar height
    private let hideThreshold: CGFloat = 35 // Hide when mouse is within this distance from top
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: backingStoreType, defer: flag)
        
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        setupMouseTracking()
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    

    
    private func setupMouseTracking() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            let screenFrame = self.screen?.frame ?? NSScreen.main?.frame ?? NSRect.zero
            
            // Calculate distance from top of screen
            let distanceFromTop = screenFrame.maxY - mouseLocation.y
            
            // Detect if the menu-bar is currently visible on-screen (works for both
            // always-visible and auto-hide cases).
            let isFullscreen = isCurrentSpaceFullscreen()
            if isFullscreen {
                print("Current Space is fullscreen")
            } else {
                print("Current Space is NOT fullscreen")
            }
      
            if distanceFromTop <= self.hideThreshold || !isFullscreen {
                // Mouse is near the top OR menu bar is visible - hide the window
                DispatchQueue.main.async {
                    self.orderOut(nil)
                }
            } else {
                // Mouse is away from top AND menu bar is hidden - show the window
                DispatchQueue.main.async {
                    self.orderFront(nil)
                }
            }
        }
    }

    /// Returns true when the current space has a permanent menu-bar
    /// (i.e. we’re *not* in a macOS full-screen space).
    private func isMenuBarAlwaysPresent(on screen: NSScreen?) -> Bool {
        guard let s = screen ?? NSScreen.main else { return false }

        print("s.frame.height: \(s.frame.height)")
        print("s.visibleFrame.height: \(s.visibleFrame.height)")
        // The visible frame excludes the areas reserved for the Dock and menubar.
        // • In a normal desktop:           frame.height  > visibleFrame.height
        // • In an auto-hidden menubar:     the same difference exists
        // • In a true full-screen space:   frame == visibleFrame  (difference ≈ 0)
        return (s.frame.height - s.visibleFrame.height) > 1   // 1-pt tolerance
    }
    
    private func isMenuBarVisible() -> Bool {
        // Check if the menu bar is visible by looking for menu bar windows
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        
        let screenFrame = self.screen?.frame ?? NSScreen.main?.frame ?? NSRect.zero
        
        for windowInfo in windowList {
            if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
               ownerName == "SystemUIServer",
               let layer = windowInfo[kCGWindowLayer as String] as? Int,
               layer == Int(CGWindowLevelForKey(.mainMenuWindow)),
               let alpha = windowInfo[kCGWindowAlpha as String] as? Double, alpha > 0.01,
               let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
               let y = bounds["Y"] as? CGFloat,
               let height = bounds["Height"] as? CGFloat {
                // Ensure the window sits at the very top of the screen and has some height ( > 10 pt )
                if abs(y - (screenFrame.maxY - height)) < 5.0 && height > 10 {
                    return true
                }
            }
        }
        return false
    }
}
