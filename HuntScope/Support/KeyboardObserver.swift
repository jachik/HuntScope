//
//  KeyboardObserver.swift
//  HuntScope
//
//  Publishes the current keyboard height to help adjust scrollable dialogs.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables: [AnyCancellable] = []

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { [weak self] note in
                guard let self = self else { return }
                if note.name == UIResponder.keyboardWillHideNotification {
                    self.height = 0
                    return
                }
                guard let info = note.userInfo,
                      let end = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let window = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first
                else { return }
                // Convert to our coordinate space
                let keyboardInView = window.convert(end, to: window)
                let overlap = max(0, window.bounds.maxY - keyboardInView.minY)
                self.height = overlap
            }
            .store(in: &cancellables)
    }
}

