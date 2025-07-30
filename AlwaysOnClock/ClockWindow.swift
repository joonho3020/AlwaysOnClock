import SwiftUI
import AppKit

struct ClockWindow: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var isHovering = false
    
    var body: some View {
        Text(viewModel.formattedTime())
            .font(viewModel.selectedFont.font.weight(.medium))
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
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: backingStoreType, defer: flag)
        
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.level = NSWindow.Level(NSWindow.Level.floating.rawValue + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        setupInitialPosition()
    }
    
    private func setupInitialPosition() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = CGSize(width: 200, height: 50)
        let padding: CGFloat = 20
        let origin = CGPoint(
            x: screenFrame.maxX - windowSize.width - padding,
            y: screenFrame.maxY - windowSize.height - padding
        )
        
        self.setFrame(NSRect(origin: origin, size: windowSize), display: true)
    }
}