//  FolderIconView.swift
//  Macapault
//
//  Visual representation of a folder icon
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderIconView: View {
    let folder: FolderItem
    let apps: [AppItem]
    let onOpen: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onAddApp: (AppItem) -> Void
    
    @State private var isHovered = false
    @State private var isDropTarget = false
    
    // Get first 9 apps in folder for preview
    private var previewApps: [AppItem] {
        let bundleIds = Array(folder.appBundleIds.prefix(9))
        return bundleIds.compactMap { bundleId in
            apps.first { $0.bundleIdentifier == bundleId }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Folder icon with app previews
            ZStack {
                // Folder background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(isHovered ? 0.3 : 0.1),
                           radius: isHovered ? 12 : 6,
                           x: 0,
                           y: isHovered ? 6 : 3)
                
                // Drop indicator
                if isDropTarget {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
                
                // App icon previews in 3x3 grid
                if !previewApps.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                        ForEach(previewApps.prefix(9), id: \.id) { app in
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)
                }
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            // Folder name
            Text(folder.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(width: 100)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onOpen()
        }
        .onDrop(of: [UTType.plainText], delegate: FolderDropDelegate(
            folder: folder,
            isDropTarget: $isDropTarget,
            onAddApp: onAddApp
        ))
        .contextMenu {
            Button("Rename Folder") {
                onRename()
            }
            Button("Delete Folder", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct FolderDropDelegate: DropDelegate {
    let folder: FolderItem
    @Binding var isDropTarget: Bool
    let onAddApp: (AppItem) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        isDropTarget = false
        // The actual app adding is handled by the parent view
        return true
    }
    
    func dropEntered(info: DropInfo) {
        isDropTarget = true
    }
    
    func dropExited(info: DropInfo) {
        isDropTarget = false
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .copy)
    }
}
