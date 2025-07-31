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
}
