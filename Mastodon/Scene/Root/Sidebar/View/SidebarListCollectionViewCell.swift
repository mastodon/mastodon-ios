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
        
        var newBackgroundConfiguration = UIBackgroundConfiguration.listSidebarCell().updated(for: state)
        // Customize the background color to use the tint color when the cell is highlighted or selected.
        if state.isSelected || state.isHighlighted {
            newBackgroundConfiguration.backgroundColor = Asset.Colors.brandBlue.color
        }
        if state.isHighlighted {
            newBackgroundConfiguration.backgroundColorTransformer = .init { $0.withAlphaComponent(0.8) }
        }
        
        
        backgroundConfiguration = newBackgroundConfiguration
        
        let needsOutlineDisclosure = item?.needsOutlineDisclosure ?? false
        if !needsOutlineDisclosure {
            accessories = []
        } else {
            let tintColor: UIColor = state.isHighlighted || state.isSelected ? .white : Asset.Colors.brandBlue.color
            accessories = [
                UICellAccessory.outlineDisclosure(
                    displayed: .always,
                    options: UICellAccessory.OutlineDisclosureOptions(tintColor: tintColor),
                    actionHandler: nil
                )
            ]
        }
    }
}
