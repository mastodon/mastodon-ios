//
//  CellFrameCacheContainer.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

protocol CellFrameCacheContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> { get }
    
    func keyForCache(tableView: UITableView, indexPath: IndexPath) -> NSNumber?
}

extension CellFrameCacheContainer {
    func cacheCellFrame(tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let key = keyForCache(tableView: tableView, indexPath: indexPath) else { return }
        let value = NSValue(cgRect: cell.frame)
        cellFrameCache.setObject(value, forKey: key)
    }
    
    func retrieveCellFrame(tableView: UITableView, indexPath: IndexPath) -> CGRect? {
        guard let key = keyForCache(tableView: tableView, indexPath: indexPath) else { return nil }
        guard let frame = cellFrameCache.object(forKey: key)?.cgRectValue else { return nil }
        return frame
    }
}
