//
//  MessageDialog.swift
//  HuntScope
//
//  Kleiner generischer Meldungsdialog im gleichen Stil wie die anderen Dialoge.
//

import SwiftUI

struct MessageDialog: View {
    @EnvironmentObject private var config: ConfigStore

    let title: String
    let message: String
    let buttonTitle: String
    let onClose: () -> Void

    init(title: String,
         message: String,
         buttonTitle: String = "OK",
         onClose: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.onClose = onClose
    }

    var body: some View {
        // Kleinere, kompakte Variante ohne DialogContainer
        MessageContainer(message: message, buttonTitle: buttonTitle, onClose: onClose)
            .environmentObject(config)
    }
}
