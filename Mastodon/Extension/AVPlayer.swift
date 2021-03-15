//
//  AVPlayer.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import AVKit

// MARK: - CustomDebugStringConvertible
extension AVPlayer.TimeControlStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .paused:                           return "paused"
        case .waitingToPlayAtSpecifiedRate:     return "waitingToPlayAtSpecifiedRate"
        case .playing:                          return "playing"
        @unknown default:
            assertionFailure()
            return ""
        }
    }
}
