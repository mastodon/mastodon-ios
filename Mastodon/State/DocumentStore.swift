//
//  DocumentStore.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import UIKit
import Combine
import MastodonSDK

class DocumentStore: ObservableObject {
    let appStartUpTimestamp = Date()
    var defaultRevealStatusDict: [Mastodon.Entity.Status.ID: Bool] = [:]
}
