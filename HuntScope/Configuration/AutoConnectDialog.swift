//
//  AutoConnectDialog.swift
//  HuntScope
//
//  Kleiner, modaler Overlay-Dialog für Auto-Connect.
//

import SwiftUI

enum AutoConnectState {
    case scanning
    case success
    case notFound
}

struct AutoConnectDialog: View {
    @EnvironmentObject private var config: ConfigStore

    var state: AutoConnectState
    var onCancel: () -> Void
    var onClose: () -> Void
    var scanningTitle: String?
    var successTitle: String?
    var notFoundTitle: String?

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        VStack(spacing: 16) {
            // Zeile 1 – Status-Text
            Text(titleText)
                .font(.headline)
                .foregroundStyle(primary)

            // Zeile 2 – Fortschritt (nur beim Scannen)
            if state == .scanning {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(primary)
            }

            // Zeile 3 – Aktion
            if state == .scanning {
                Button(action: onCancel) {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(primary)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onClose) {
                    Text("_configuration_close").bold()
                        .foregroundStyle(primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(primary, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .background(Color.black.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(primary.opacity(0.9), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(radius: 8)
    }

    private var titleText: String {
        switch state {
        case .scanning: return scanningTitle ?? String(localized: "_configuration_autoconnect_scanning")
        case .success: return successTitle ?? String(localized: "_configuration_autoconnect_success")
        case .notFound: return notFoundTitle ?? String(localized: "_configuration_autoconnect_not_found")
        }
    }
}
