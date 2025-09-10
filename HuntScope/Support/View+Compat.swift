//
//  View+Compat.swift
//  HuntScope
//
//  Compatibility helpers for newer SwiftUI modifiers on older iOS versions.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func scrollDismissesKeyboardCompat() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}

