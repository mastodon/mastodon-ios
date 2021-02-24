//
//  TimelineLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import Combine

class TimelineLoaderTableViewCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 44 + TimelineLoaderTableViewCell.extraTopPadding + TimelineLoaderTableViewCell.bottomPadding
    static let extraTopPadding: CGFloat = 3     // the status cell already has 10pt bottom padding
    static let bottomPadding: CGFloat = StatusTableViewCell.bottomPaddingHeight + TimelineLoaderTableViewCell.extraTopPadding   // make balance
    
    var disposeBag = Set<AnyCancellable>()
    
    let loadMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setTitle(L10n.Common.Controls.Timeline.loadMore, for: .normal)
        return button
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = .white
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelineLoaderTableViewCell.extraTopPadding),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor, constant: TimelineLoaderTableViewCell.bottomPadding),
            loadMoreButton.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: loadMoreButton.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: loadMoreButton.centerYAnchor),
        ])
        
        loadMoreButton.isHidden = true
        activityIndicatorView.isHidden = true
    }
    
}
