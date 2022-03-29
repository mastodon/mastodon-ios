//
//  ShareActivityProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-25.
//

import UIKit

protocol ShareActivityProvider {
    var activities: [Any] { get }
    var applicationActivities: [UIActivity] { get }
}
