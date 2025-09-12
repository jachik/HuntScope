// Datei: SidebarButton.swift
import SwiftUI
import UIKit

struct SidebarButton<Content: View>: View {
    // Zentrales Theme
    @EnvironmentObject var config: ConfigStore
    // Reagiert automatisch auf .disabled(...)
    @Environment(\.isEnabled) private var isEnabled

    // API – wie ein normaler Button, plus Extras
    enum HapticKind { case none, tap, selection }

    var pulsing: Bool = false
    var haptics: HapticKind = .tap
    let action: () -> Void
    let label: () -> Content

    // Fixwerte
    private let size: CGFloat = 44.0
    private let circleLineWidth: CGFloat = 2.0

    // Pulsanimation
    @State private var pulsePhase: Bool = false

    // Primärfarbe folgt Theme und Enabled-State
    private var primaryColor: Color {
        let base: Color = (config.theme == .red) ? .red : .white
        // Disabled: leicht abgedimmte Theme-Farbe statt Grau
        return isEnabled ? base : base.opacity(0.45)
    }

    // 1) Button-typischer Initializer (wie SwiftUI Button(action:label:))
    init(pulsing: Bool = false,
         haptics: HapticKind = .tap,
         action: @escaping () -> Void,
         @ViewBuilder label: @escaping () -> Content) {
        self.pulsing = pulsing
        self.haptics = haptics
        self.action = action
        self.label = label
    }

    // 2) Convenience-Init für SF Symbols (Content == Image)
    init(systemName: String,
         pulsing: Bool = false,
         haptics: HapticKind = .tap,
         action: @escaping () -> Void) where Content == Image {
        self.pulsing = pulsing
        self.haptics = haptics
        self.action = action
        self.label = { Image(systemName: systemName) }
    }

    var body: some View {
        Button(action: {
            playHaptic()
            action()
        }) {
            ZStack {
                // Optionaler Pulsring (nur, wenn enabled)
                if pulsing && isEnabled {
                    Circle()
                        .stroke(primaryColor.opacity(0.4), lineWidth: circleLineWidth)
                        .scaleEffect(pulsePhase ? 1.25 : 1.0)
                        .opacity(pulsePhase ? 0.0 : 0.8)
                        .animation(
                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: pulsePhase
                        )
                }

                // Fester Kreisrahmen
                Circle()
                    .stroke(primaryColor, lineWidth: circleLineWidth)

                // Dein Label (Image/Text/Custom)
                label()
                    .font(.title2)
                    .foregroundColor(primaryColor)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            if pulsing && isEnabled { pulsePhase = true }
        }
        // iOS 14–16 Syntax:
        .onChange(of: pulsing) { newValue in
            pulsePhase = newValue && isEnabled
        }
        .onChange(of: isEnabled) { enabled in
            pulsePhase = enabled ? pulsing : false
        }
    }

    private func playHaptic() {
        switch haptics {
        case .none:
            break
        case .tap:
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            g.impactOccurred()
        case .selection:
            let g = UISelectionFeedbackGenerator()
            g.prepare()
            g.selectionChanged()
        }
    }
}
