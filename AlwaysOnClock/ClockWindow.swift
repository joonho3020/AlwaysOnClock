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
    private var fullscreenCheckTimer: Timer?
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
        setupFullscreenMonitoring()
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        fullscreenCheckTimer?.invalidate()
        fullscreenCheckTimer = nil
    }

    private func setupFullscreenMonitoring() {
        // Check fullscreen state every 0.2 seconds
        fullscreenCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateWindowVisibility()
        }
    }
    
    private func updateWindowVisibility() {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = self.screen?.frame ?? NSScreen.main?.frame ?? NSRect.zero
        
        // Calculate distance from top of screen
        let distanceFromTop = screenFrame.maxY - mouseLocation.y
        
        // Check if current space is fullscreen
        let isFullscreen = isCurrentSpaceFullscreen()

        // print("distanceFromTop: \(distanceFromTop)")
        // if isFullscreen {
        //     print("Current Space is fullscreen")
        // } else {
        //     print("Current Space is NOT fullscreen")
        // }
        
        DispatchQueue.main.async {
            if distanceFromTop <= self.hideThreshold || !isFullscreen {
                // Mouse is near the top OR in fullscreen space - hide the window
                self.orderOut(nil)
            } else {
                // Mouse is away from top AND not in fullscreen space - show the window
                self.orderFront(nil)
            }
        }
    }

    private func setupMouseTracking() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            self.updateWindowVisibility()
        }
    }
}
