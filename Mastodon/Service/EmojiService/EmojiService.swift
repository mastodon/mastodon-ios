//
//  EmojiService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import os.log
import Foundation
import Combine
import MastodonSDK

final class EmojiService {
    
    let workingQueue = DispatchQueue(label: "com.twidere.twiderex.video-playback-service.working-queue")
    
    weak var apiService: APIService?
    
    // ouput
    
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
}

