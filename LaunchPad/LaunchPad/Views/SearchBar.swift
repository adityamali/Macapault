//
//  SearchBar.swift
//  Macapault
//
//  Custom search bar with modern pill-shaped styling
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 13, weight: .semibold))
            
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Base layer with gradient border
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Inner glow
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                
                // Shadow layers for depth
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.05))
                    .blur(radius: 2)
            }
        )
        .frame(width: 280, height: 32)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .shadow(color: .white.opacity(0.1), radius: 1, x: 0, y: -1)
        .onAppear {
            // Auto-focus search bar when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
