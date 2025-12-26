//
//  SettingsView.swift
//  Macapault
//
//  Settings panel for user preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Display Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display Mode")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Picker("Display Mode", selection: $settings.displayMode) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Choose between paginated pages or vertical scrolling grid")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Sort Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sort Order")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Picker("Sort Mode", selection: $settings.sortMode) {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Apps can be arranged manually or sorted alphabetically")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // iOS Apps Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $settings.showiPhoneApps) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show iOS Apps on Mac")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Display iOS/iPadOS apps running on this Mac (Catalyst apps)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Text("Note: Showing remote iPhone apps requires Continuity APIs not yet implemented")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow.opacity(0.8))
                            .padding(.top, 4)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Reset Button
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 450, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values, including hidden apps and custom ordering.")
        }
    }
}

#Preview {
    SettingsView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
}
