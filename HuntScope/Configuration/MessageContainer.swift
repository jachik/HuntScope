//
//  MessageContainer.swift
//  HuntScope
//
//  Kleiner Hinweis-Container: kompakter als DialogContainer,
//  nur Nachricht + OK-Button im Theme-Look.
//

import SwiftUI

struct MessageContainer: View {
    @EnvironmentObject private var config: ConfigStore

    let message: String
    let buttonTitle: String
    let onClose: () -> Void

    private var primary: Color { (config.theme == .red) ? .red : .white }

    init(message: String, buttonTitle: String = String(localized: "_configuration_ok"), onClose: @escaping () -> Void) {
        self.message = message
        self.buttonTitle = buttonTitle
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(primary)

            Button(action: onClose) {
                Text(buttonTitle).bold()
                    .foregroundStyle(primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(primary, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: 360)
        .background(Color.black.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(primary.opacity(0.9), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
