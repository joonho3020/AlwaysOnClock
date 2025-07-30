import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var windowManager: WindowManager
    @StateObject private var clockViewModel = ClockViewModel()
    @State private var selectedTab: SettingsTab = .appearance
    
    enum SettingsTab: String, CaseIterable {
        case appearance = "Appearance"
        case format = "Format"
        case displays = "Displays"
        
        var systemImage: String {
            switch self {
            case .appearance: return "paintbrush"
            case .format: return "textformat"
            case .displays: return "display.2"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180, maxWidth: 200)
            
            Group {
                switch selectedTab {
                case .appearance:
                    AppearanceSettingsView(clockViewModel: clockViewModel, windowManager: windowManager)
                case .format:
                    FormatSettingsView(clockViewModel: clockViewModel)
                case .displays:
                    DisplaySettingsView(windowManager: windowManager)
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        }
        .frame(minWidth: 580, minHeight: 400)
        .navigationTitle("Always On Clock Settings")
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var clockViewModel: ClockViewModel
    @ObservedObject var windowManager: WindowManager
    
    var body: some View {
        Form {
            Section("Font") {
                Picker("Font Family", selection: $clockViewModel.selectedFont) {
                    ForEach(ClockViewModel.ClockFont.allCases) { font in
                        Text(font.rawValue).tag(font)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section("Preview") {
                HStack {
                    Spacer()
                    Text(clockViewModel.formattedTime())
                        .font(clockViewModel.selectedFont.font.weight(.medium))
                        .foregroundColor(clockViewModel.textColor)
                        .padding(clockViewModel.padding)
                        .background(
                            RoundedRectangle(cornerRadius: clockViewModel.cornerRadius)
                                .fill(clockViewModel.backgroundColor)
                                .opacity(clockViewModel.opacity)
                        )
                    Spacer()
                }
                .padding()
            }
        }
        .padding()
        .onChange(of: clockViewModel.selectedFont) { _ in saveAndUpdate() }
    }
    
    private func saveAndUpdate() {
        clockViewModel.savePreferences()
        if windowManager.isClockVisible {
            windowManager.createClockWindows()
        }
    }
}

struct FormatSettingsView: View {
    @ObservedObject var clockViewModel: ClockViewModel
    
    var body: some View {
        Form {
            Section("Time Format") {
                Picker("Format", selection: $clockViewModel.timeFormat) {
                    ForEach(ClockViewModel.TimeFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("Display Options") {
                Toggle("Show Seconds", isOn: $clockViewModel.showSeconds)
                Toggle("Show Date", isOn: $clockViewModel.showDate)
                Toggle("Show Day of Week", isOn: $clockViewModel.showDayOfWeek)
            }
            
            Section("Preview") {
                HStack {
                    Text("Current Time:")
                    Spacer()
                    Text(clockViewModel.formattedTime())
                        .font(.monospaced(.body)())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .onChange(of: clockViewModel.timeFormat) { _ in clockViewModel.savePreferences() }
        .onChange(of: clockViewModel.showSeconds) { _ in clockViewModel.savePreferences() }
        .onChange(of: clockViewModel.showDate) { _ in clockViewModel.savePreferences() }
        .onChange(of: clockViewModel.showDayOfWeek) { _ in clockViewModel.savePreferences() }
    }
}

struct DisplaySettingsView: View {
    @ObservedObject var windowManager: WindowManager
    
    var body: some View {
        Form {
            Section("Connected Displays") {
                ForEach(windowManager.displaySettings) { displaySetting in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "display")
                            Text(displaySetting.screen.localizedName)
                                .font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { displaySetting.isEnabled },
                                set: { enabled in
                                    windowManager.toggleDisplay(displaySetting.id, enabled: enabled)
                                }
                            ))
                            .labelsHidden()
                        }
                        
                        if displaySetting.isEnabled {
                            HStack {
                                Text("Position:")
                                Spacer()
                                Picker("Position", selection: Binding(
                                    get: { displaySetting.position },
                                    set: { position in
                                        windowManager.setPosition(displaySetting.id, position: position)
                                    }
                                )) {
                                    ForEach(WindowManager.DisplaySetting.WindowPosition.allCases, id: \.self) { position in
                                        Text(position.rawValue).tag(position)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 120)
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
}
