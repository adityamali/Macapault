//
//  FolderContentView.swift
//  Macapault
//
//  Overlay view showing folder contents
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderContentView: View {
    let folder: FolderItem
    let apps: [AppItem]
    let onClose: () -> Void
    let onLaunch: (AppItem) -> Void
    let onRemoveApp: (AppItem) -> Void
    
    @State private var folderName: String
    @ObservedObject private var settings = AppSettings.shared
    @State private var isEditing = false
    @State private var showingAppPicker = false
    
    init(folder: FolderItem, apps: [AppItem], onClose: @escaping () -> Void, onLaunch: @escaping (AppItem) -> Void, onRemoveApp: @escaping (AppItem) -> Void) {
        self.folder = folder
        self.apps = apps
        self.onClose = onClose
        self.onLaunch = onLaunch
        self.onRemoveApp = onRemoveApp
        _folderName = State(initialValue: folder.name)
    }
    
    private var folderApps: [AppItem] {
        folder.appBundleIds.compactMap { bundleId in
            apps.first { $0.bundleIdentifier == bundleId }
        }
    }
    
    // Apps not in folder
    private var availableApps: [AppItem] {
        apps.filter { app in
            !folder.appBundleIds.contains(app.bundleIdentifier) &&
            !settings.isFolderApp(bundleId: app.bundleIdentifier)
        }
    }
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    saveFolderName()
                    onClose()
                }
            
            // Folder content
            VStack(spacing: 30) {
                // Header with folder name and controls
                HStack {
                    if isEditing {
                        TextField("Folder Name", text: $folderName, onCommit: {
                            saveFolderName()
                            isEditing = false
                        })
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 300)
                    } else {
                        Text(folderName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .onTapGesture {
                                isEditing = true
                            }
                    }
                    
                    Spacer()
                    
                    // Add app button
                    Button(action: {
                        showingAppPicker.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingAppPicker) {
                        AppPickerView(
                            availableApps: availableApps,
                            onSelectApp: { app in
                                settings.addAppToFolder(folderId: folder.id, bundleId: app.bundleIdentifier)
                                showingAppPicker = false
                            }
                        )
                    }
                    
                    Button(action: {
                        saveFolderName()
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                
                // Apps grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 5), spacing: 30) {
                        ForEach(folderApps, id: \.id) { app in
                            AppIconView(app: app)
                                .onTapGesture {
                                    onLaunch(app)
                                }
                                .contextMenu {
                                    Button("Remove from Folder") {
                                        onRemoveApp(app)
                                    }
                                    Button("Hide App") {
                                        settings.hideApp(bundleId: app.bundleIdentifier)
                                    }
                                    Divider()
                                    Button("Show in Finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([app.path])
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 500)
            }
            .padding(.vertical, 40)
            .frame(width: 700)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private func saveFolderName() {
        if !folderName.isEmpty && folderName != folder.name {
            settings.renameFolder(id: folder.id, newName: folderName)
        }
    }
}

// App picker for adding apps to folder
struct AppPickerView: View {
    let availableApps: [AppItem]
    let onSelectApp: (AppItem) -> Void
    
    @State private var searchText = ""
    
    private var filteredApps: [AppItem] {
        if searchText.isEmpty {
            return availableApps
        }
        return availableApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Divider()
            
            // App list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredApps, id: \.id) { app in
                        Button(action: {
                            onSelectApp(app)
                        }) {
                            HStack(spacing: 12) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(6)
                                
                                Text(app.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.clear)
                        .onHover { hovering in
                            // Hover effect handled by button
                        }
                        
                        Divider()
                    }
                }
            }
            .frame(width: 300, height: 400)
        }
    }
}
