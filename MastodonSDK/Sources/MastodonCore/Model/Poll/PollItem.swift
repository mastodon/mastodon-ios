//
//  PollItem.swift
//  
//
//  Created by MainasuK on 2022-1-12.
//

import Foundation
import CoreData
import MastodonSDK

public enum PollItem: Hashable {
    @available(*, deprecated, message: "migrate to pollOption wrapping a Mastodon.Entity.Poll.Option")
    case option(record: MastodonPollOption)
    case pollOption(Mastodon.Entity.Poll.Option)
    case history(option: Mastodon.Entity.StatusEdit.Poll.Option)
}
