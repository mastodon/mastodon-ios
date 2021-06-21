//
//  HomeTimelinePreference.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-21.
//

import UIKit

extension UserDefaults {

    @objc dynamic var preferAsyncHomeTimeline: Bool {
        get {
            register(defaults: [#function: false])
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }

}
