//
//  KeyboardResponderService.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-20.
//

import UIKit
import Combine

final public class KeyboardResponderService {
    
    var disposeBag = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = KeyboardResponderService()
    
    // output
    public let isShow = CurrentValueSubject<Bool, Never>(false)
    public let state = CurrentValueSubject<KeyboardState, Never>(.none)
    public let endFrame = CurrentValueSubject<CGRect, Never>(.zero)

    private init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { notification in
                self.isShow.value = true
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification, object: nil)
            .sink { notification in
                self.isShow.value = false
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            .sink { notification in
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            .sink { notification in
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
    }
    
}

extension KeyboardResponderService {
    
    private func updateInternalStatus(notification: Notification) {
        guard let isLocal = notification.userInfo?[UIWindow.keyboardIsLocalUserInfoKey] as? Bool,
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }
        
        self.endFrame.value = endFrame

        guard isLocal else {
            self.state.value = .notLocal
            return
        }
        
        // check if floating
        guard endFrame.width == UIScreen.main.bounds.width else {
            self.state.value = .floating
            return
        }
        
        // check if undock | split
        let dockMinY = UIScreen.main.bounds.height - endFrame.height
        if endFrame.minY < dockMinY {
            self.state.value = .notDock
        } else {
            self.state.value = .dock
        }
    }
    
}

extension KeyboardResponderService {
    public enum KeyboardState {
        case none
        case notLocal
        case notDock        // undock | split
        case floating       // iPhone size floating
        case dock
    }
}

extension KeyboardResponderService {
    public static func configure(
        scrollView: UIScrollView,
        layoutNeedsUpdate: AnyPublisher<Void, Never>,
        additionalSafeAreaInsets: AnyPublisher<UIEdgeInsets, Never> = CurrentValueSubject(.zero).eraseToAnyPublisher()
    ) -> AnyCancellable {
        let tuple = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )
        
        return Publishers.CombineLatest3(
            tuple,
            layoutNeedsUpdate,
            additionalSafeAreaInsets
        )
        .sink(receiveValue: { [weak scrollView] tuple, _, additionalSafeAreaInsets in
            guard let scrollView = scrollView else { return }
            guard let view = scrollView.superview else { return }
            
            let (isShow, state, endFrame) = tuple
            
            guard isShow, state == .dock else {
                scrollView.contentInset.bottom = additionalSafeAreaInsets.bottom
                scrollView.verticalScrollIndicatorInsets.bottom = additionalSafeAreaInsets.bottom
                return
            }
            
            // isShow AND dock state
            let contentFrame = view.convert(scrollView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                scrollView.contentInset.bottom = additionalSafeAreaInsets.bottom
                scrollView.verticalScrollIndicatorInsets.bottom = additionalSafeAreaInsets.bottom
                return
            }
            
            scrollView.contentInset.bottom = padding - scrollView.safeAreaInsets.bottom + additionalSafeAreaInsets.bottom
            scrollView.verticalScrollIndicatorInsets.bottom = padding - scrollView.safeAreaInsets.bottom + additionalSafeAreaInsets.bottom
        })
    }
}
