//
//  TimelineHeaderTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-6.
//

import UIKit

final class TimelineHeaderTableViewCell: UITableViewCell {
    
    let timelineHeaderView = TimelineHeaderView()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineHeaderTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        timelineHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelineHeaderView)
        NSLayoutConstraint.activate([
            timelineHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            timelineHeaderView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            timelineHeaderView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            timelineHeaderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])        
    }
    
}
