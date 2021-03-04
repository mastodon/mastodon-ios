//
//  UIAlertController.swift
//  Mastodon
//

import UIKit
import MastodonSDK
// Reference:
// https://nshipster.com/swift-foundation-error-protocols/
extension UIAlertController {
    convenience init(
        for error: Error,
        title: String?,
        preferredStyle: UIAlertController.Style
    ) {
        let _title: String
        let message: String?
        if let error = error as? LocalizedError {
            var messages: [String?] = []
            if let title = title {
                _title = title
                messages.append(error.errorDescription)
            } else {
                _title = error.errorDescription ?? "Error"
            }
            messages.append(contentsOf: [
                error.failureReason,
                error.recoverySuggestion
            ])
            message = messages
                .compactMap { $0 }
                .joined(separator: " ")
        } else {
            _title = "Internal Error"
            message = error.localizedDescription
        }
        
        self.init(
            title: _title,
            message: message,
            preferredStyle: preferredStyle
        )
    }
}
