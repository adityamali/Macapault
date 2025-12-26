//
//  ScrollingGridView.swift
//  Macapault
//
//  Vertical scrolling grid view with drag and drop
//

import SwiftUI
import UniformTypeIdentifiers

struct ScrollingGridView: View {
    let apps: [AppItem]
    let onLaunch: (AppItem) -> Void
    let onDelete: (AppItem) -> Void
    let onHide: (AppItem) -> Void
    let onMove: (Int, Int) -> Void
    
    @State private var draggedItem: AppItem?
    @State private var isPressingItem: UUID? = nil
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 7)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                    AppIconView(app: app)
                        .scaleEffect(isPressingItem == app.id ? 0.95 : 1.0)
                        .opacity(draggedItem?.id == app.id ? 0.5 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onLaunch(app)
                        }
                        .onDrag {
                            self.draggedItem = app
                            // Create a proper draggable item
                            let provider = NSItemProvider()
                            provider.suggestedName = app.name
                            // Register the bundle ID as plain text for drop detection
                            provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
                                let data = app.bundleIdentifier.data(using: .utf8)
                                completion(data, nil)
                                return nil
                            }
                            return provider
                        }
                        .onDrop(of: [UTType.plainText], delegate: AppDropDelegate(
                            item: app,
                            items: apps,
                            draggedItem: $draggedItem,
                            onMove: onMove
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
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 60)
        }
    }
}

struct AppDropDelegate: DropDelegate {
    let item: AppItem
    let items: [AppItem]
    @Binding var draggedItem: AppItem?
    let onMove: (Int, Int) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        onMove(fromIndex, toIndex)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return draggedItem != nil
    }
}
