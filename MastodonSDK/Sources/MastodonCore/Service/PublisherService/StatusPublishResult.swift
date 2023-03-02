//
//  StatusPublishResult.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import MastodonSDK

public enum StatusPublishResult {
    case post(Mastodon.Response.Content<Mastodon.Entity.Status>)
    case edit(Mastodon.Response.Content<Mastodon.Entity.Status>)
}
