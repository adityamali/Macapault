//
//  AppSettings.swift
//  Macapault
//
//  Settings manager for user preferences and app configuration
//

import Foundation
import SwiftUI

enum DisplayMode: String, Codable, CaseIterable {
    case paged = "Paged Grid"
    case scrolling = "Scrolling Grid"
}

enum SortMode: String, Codable, CaseIterable {
    case manual = "Manual Order"
    case alphabetical = "Alphabetical"
}

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var displayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: "displayMode")
        }
    }
    
    @Published var sortMode: SortMode {
        didSet {
            UserDefaults.standard.set(sortMode.rawValue, forKey: "sortMode")
        }
    }
    
    @Published var showiPhoneApps: Bool {
        didSet {
            UserDefaults.standard.set(showiPhoneApps, forKey: "showIPhoneApps")
        }
    }
    
    @Published var customAppOrder: [String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(customAppOrder) {
                UserDefaults.standard.set(encoded, forKey: "customAppOrder")
            }
        }
    }
    
    @Published var hiddenApps: Set<String> {
        didSet {
            if let encoded = try? JSONEncoder().encode(hiddenApps) {
                UserDefaults.standard.set(encoded, forKey: "hiddenApps")
            }
        }
    }
    
    @Published var folders: [FolderItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(folders) {
                UserDefaults.standard.set(encoded, forKey: "folders")
            }
        }
    }
    
    private init() {
        // Load display mode
        if let saved = UserDefaults.standard.string(forKey: "displayMode"),
           let mode = DisplayMode(rawValue: saved) {
            self.displayMode = mode
        } else {
            self.displayMode = .scrolling
        }
        
        // Load sort mode
        if let saved = UserDefaults.standard.string(forKey: "sortMode"),
           let mode = SortMode(rawValue: saved) {
            self.sortMode = mode
        } else {
            self.sortMode = .alphabetical
        }
        
        // Load iPhone apps preference
        self.showiPhoneApps = UserDefaults.standard.bool(forKey: "showIPhoneApps")
        
        // Load custom app order
        if let data = UserDefaults.standard.data(forKey: "customAppOrder"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.customAppOrder = decoded
        } else {
            self.customAppOrder = []
        }
        
        // Load hidden apps
        if let data = UserDefaults.standard.data(forKey: "hiddenApps"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.hiddenApps = decoded
        } else {
            self.hiddenApps = []
        }
        
        // Load folders
        if let data = UserDefaults.standard.data(forKey: "folders"),
           let decoded = try? JSONDecoder().decode([FolderItem].self, from: data) {
            self.folders = decoded
        } else {
            self.folders = []
        }
    }
    
    func resetToDefaults() {
        displayMode = .scrolling
        sortMode = .alphabetical
        showiPhoneApps = false
        customAppOrder = []
        hiddenApps = []
        folders = []
    }
    
    func hideApp(bundleId: String) {
        hiddenApps.insert(bundleId)
    }
    
    func unhideApp(bundleId: String) {
        hiddenApps.remove(bundleId)
    }
    
    func isHidden(bundleId: String) -> Bool {
        hiddenApps.contains(bundleId)
    }
    
    // MARK: - Folder Management
    
    func createFolder(name: String, appBundleIds: [String]) -> FolderItem {
        let folder = FolderItem(name: name, appBundleIds: appBundleIds)
        folders.append(folder)
        return folder
    }
    
    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
    }
    
    func renameFolder(id: UUID, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].name = newName
        }
    }
    
    func addAppToFolder(folderId: UUID, bundleId: String) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            if !folders[index].appBundleIds.contains(bundleId) {
                folders[index].appBundleIds.append(bundleId)
            }
        }
    }
    
    func removeAppFromFolder(folderId: UUID, bundleId: String) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].appBundleIds.removeAll { $0 == bundleId }
            // Delete folder if empty
            if folders[index].appBundleIds.isEmpty {
                deleteFolder(id: folderId)
            }
        }
    }
    
    func isFolderApp(bundleId: String) -> Bool {
        folders.contains { $0.appBundleIds.contains(bundleId) }
    }
    
    func getFolderFor(bundleId: String) -> FolderItem? {
        folders.first { $0.appBundleIds.contains(bundleId) }
    }
}
