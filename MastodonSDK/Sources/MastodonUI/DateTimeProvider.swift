//
//  DateTimeProvider.swift
//  
//
//  Created by MainasuK on 2022-1-29.
//

import Foundation

public protocol DateTimeProvider {
    func shortTimeAgoSinceNow(to date: Date?) -> String?
}
