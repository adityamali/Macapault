//
//  FolderItem.swift
//  Macapault
//
//  Data model representing a folder containing apps
//

import Foundation

struct FolderItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var appBundleIds: [String]
    
    init(id: UUID = UUID(), name: String, appBundleIds: [String]) {
        self.id = id
        self.name = name
        self.appBundleIds = appBundleIds
    }
    
    // Default folder name based on contained apps
    static func suggestName(for apps: [AppItem]) -> String {
        if apps.isEmpty { return "Folder" }
        
        // Simple category detection based on common patterns
        let names = apps.map { $0.name.lowercased() }
        
        if names.contains(where: { $0.contains("office") || $0.contains("word") || $0.contains("excel") }) {
            return "Productivity"
        } else if names.contains(where: { $0.contains("chrome") || $0.contains("safari") || $0.contains("firefox") }) {
            return "Web"
        } else if names.contains(where: { $0.contains("xcode") || $0.contains("terminal") || $0.contains("code") }) {
            return "Development"
        } else if names.contains(where: { $0.contains("photoshop") || $0.contains("illustrator") || $0.contains("figma") }) {
            return "Design"
        }
        
        return "Folder"
    }
}
