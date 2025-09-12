//
//  TrialIntroDialog.swift
//  HuntScope
//

import SwiftUI

struct TrialIntroDialog: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        DialogContainer(title: "_trial_intro_title", onClose: { closeFlow() }) {
            VStack(spacing: 16) {
                Text("_trial_intro_body")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primary)

                HStack {
                    Spacer()
                    Button(action: { closeFlow() }) {
                        Text("_trial_intro_ok").bold()
                            .foregroundStyle(primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(primary, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func closeFlow() {
        // If first launch wizard should follow, show it now
        if ConfigManager.shared.hasLaunchedBefore == false {
            ui.activeDialog = .firstLaunch
            ui.isDialogActive = true
        } else {
            ui.activeDialog = nil
            ui.isDialogActive = false
        }
    }
}

