//
//  DialogContainer.swift
//  HuntScope
//
//  Gemeinsamer Container für Dialoge: Titel zentriert, Close-Button oben rechts,
//  Panel-Background, Border, CornerRadius, Shadow. Inhalt wird via @ViewBuilder übergeben.
//

import SwiftUI

struct DialogContainer<Content: View>: View {
    @EnvironmentObject private var config: ConfigStore
    @StateObject private var keyboard = KeyboardObserver()

    let title: LocalizedStringKey
    let backgroundOpacity: Double
    let onClose: () -> Void
    let content: Content

    init(title: LocalizedStringKey,
         backgroundOpacity: Double = 0.7,
         onClose: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.backgroundOpacity = backgroundOpacity
        self.onClose = onClose
        self.content = content()
    }

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Panel-Hintergrund (hinter dem Scroll-Inhalt)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(backgroundOpacity))
            RoundedRectangle(cornerRadius: 16)
                .stroke(primary.opacity(0.8), lineWidth: 1)

            // Scrollbarer Inhalt, inklusive schließendem Button (scrollt mit)
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .center, spacing: 20) {
                        Text(title)
                            .font(.title.weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(primary)

                        content

                        // füllt den verbleibenden Raum, damit der Container
                        // in der vom MainLayout vorgegebenen Höhe erscheint
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 0, alignment: .top)
                    .foregroundColor(primary)
                    .padding(24)

                    // Close-Button innerhalb des Scroll-Contents (scrollt mit)
                    Button(action: onClose) {
                        ZStack {
                            Circle().stroke(primary, lineWidth: 2)
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                }
            }
            .scrollDismissesKeyboardCompat()
            // Extra margin to ensure focused fields are fully visible
            .padding(.bottom, keyboard.height + 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}
