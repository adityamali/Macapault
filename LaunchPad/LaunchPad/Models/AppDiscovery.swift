//
//  AppDiscovery.swift
//  Macapault
//
//  Discovers and manages installed macOS applications
//

import Foundation
import AppKit

@MainActor
class AppDiscovery: ObservableObject {
    @Published var applications: [AppItem] = []
    @Published var isLoading = false
    
    private let applicationPaths = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities"
    ]
    private let settings = AppSettings.shared
    private var allDiscoveredApps: [AppItem] = []
    
    func discoverApplications() {
        isLoading = true
        
        Task {
            var apps: [AppItem] = []
            let fileManager = FileManager.default
            
            // Scan all application directories
            for appPath in applicationPaths {
                guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: appPath),
                                                              includingPropertiesForKeys: [.isDirectoryKey],
                                                              options: [.skipsHiddenFiles]) else {
                    continue
                }
                
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        // Skip subdirectories within .app bundles
                        enumerator.skipDescendants()
                        
                        if let app = createAppItem(from: fileURL) {
                            // Avoid duplicates
                            if !apps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
                                apps.append(app)
                            }
                        }
                    }
                }
            }
            
            await MainActor.run {
                self.allDiscoveredApps = apps
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        }
    }
    
    func applyFiltersAndSort() {
        var filtered = allDiscoveredApps
        
        // Filter out hidden apps only (always show iOS apps)
        filtered = filtered.filter { app in
            !settings.isHidden(bundleId: app.bundleIdentifier)
        }
        
        // Apply sorting - alphabetical by default, or custom order if user has rearranged
        if !settings.customAppOrder.isEmpty {
            // User has customized the order via drag-and-drop
            filtered.sort { app1, app2 in
                let index1 = settings.customAppOrder.firstIndex(of: app1.bundleIdentifier) ?? Int.max
                let index2 = settings.customAppOrder.firstIndex(of: app2.bundleIdentifier) ?? Int.max
                return index1 < index2
            }
        } else {
            // Default alphabetical sorting
            filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        applications = filtered
    }
    
    private func createAppItem(from url: URL) -> AppItem? {
        let name = url.deletingPathExtension().lastPathComponent
        
        // Get bundle
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else {
            return nil
        }
        
        // Detect if this is an iPhone app
        let isiPhoneApp = detectiPhoneApp(bundle: bundle)
        
        // Get app icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 128, height: 128)
        
        return AppItem(name: name,
                      bundleIdentifier: bundleID,
                      path: url,
                      icon: icon,
                      isiPhoneApp: isiPhoneApp)
    }
    
    private func detectiPhoneApp(bundle: Bundle) -> Bool {
        // NOTE: This is a placeholder for remote iPhone app detection
        // Full implementation would require:
        // 1. Continuity/Handoff framework access
        // 2. Private APIs that Apple uses in Spotlight
        // 3. Active iPhone connection via Universal Control/Continuity
        
        // For now, we can only detect iOS apps running on macOS via Catalyst
        // Check if the app is an iOS app running on macOS
        if let platforms = bundle.infoDictionary?["CFBundleSupportedPlatforms"] as? [String] {
            return platforms.contains("iPhoneOS") || platforms.contains("iPhoneSimulator")
        }
        
        // Check for UIDeviceFamily (iOS specific)
        if bundle.infoDictionary?["UIDeviceFamily"] != nil {
            return true
        }
        
        return false
    }
    
    // TODO: Add method to discover remote iPhone apps
    // This would require accessing Continuity services which may use private APIs
    // func discoverRemoteiPhoneApps() { }
    
    func launchApplication(_ app: AppItem) {
        if app.isiPhoneApp {
            // For remote iPhone apps, we would need to:
            // 1. Trigger app launch via Continuity
            // 2. Use NSUserActivity or similar to open on iPhone
            // Currently just launches local iOS apps
        }
        
        NSWorkspace.shared.openApplication(at: app.path,
                                          configuration: NSWorkspace.OpenConfiguration(),
                                          completionHandler: nil)
    }
    
    func deleteApplication(_ app: AppItem) {
        let fileManager = FileManager.default
        
        do {
            // Move to trash instead of permanent deletion
            var resultingURL: NSURL?
            try fileManager.trashItem(at: app.path, resultingItemURL: &resultingURL)
            
            // Refresh apps list
            discoverApplications()
        } catch {
            print("Error deleting app: \(error.localizedDescription)")
        }
    }
    
    func moveApp(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < applications.count,
              destinationIndex >= 0, destinationIndex < applications.count else {
            return
        }
        
        var mutableApps = applications
        let movedApp = mutableApps.remove(at: sourceIndex)
        mutableApps.insert(movedApp, at: destinationIndex)
        applications = mutableApps
        
        // Update custom order
        saveCustomOrder()
    }
    
    func saveCustomOrder() {
        settings.customAppOrder = applications.map { $0.bundleIdentifier }
    }
}
