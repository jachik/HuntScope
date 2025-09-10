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
        @EnvironmentObject private var config: ConfigStore
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
            let safeLeft  = geo.safeAreaInsets.leading + 10
            let safeRight = geo.safeAreaInsets.trailing + 10
            let safeTop    = geo.safeAreaInsets.top + 10
            let safeBottom = geo.safeAreaInsets.bottom + 10
            
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
                    // Safe-Bereich oben/unten + 5pt
                    .padding(.top, safeTop + 5)
                    .padding(.bottom, safeBottom + 5)
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
                    }
                    .frame(width: sideBaseWidth + safeRight)   // fix inkl. SafeArea rechts
                    // Safe-Bereich oben/unten + 5pt
                    .padding(.top, safeTop + 5)
                    .padding(.bottom, safeBottom + 5)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 3) Dialog-Layer (liegt ueber allem)
                let horizontalMargin: CGFloat = 20
                let reservedLeft  = sideBaseWidth + safeLeft  + horizontalMargin
                let reservedRight = sideBaseWidth + safeRight + horizontalMargin
                let centerWidth = max(0, geo.size.width - reservedLeft - reservedRight)
                let centerHeight = max(0, geo.size.height - (safeTop + safeBottom + 20)) // 10pt oben/unten zusätzlich
                DialogOverlay(isVisible: ui.isDialogActive) {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: reservedLeft)
                            .allowsHitTesting(false)

                        // Center-Bereich: eigener Layer mit Abdunkelung + Dialogbox
                        ZStack {
                            // Dim nur über der Mitte, Buttons bleiben klar
                            Color.black.opacity(0.5)
                                .allowsHitTesting(false)

                            // Dialogbox und Close-Button in gemeinsamem Container (TopTrailing),
                            // damit der Innenabstand zuverlässig greift
                            ZStack(alignment: .topTrailing) {
                                // Dialogbox exakt in der Mitte, begrenzt auf Stream-Fläche
                                dialogContent()
                                    .padding(24)
                                    .background(Color.black.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(((config.theme == .red) ? Color.red : Color.white).opacity(0.8), lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                    .shadow(radius: 8)

                                // Close-Button oben rechts mit 5pt Innenabstand
                                let primary = (config.theme == .red) ? Color.red : Color.white
                                Button {
                                    ui.isDialogActive = false
                                } label: {
                                    ZStack {
                                        Circle().stroke(primary, lineWidth: 2)
                                        Image(systemName: "xmark")
                                            .font(.title2)
                                            .foregroundStyle(primary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .padding(.top, 5)
                                .padding(.trailing, 5)
                            }
                            .frame(maxWidth: centerWidth, maxHeight: centerHeight)
                        }
                        .frame(width: centerWidth, height: centerHeight)

                        Color.clear
                            .frame(width: reservedRight)
                            .allowsHitTesting(false)
                    }
                }

                // (Ringer-Indikator in LeftButtonArea verschoben)
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
}
