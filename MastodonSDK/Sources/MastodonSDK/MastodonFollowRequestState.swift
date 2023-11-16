// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public final class MastodonFollowRequestState: NSObject, Codable {
    public let state: State

    public init(
        state: State
    ) {
        self.state = state
    }
}

extension MastodonFollowRequestState {
    public enum State: String, Codable {
        case none
        case isAccepting
        case isAccept
        case isRejecting
        case isReject
    }
}
