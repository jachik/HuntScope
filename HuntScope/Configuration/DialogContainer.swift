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

    let title: String
    let backgroundOpacity: Double
    let onClose: () -> Void
    let content: Content

    init(title: String,
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
            // fülle die vom MainLayout vorgegebene Center-Fläche vollständig
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .foregroundColor(primary)
            .padding(24)
            .background(Color.black.opacity(backgroundOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(primary.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(radius: 8)

            Button(action: onClose) {
                ZStack {
                    Circle().stroke(primary, lineWidth: 2)
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(primary)
                }
                .frame(width: 44, height: 44)
                .padding(.top, 15)
                .padding(.trailing, 15)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .padding(.top, 5)
            .padding(.trailing, 5)
        }
    }
}
