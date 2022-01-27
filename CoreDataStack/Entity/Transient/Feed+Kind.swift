//
//  Feed+Kind.swift
//  CoreDataStack
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation

extension Feed {
    public enum Kind: String, CaseIterable, Hashable {
        case none
        case home
        case notificationAll
        case notificationMentions
    }
}
