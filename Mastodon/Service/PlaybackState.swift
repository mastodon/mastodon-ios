//
//  PlaybackState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/9.
//

import Foundation

public enum PlaybackState : Int {

    case unknown = 0
    
    case buffering = 1

    case readyToPlay = 2

    case playing = 3
    
    case paused = 4
    
    case stopped = 5

    case failed = 6
}

// MARK: - CustomStringConvertible
extension PlaybackState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .buffering: return "buffering"
        case .readyToPlay: return "readyToPlay"
        case .playing: return "playing"
        case .paused: return "paused"
        case .stopped: return "stopped"
        case .failed: return "failed"
        }
    }
}
