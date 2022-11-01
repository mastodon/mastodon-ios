//
//  MastodonStatus.swift
//  
//
//  Created by MainasuK on 2022-4-18.
//

import Foundation
import CoreDataStack

extension Status {
    
    // mark content sensitive when status contains spoilerText
    public var isContentSensitive: Bool {
        if let spoilerText = spoilerText, !spoilerText.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    // mark media sensitive when `isContentSensitive` or media marked sensitive
    public var isMediaSensitive: Bool {
        // some servers set media sensitive even empty attachments
        return isContentSensitive || (sensitive && !attachments.isEmpty)
    }
    
}
