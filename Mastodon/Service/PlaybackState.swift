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
