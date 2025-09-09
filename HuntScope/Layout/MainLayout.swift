//
//  MainLayout.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
import SwiftUI


// Hauptlayout: Linke + Mitte + Rechte Spalte, mit Safe-Area-Breite
struct MainLayout<DialogButtons: View, DialogContent: View>: View {
    @EnvironmentObject private var ui: UIStateModel
    @StateObject private var player = PlayerController()


    // Dialog-spezifische Inhalte
    let dialogButtons: () -> DialogButtons
    let dialogContent: () -> DialogContent

    init(@ViewBuilder dialogButtons: @escaping () -> DialogButtons,
         @ViewBuilder dialogContent: @escaping () -> DialogContent) {
        self.dialogButtons = dialogButtons
        self.dialogContent = dialogContent
    }

    private let sideBaseWidth: CGFloat = 56.0

    var body: some View {
        GeometryReader { geo in
            // Safe-Area ermitteln (links/rechts in Landscape wichtig)
            let safeLeft  = geo.safeAreaInsets.leading
            let safeRight = geo.safeAreaInsets.trailing+5
            let safeTop    = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            
            ZStack {
                // 1) Stream in der Mitte (hinter allem)
                StreamView()

                // 2) Drei-Spalten-Layout
                HStack(spacing: 0) {

                    // Linke Spalte
                    LeftButtonArea(
                        showDialogButtons: ui.isDialogActive,
                        dialogButtons: dialogButtons
                    )
                    .frame(width: sideBaseWidth + safeLeft)
                    .frame(maxHeight: .infinity)
                    .background(Color.black.opacity(0.001))

                    // Mitte: fuellt alles zwischen den Seiten
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Rechte Spalte
                    ZStack {
                        Color.clear
                        RightButtonArea()
                            /*.frame(width: sideBaseWidth)          // 56 pt fix
                            .padding(.trailing, safeRight)        // Safe-Area INNEN, nicht Breite addieren
                            .padding(.top, safeTop)               // optional: falls oben/unten SafeInsets im Landscape
                            .padding(.bottom, safeBottom)         // optional
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())            // volle Spaltenfläche tappbar*/
                        
                    }
                    .frame(width: sideBaseWidth)   // fix 56
                    .padding(.trailing, safeRight) // SafeArea nach innen schieben
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 3) Dialog-Layer (liegt ueber allem)
                DialogOverlay(isVisible: ui.isDialogActive) {
                    dialogContent()
                        .frame(maxWidth: 520)
                        .padding(24)
                        .background(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.red.opacity(0.8), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(radius: 8)
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
}
