import Foundation
import ServiceManagement

class StartupManager: ObservableObject {
    @Published var isStartupEnabled: Bool = false
    
    init() {
        loadStartupState()
    }
    
    func toggleStartup() {
        if isStartupEnabled {
            disableStartup()
        } else {
            enableStartup()
        }
    }
    
    private func enableStartup() {
        // Create LaunchAgent plist
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.alwaysonclock.startup</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(Bundle.main.executablePath!)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        
        // Get the LaunchAgents directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        
        // Create LaunchAgents directory if it doesn't exist
        try? FileManager.default.createDirectory(at: launchAgentsPath, withIntermediateDirectories: true)
        
        // Write the plist file
        let plistPath = launchAgentsPath.appendingPathComponent("com.alwaysonclock.startup.plist")
        
        do {
            try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
            
            // Load the LaunchAgent
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["load", plistPath.path]
            
            try process.run()
            process.waitUntilExit()
            
            isStartupEnabled = true
            saveStartupState()
            
            print("Startup enabled successfully")
        } catch {
            print("Failed to enable startup: \(error)")
        }
    }
    
    private func disableStartup() {
        // Get the LaunchAgents directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsPath.appendingPathComponent("com.alwaysonclock.startup.plist")
        
        // Unload the LaunchAgent
        let process = Process()
        process.launchPath = "/bin/launchctl"
        process.arguments = ["unload", plistPath.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Remove the plist file
            try FileManager.default.removeItem(at: plistPath)
            
            isStartupEnabled = false
            saveStartupState()
            
            print("Startup disabled successfully")
        } catch {
            print("Failed to disable startup: \(error)")
        }
    }
    
    private func loadStartupState() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsPath.appendingPathComponent("com.alwaysonclock.startup.plist")
        
        isStartupEnabled = FileManager.default.fileExists(atPath: plistPath.path)
    }
    
    private func saveStartupState() {
        UserDefaults.standard.set(isStartupEnabled, forKey: "isStartupEnabled")
    }
} 