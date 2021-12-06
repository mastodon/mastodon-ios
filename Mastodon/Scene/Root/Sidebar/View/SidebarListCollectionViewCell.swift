//
//  SidebarListTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-24.
//

import UIKit
import Combine

final class SidebarListCollectionViewCell: UICollectionViewListCell {
    
    var disposeBag = Set<AnyCancellable>()

    var item: SidebarListContentView.Item?
    
    var _contentView: SidebarListContentView? {
        guard let view = contentView as? SidebarListContentView else {
            assertionFailure()
            return nil
        }
        
        return view
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension SidebarListCollectionViewCell {
    private func _init() {
        
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = SidebarListContentView.ContentConfiguration().updated(for: state)
        newConfiguration.item = item
        contentConfiguration = newConfiguration
        
        // remove background
        var newBackgroundConfiguration = UIBackgroundConfiguration.listSidebarCell().updated(for: state)
        newBackgroundConfiguration.backgroundColor = .clear        
        backgroundConfiguration = newBackgroundConfiguration
    }
}
