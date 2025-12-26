//
//  AppItem.swift
//  Macapault
//
//  Data model representing a macOS application
//

import Foundation
import AppKit

struct AppItem: Identifiable, Equatable, Codable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: URL
    var icon: NSImage
    let isiPhoneApp: Bool
    
    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.path == rhs.path && lhs.name == rhs.name
    }
    
    enum CodingKeys: String, CodingKey {
        case name, bundleIdentifier, path, isiPhoneApp
    }
    
    init(name: String, bundleIdentifier: String, path: URL, icon: NSImage, isiPhoneApp: Bool = false) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
        self.isiPhoneApp = isiPhoneApp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        path = try container.decode(URL.self, forKey: .path)
        isiPhoneApp = try container.decode(Bool.self, forKey: .isiPhoneApp)
        
        // Load icon from path
        icon = NSWorkspace.shared.icon(forFile: path.path)
        icon.size = NSSize(width: 128, height: 128)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(path, forKey: .path)
        try container.encode(isiPhoneApp, forKey: .isiPhoneApp)
    }
}
