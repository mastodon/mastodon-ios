//
//  TableViewCellHeightCacheableContainer.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import UIKit

protocol TableViewCellHeightCacheableContainer: StatusProvider {
    var cellFrameCache: NSCache<NSNumber, NSValue> { get }
}

extension TableViewCellHeightCacheableContainer {
    
    func cacheTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = item(for: nil, indexPath: indexPath) else { return }
        
        let key = item.hashValue
        let frame = cell.frame
        cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
    }

    func handleTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = item(for: nil, indexPath: indexPath) else { return 200 }
        guard let frame = cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
            if case .bottomLoader = item {
                return TimelineLoaderTableViewCell.cellHeight
            } else {
                return 200
            }
        }
        
        return ceil(frame.height)
    }
}
