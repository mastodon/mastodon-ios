//
//  UIAlertController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-7-1.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    public static func standardAlert(of error: Error) -> UIAlertController {
        let title: String? = {
            if let error = error as? LocalizedError {
                return error.errorDescription
            } else {
                return "Error"
            }
        }()
        
        let message: String? = {
            if let error = error as? LocalizedError {
                return [error.failureReason, error.recoverySuggestion].compactMap { $0 }.joined(separator: "\n")
            } else {
                return error.localizedDescription
            }
        }()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
    
}
