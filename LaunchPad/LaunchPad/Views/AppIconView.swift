//
//  AppIconView.swift
//  Macapault
//
//  Individual app icon with hover effects and edit mode
//

import SwiftUI

struct AppIconView: View {
    let app: AppItem
    var isEditMode: Bool = false
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var wiggleOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                // App icon
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(isHovered ? 0.3 : 0.1),
                           radius: isHovered ? 8 : 4,
                           x: 0,
                           y: isHovered ? 4 : 2)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .rotationEffect(.degrees(isEditMode ? wiggleOffset : 0))
                
                // App name
                Text(app.name)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100, height: 32)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            // Delete button in edit mode
            if isEditMode, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
        }
        .frame(width: 120, height: 110)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if isEditMode {
                startWiggle()
            }
        }
        .onChange(of: isEditMode) { newValue in
            if newValue {
                startWiggle()
            } else {
                wiggleOffset = 0
            }
        }
    }
    
    private func startWiggle() {
        let duration = 0.15
        let angle: CGFloat = 2.0
        
        withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            wiggleOffset = angle
        }
    }
}
