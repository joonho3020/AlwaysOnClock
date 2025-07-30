import Foundation
import SwiftUI

class ClockViewModel: ObservableObject {
    @Published var currentTime = Date()
    @Published var timeFormat: TimeFormat = .twelveHour
    @Published var showSeconds: Bool = true
    @Published var showDate: Bool = false
    @Published var showDayOfWeek: Bool = false
    @Published var customFormat: String = ""
    @Published var useCustomFormat: Bool = false
    @Published var selectedFont: ClockFont = .sfPro
    @Published var fontSize: Double = 16
    @Published var textColor: Color = .primary
    @Published var backgroundColor: Color = .clear
    @Published var cornerRadius: Double = 8
    @Published var padding: Double = 8
    @Published var opacity: Double = 0.9
    
    private var timer: Timer?
    
    enum TimeFormat: String, CaseIterable, Identifiable {
        case twelveHour = "12-hour"
        case twentyFourHour = "24-hour"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .twelveHour:
                return "12-hour format"
            case .twentyFourHour:
                return "24-hour format"
            }
        }
    }
    
    enum ClockFont: String, CaseIterable, Identifiable {
        case sfPro = "SF Pro"
        case sfMono = "SF Mono"
        case sfRounded = "SF Pro Rounded"
        case system = "System"
        
        var id: String { rawValue }
        
        var font: Font {
            switch self {
            case .sfPro:
                return .system(.body, design: .default)
            case .sfMono:
                return .system(.body, design: .monospaced)
            case .sfRounded:
                return .system(.body, design: .rounded)
            case .system:
                return .system(.body)
            }
        }
    }
    
    init() {
        startTimer()
        loadPreferences()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentTime = Date()
            }
        }
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        
        if useCustomFormat && !customFormat.isEmpty {
            formatter.dateFormat = customFormat
        } else {
            var formatString = ""
            
            if showDayOfWeek {
                formatString += "EEEE "
            }
            
            if showDate {
                formatString += "MMM d "
            }
            
            switch timeFormat {
            case .twelveHour:
                formatString += showSeconds ? "h:mm:ss a" : "h:mm a"
            case .twentyFourHour:
                formatString += showSeconds ? "HH:mm:ss" : "HH:mm"
            }
            
            formatter.dateFormat = formatString.trimmingCharacters(in: .whitespaces)
        }
        
        return formatter.string(from: currentTime)
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        if let formatString = defaults.object(forKey: "timeFormat") as? String,
           let format = TimeFormat(rawValue: formatString) {
            timeFormat = format
        }
        
        showSeconds = defaults.object(forKey: "showSeconds") as? Bool ?? true
        showDate = defaults.object(forKey: "showDate") as? Bool ?? false
        showDayOfWeek = defaults.object(forKey: "showDayOfWeek") as? Bool ?? false
        customFormat = defaults.object(forKey: "customFormat") as? String ?? ""
        useCustomFormat = defaults.object(forKey: "useCustomFormat") as? Bool ?? false
        
        if let fontString = defaults.object(forKey: "selectedFont") as? String,
           let font = ClockFont(rawValue: fontString) {
            selectedFont = font
        }
        
        fontSize = defaults.object(forKey: "fontSize") as? Double ?? 16
        opacity = defaults.object(forKey: "opacity") as? Double ?? 0.9
        cornerRadius = defaults.object(forKey: "cornerRadius") as? Double ?? 8
        padding = defaults.object(forKey: "padding") as? Double ?? 8
    }
    
    func savePreferences() {
        let defaults = UserDefaults.standard
        
        defaults.set(timeFormat.rawValue, forKey: "timeFormat")
        defaults.set(showSeconds, forKey: "showSeconds")
        defaults.set(showDate, forKey: "showDate")
        defaults.set(showDayOfWeek, forKey: "showDayOfWeek")
        defaults.set(customFormat, forKey: "customFormat")
        defaults.set(useCustomFormat, forKey: "useCustomFormat")
        defaults.set(selectedFont.rawValue, forKey: "selectedFont")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(opacity, forKey: "opacity")
        defaults.set(cornerRadius, forKey: "cornerRadius")
        defaults.set(padding, forKey: "padding")
    }
}