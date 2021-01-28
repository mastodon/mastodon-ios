//
//  TimelinePostTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import AVKit
import Combine


protocol TimelinePostTableViewCellDelegate: class {
    
}

final class TimelinePostTableViewCell: UITableViewCell {
    
    static let verticalMargin: CGFloat = 16         // without retweet indicator
    static let verticalMarginAlt: CGFloat = 8       // with retweet indicator
    
    weak var delegate: TimelinePostTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    let timelinePostView = TimelinePostView()
    
    var timelinePostViewTopLayoutConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag.removeAll()
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelinePostTableViewCell {
    
    private func _init() {
        timelinePostView.translatesAutoresizingMaskIntoConstraints = false
        timelinePostViewTopLayoutConstraint = timelinePostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelinePostTableViewCell.verticalMargin)
        contentView.addSubview(timelinePostView)
        NSLayoutConstraint.activate([
            timelinePostViewTopLayoutConstraint,
            timelinePostView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: timelinePostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: timelinePostView.bottomAnchor),    // use action toolbar margin
        ])
    }
    
}
