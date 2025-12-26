//
//  ContentView.swift
//  Macapault
//
//  Main view displaying the application grid with inline settings
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appDiscovery = AppDiscovery()
    @ObservedObject private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var eventMonitor: Any?
    @State private var showDeleteConfirmation = false
    @State private var appToDelete: AppItem?
    @State private var desktopImage: NSImage?
    @State private var isEditMode = false
    @Environment(\.dismiss) private var dismiss
    
    var filteredApps: [AppItem] {
        if searchText.isEmpty {
            return appDiscovery.applications
        } else {
            return appDiscovery.applications.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Desktop wallpaper background with blur and overlay
            if let desktopImage = desktopImage {
                Image(nsImage: desktopImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
                    .ignoresSafeArea()
                
                // Dark overlay for better contrast
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            } else {
                // Fallback to gradient background if wallpaper can't load
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.15, green: 0.1, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 15) {
                // Header with search and edit button
                HStack(spacing: 20) {
                    SearchBar(text: $searchText)
                        .frame(maxWidth: 400)
                    
                    
                    Button(action: {
                        isEditMode.toggle()
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isEditMode ? Color.blue : Color.white.opacity(0.2))
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 80)
                .padding(.top, 30)
                
                if appDiscovery.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Discovering applications...")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14))
                    Spacer()
                } else if filteredApps.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "app.dashed" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text(searchText.isEmpty ? "No applications found" : "No results for '\(searchText)'")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                } else {
                    // Always use paged grid with horizontal scrolling
                    PagedGridView(
                        apps: filteredApps,
                        isEditMode: isEditMode,
                        onLaunch: { app in
                            appDiscovery.launchApplication(app)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                NSApplication.shared.hide(nil)
                            }
                        },
                        onDelete: { app in
                            appToDelete = app
                            showDeleteConfirmation = true
                        },
                        onHide: { app in
                            settings.hideApp(bundleId: app.bundleIdentifier)
                            appDiscovery.applyFiltersAndSort()
                        },
                        onMove: { from, to in
                            appDiscovery.moveApp(from: from, to: to)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadDesktopWallpaper()
            appDiscovery.discoverApplications()
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .alert("Delete Application", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let app = appToDelete {
                    appDiscovery.deleteApplication(app)
                }
            }
        } message: {
            if let app = appToDelete {
                Text("Are you sure you want to move \(app.name) to the Trash? This action cannot be undone.")
            }
        }
    }
    
    private func loadDesktopWallpaper() {
        if let screen = NSScreen.main {
            if let imageURL = NSWorkspace.shared.desktopImageURL(for: screen) {
                // Load the image data first, then create NSImage from data
                // This properly handles HEIC and other formats
                do {
                    let imageData = try Data(contentsOf: imageURL)
                    if let image = NSImage(data: imageData) {
                        // Validate the image has actual size
                        if image.size.width > 0 && image.size.height > 0 {
                            print("Desktop image loaded successfully: \(imageURL.lastPathComponent), size: \(image.size)")
                            desktopImage = image
                        } else {
                            print("Image loaded but has zero size")
                        }
                    } else {
                        print("Could not create NSImage from data")
                    }
                } catch {
                    print("Error loading image data: \(error.localizedDescription)")
                }
            } else {
                print("Could not get desktop image URL")
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                NSApplication.shared.hide(nil)
                return nil
            }
            return event
        }
    }
    
    private func removeKeyboardMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

#Preview {
    ContentView()
}
