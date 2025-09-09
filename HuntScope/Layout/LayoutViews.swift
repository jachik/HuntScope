//
//  LayoutViews.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI

// Zentraler Zustand: steuert, ob ein Dialog aktiv ist
@MainActor
final class UIStateModel: ObservableObject {
    @Published var isDialogActive: Bool = false
}

// Placeholder fuer den RTSP/VLC-Stream
struct StreamView: View {
    @EnvironmentObject private var config: ConfigStore
    var body: some View {
        ZStack {
            Color.black
            Text("StreamView (VLC kommt hier rein)")
                .foregroundColor((config.theme == .red) ? .red : .white)
                .font(.footnote)
        }
        .ignoresSafeArea()
    }
}



// Vollbild-Layer fuer Dialoge, liegt ueber dem Stream
struct DialogOverlay<Content: View>: View {
    let isVisible: Bool
    let content: Content

    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.content = content()
    }

    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    // Abdunkeln des Streams, falls gewuenscht
                    Color.black.opacity(0.5).ignoresSafeArea()
                    content
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
