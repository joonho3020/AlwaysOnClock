import SwiftUI
import AppKit

@main
struct AlwaysOnClockApp: App {
    @StateObject private var windowManager = WindowManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Pass the windowManager to appDelegate
        AppDelegate.shared = windowManager
    }
    
    var body: some Scene {
        Settings {
            SettingsView(windowManager: windowManager)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    static var shared: WindowManager?
    private var startupManager = StartupManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon since we're a menu bar app
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupWindowManager()
        
        // Generate app icons (this will create PNG files in Documents folder)
        // Uncomment the line below to generate icons, then comment it out again
        // IconGenerator.generateIcons()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Always On Clock")
            button.toolTip = "Always On Clock"
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Clock", action: #selector(showClock), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide Clock", action: #selector(hideClock), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupWindowManager() {
        // Initialize clock windows now that AppKit is ready
        AppDelegate.shared?.createClockWindows()
    }
    
    @objc private func showClock() {
        AppDelegate.shared?.showClockWindows()
    }
    
    @objc private func hideClock() {
        AppDelegate.shared?.hideClockWindows()
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}