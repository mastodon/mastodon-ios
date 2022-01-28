//
//  MastodonEmoji.swift
//  MastodonEmoji
//
//  Created by Cirno MainasuK on 2021-9-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public final class MastodonEmoji: NSObject, Codable {
    public let code: String
    public let url: String
    public let staticURL: String
    public let visibleInPicker: Bool
    public let category: String?
    
    public init(code:
         String, url:
         String, staticURL:
         String, visibleInPicker:
         Bool, category: String?
    ) {
        self.code = code
        self.url = url
        self.staticURL = staticURL
        self.visibleInPicker = visibleInPicker
        self.category = category
    }
}
