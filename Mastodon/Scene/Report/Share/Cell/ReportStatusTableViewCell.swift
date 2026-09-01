//
//  ReportStatusTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import MastodonUI
import MastodonAsset
import SwiftUI

final class ReportStatusTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    func configure(postViewModel: MastodonPostViewModel, layoutWidth: CGFloat, canChangeSelection: Bool, isSelected: Binding<Bool>) {
        configurationUpdateHandler = { cell, state in
            cell.contentConfiguration = UIHostingConfiguration {
                ReportablePostRowView(layoutWidth: layoutWidth - doublePadding, canChangeSelection: canChangeSelection, isSelected: isSelected)
                    .padding(standardPadding)
                    .environment(postViewModel)
                    .environment(TimestampUpdater.timestamper(withInterval: 60))
            }
            .margins(.all, 0)
        }
        setNeedsUpdateConfiguration()
    }
}
