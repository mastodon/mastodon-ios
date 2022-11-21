//
//  DocumentStore.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import UIKit
import Combine
import MastodonSDK

public class DocumentStore: ObservableObject {
    public let appStartUpTimestamp = Date()
    public var defaultRevealStatusDict: [Mastodon.Entity.Status.ID: Bool] = [:]
}
