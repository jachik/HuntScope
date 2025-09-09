//
//  LeftButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
import SwiftUI
import UIKit


// Linke Button-Area: zeigt nur Status-Symbole (keine Interaktion)
struct LeftButtonArea<DialogButtons: View>: View {
    @EnvironmentObject private var config: ConfigStore
    @StateObject private var battery = BatteryMonitor()
    let dialogButtons: DialogButtons // ignoriert (keine Dialog-Buttons mehr links)
    let showDialogButtons: Bool      // ignoriert

    init(showDialogButtons: Bool, @ViewBuilder dialogButtons: () -> DialogButtons) {
        self.showDialogButtons = showDialogButtons
        self.dialogButtons = dialogButtons()
    }

    var body: some View {
        let primary = (config.theme == .red) ? Color.red : Color.white
        return VStack(spacing: 16) {
            // Batterie-Status (Indikator, nicht klickbar)
            ZStack {
                Circle().stroke(primary, lineWidth: 2)
                Image(systemName: battery.symbolName)
                    .font(.title2)
                    .foregroundColor(primary)
                if battery.isPluggedIn {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(primary)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .allowsHitTesting(false)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
