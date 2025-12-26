//
//  MacapaultApp.swift
//  Macapault
//
//  Main app entry point with keyboard shortcuts
//

import SwiftUI
import AppKit

@main
struct MacapaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Remove some default menu items
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the main window
        if let window = NSApplication.shared.windows.first {
            self.window = window
            
            // Remove all window decorations
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            
            // Make window float above everything except menu bar
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            // Make it non-movable
            window.isMovable = false
            window.isMovableByWindowBackground = false
            
            // Set window to cover screen EXCEPT menu bar
            if let screen = NSScreen.main {
                var frame = screen.frame
                // Subtract menu bar height (typically 25 points)
                let menuBarHeight: CGFloat = 25
                frame.origin.y = 0
                frame.size.height -= menuBarHeight
                window.setFrame(frame, display: true)
            }
            
            // Make background opaque (so we show our wallpaper, not blur through to other windows)
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            
            // Set dark appearance for menu bar
            window.appearance = NSAppearance(named: .darkAqua)
            
            // Ensure it can become key window
            window.acceptsMouseMovedEvents = true
        }
        
        // Set up global keyboard shortcut (F4 key)
        setupGlobalShortcut()
        
        // Don't show in Dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupGlobalShortcut() {
        // Monitor for F4 key press
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // F4 key code is 118
            if event.keyCode == 118 {
                self.toggleMacapault()
            }
        }
        
        // Also monitor local events (when app is active)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 118 {
                self.toggleMacapault()
                return nil
            }
            return event
        }
    }
    
    func toggleMacapault() {
        DispatchQueue.main.async {
            if let window = self.window {
                if window.isVisible && NSApp.isActive {
                    NSApp.hide(nil)
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
