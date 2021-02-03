//
//  UIAlertController.swift
//  Mastodon
//

import UIKit

// Reference:
// https://nshipster.com/swift-foundation-error-protocols/
extension UIAlertController {
    convenience init(
        _ error: Error,
        preferredStyle: UIAlertController.Style
    ) {
        let title: String
        let message: String?
        if let error = error as? LocalizedError {
            title = error.errorDescription ?? "Unknown Error"
            message = [
                error.failureReason,
                error.recoverySuggestion
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        } else {
            title = "Internal Error"
            message = error.localizedDescription
        }
        
        self.init(
            title: title,
            message: message,
            preferredStyle: preferredStyle
        )
    }
}

