//
//  String.swift
//  NotificationService
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation

extension String {
    static func normalize(base64String: String) -> String {
        let base64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding()
        return base64
    }
    
    private func padding() -> String {
        let remainder = self.count % 4
        if remainder > 0 {
            return self.padding(
                toLength: self.count + 4 - remainder,
                withPad: "=",
                startingAt: 0
            )
        }
        return self
    }
}

