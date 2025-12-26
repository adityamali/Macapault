//
//  PagedGridView.swift
//  Macapault
//
//  Horizontal paging grid view with ScrollView
//

import SwiftUI
import UniformTypeIdentifiers

// Grid item can be either an app or a folder
enum GridItemType: Identifiable {
    case app(AppItem)
    case folder(FolderItem)
    
    var id: String {
        switch self {
        case .app(let item): return item.id.uuidString
        case .folder(let item): return item.id.uuidString
        }
    }
}

struct PagedGridView: View {
    let apps: [AppItem]
    let isEditMode: Bool
    let onLaunch: (AppItem) -> Void
    let onDelete: (AppItem) -> Void
    let onHide: (AppItem) -> Void
    let onMove: (Int, Int) -> Void
    
    @State private var currentPage: Int? = 0
    @State private var draggedApp: AppItem?
    @State private var openFolder: FolderItem?
    @ObservedObject private var settings = AppSettings.shared
    
    private let columns = 7
    private let rows = 5
    private var appsPerPage: Int { columns * rows }
    
    // Combine apps and folders into grid items
    private var gridItems: [GridItemType] {
        var items: [GridItemType] = []
        
        // Add folders first
        for folder in settings.folders {
            items.append(.folder(folder))
        }
        
        // Add apps that are not in folders
        for app in apps {
            if !settings.isFolderApp(bundleId: app.bundleIdentifier) {
                items.append(.app(app))
            }
        }
        
        return items
    }
    
    private var pages: [[GridItemType]] {
        stride(from: 0, to: gridItems.count, by: appsPerPage).map {
            Array(gridItems[$0..<min($0 + appsPerPage, gridItems.count)])
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Scrollable paged content
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, pageItems in
                            GridView(
                                items: pageItems,
                                apps: apps,
                                columns: columns,
                                isEditMode: isEditMode,
                                draggedApp: $draggedApp,
                                onLaunch: onLaunch,
                                onDelete: onDelete,
                                onHide: onHide,
                                onMove: onMove,
                                onOpenFolder: { folder in
                                    openFolder = folder
                                },
                                onCreateFolder: createFolder
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(pageIndex)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentPage)
                
                // Page indicators overlay at bottom
                VStack {
                    Spacer()
                    
                    if pages.count > 1 {
                        HStack(spacing: 10) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == (currentPage ?? 0) ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 7, height: 7)
                                    .scaleEffect(index == (currentPage ?? 0) ? 1.4 : 1.0)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                    .onTapGesture {
                                        withAnimation {
                                            currentPage = index
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
                .allowsHitTesting(true)
                
                // Folder content overlay
                if let folder = openFolder {
                    FolderContentView(
                        folder: folder,
                        apps: apps,
                        onClose: {
                            openFolder = nil
                        },
                        onLaunch: { app in
                            onLaunch(app)
                            openFolder = nil
                        },
                        onRemoveApp: { app in
                            settings.removeAppFromFolder(folderId: folder.id, bundleId: app.bundleIdentifier)
                        }
                    )
                }
            }
        }
        .onAppear {
            print("PagedGridView loaded with \(pages.count) pages, \(gridItems.count) items")
        }
    }
    
    private func createFolder(app1: AppItem, app2: AppItem) {
        let suggestedName = FolderItem.suggestName(for: [app1, app2])
        _ = settings.createFolder(name: suggestedName, appBundleIds: [app1.bundleIdentifier, app2.bundleIdentifier])
    }
}

struct GridView: View {
    let items: [GridItemType]
    let apps: [AppItem]
    let columns: Int
    let isEditMode: Bool
    @Binding var draggedApp: AppItem?
    let onLaunch: (AppItem) -> Void
    let onDelete: (AppItem) -> Void
    let onHide: (AppItem) -> Void
    let onMove: (Int, Int) -> Void
    let onOpenFolder: (FolderItem) -> Void
    let onCreateFolder: (AppItem, AppItem) -> Void
    
    @ObservedObject private var settings = AppSettings.shared
    @State private var dropTargetApp: AppItem?
    @State private var hoverStartTime: Date?
    
    var body: some View {
        VStack {
            Spacer()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: columns), spacing: 30) {
                ForEach(items) { item in
                    switch item {
                    case .app(let app):
                        AppIconView(
                            app: app,
                            isEditMode: isEditMode,
                            onDelete: isEditMode ? {
                                onDelete(app)
                            } : nil
                        )
                            .opacity(draggedApp?.id == app.id ? 0.5 : 1.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                    .opacity(dropTargetApp?.id == app.id ? 1 : 0)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLaunch(app)
                            }
                            .onDrag {
                                self.draggedApp = app
                                let provider = NSItemProvider()
                                provider.suggestedName = app.name
                                provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
                                    let data = app.bundleIdentifier.data(using: .utf8)
                                    completion(data, nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [UTType.plainText], delegate: AppDropDelegate(
                                targetApp: app,
                                allApps: items.compactMap { item in
                                    if case .app(let a) = item { return a }
                                    return nil
                                },
                                draggedApp: $draggedApp,
                                dropTargetApp: $dropTargetApp,
                                hoverStartTime: $hoverStartTime,
                                onMove: { from, to in
                                    // Find indices in original apps array
                                    let pageApps: [AppItem] = items.compactMap { item in
                                        if case .app(let appItem) = item { return appItem }
                                        return nil
                                    }
                                    
                                    if let fromApp = pageApps[safe: from],
                                       let toApp = pageApps[safe: to],
                                       let fromIdx = apps.firstIndex(where: { $0.id == fromApp.id }),
                                       let toIdx = apps.firstIndex(where: { $0.id == toApp.id }) {
                                        onMove(fromIdx, toIdx)
                                    }
                                },
                                onCreateFolder: onCreateFolder
                            ))
                            .contextMenu {
                                Button("Hide App") {
                                    onHide(app)
                                }
                                Button("Delete App", role: .destructive) {
                                    onDelete(app)
                                }
                                Divider()
                                Button("Show in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([app.path])
                                }
                            }
                        
                    case .folder(let folder):
                        FolderIconView(
                            folder: folder,
                            apps: apps,
                            onOpen: {
                                onOpenFolder(folder)
                            },
                            onRename: {
                                // Rename handled in FolderContentView
                            },
                            onDelete: {
                                settings.deleteFolder(id: folder.id)
                            },
                            onAddApp: { app in
                                settings.addAppToFolder(folderId: folder.id, bundleId: app.bundleIdentifier)
                            }
                        )
                        .onDrop(of: [UTType.plainText], delegate: AppDropToFolderDelegate(
                            folder: folder,
                            draggedApp: $draggedApp,
                            onAddToFolder: { app in
                                settings.addAppToFolder(folderId: folder.id, bundleId: app.bundleIdentifier)
                            }
                        ))
                    }
                }
            }
            .padding(.horizontal, 80)
            
            Spacer()
        }
    }
}

struct AppDropDelegate: DropDelegate {
    let targetApp: AppItem
    let allApps: [AppItem]
    @Binding var draggedApp: AppItem?
    @Binding var dropTargetApp: AppItem?
    @Binding var hoverStartTime: Date?
    let onMove: (Int, Int) -> Void
    let onCreateFolder: (AppItem, AppItem) -> Void
    
