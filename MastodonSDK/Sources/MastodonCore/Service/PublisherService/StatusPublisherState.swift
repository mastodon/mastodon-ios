//
//  StatusPublisherState.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation

public enum StatusPublisherState {
    case pending
    case failure(Error)
    case success
}
