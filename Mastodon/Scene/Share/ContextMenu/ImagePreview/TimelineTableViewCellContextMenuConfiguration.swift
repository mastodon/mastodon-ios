//
//  TimelineTableViewCellContextMenuConfiguration.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-30.
//

import UIKit

// note: use subclass configuration not custom NSCopying identifier due to identifier cause crash issue
final class TimelineTableViewCellContextMenuConfiguration: UIContextMenuConfiguration {
    
    var indexPath: IndexPath?
    var index: Int?
    
}
