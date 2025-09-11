//
//  TestConfigView.swift
//  HuntScope
//
//  Beispiel-Dialog, der den neuen DialogContainer nutzt.
//

import SwiftUI

struct TestConfigView: View {
    @EnvironmentObject private var ui: UIStateModel

    var body: some View {
        DialogContainer(title: "_configuration_test_title", onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            VStack(spacing: 12) {
                Text("_configuration_test_body")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Text("_configuration_test_note")
                    .font(.footnote)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