    private let hoverThreshold: TimeInterval = 0.5 // Half second to create folder
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedApp = draggedApp,
              draggedApp.id != targetApp.id else {
            self.draggedApp = nil
            dropTargetApp = nil
            hoverStartTime = nil
            return false
        }
        
        // Check if we hovered long enough to create a folder
        if let hoverStart = hoverStartTime,
           Date().timeIntervalSince(hoverStart) >= hoverThreshold {
            // Create folder
            onCreateFolder(draggedApp, targetApp)
        } else {
            // Rearrange apps
            if let fromIndex = allApps.firstIndex(where: { $0.id == draggedApp.id }),
               let toIndex = allApps.firstIndex(where: { $0.id == targetApp.id }) {
                onMove(fromIndex, toIndex)
            }
        }
        
        self.draggedApp = nil
        dropTargetApp = nil
        hoverStartTime = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedApp = draggedApp, draggedApp.id != targetApp.id {
            dropTargetApp = targetApp
            hoverStartTime = Date()
        }
    }
    
    func dropExited(info: DropInfo) {
        dropTargetApp = nil
        hoverStartTime = nil
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        if let draggedApp = draggedApp, draggedApp.id != targetApp.id {
            // Check if hovering long enough for folder creation
            if let hoverStart = hoverStartTime,
               Date().timeIntervalSince(hoverStart) >= hoverThreshold {
                return DropProposal(operation: .copy) // Create folder
            }
            return DropProposal(operation: .move) // Rearrange
        }
        return DropProposal(operation: .forbidden)
    }
}

struct AppDropToFolderDelegate: DropDelegate {
    let folder: FolderItem
    @Binding var draggedApp: AppItem?
    let onAddToFolder: (AppItem) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedApp = draggedApp else {
            return false
        }
        
        // Add app to folder
        onAddToFolder(draggedApp)
        
        self.draggedApp = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .copy)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return draggedApp != nil
    }
}

// Collection extension for safe indexing
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
