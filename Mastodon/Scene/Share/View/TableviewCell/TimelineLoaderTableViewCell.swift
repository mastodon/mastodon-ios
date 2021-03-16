//
//  TimelineLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import Combine

class TimelineLoaderTableViewCell: UITableViewCell {
    
    static let buttonHeight: CGFloat = 62
    static let cellHeight: CGFloat = TimelineLoaderTableViewCell.buttonHeight + 17
    static let extraTopPadding: CGFloat = 10

    
    var disposeBag = Set<AnyCancellable>()
    
    var stateBindDispose: AnyCancellable?
    
    let loadMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Asset.Colors.lightWhite.color
        return button
    }()
    
    private let loadMoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = Asset.Colors.lightSecondaryText.color
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
    func startAnimating() {
        activityIndicatorView.startAnimating()
        self.loadMoreLabel.textColor = Asset.Colors.lightSecondaryText.color
        self.loadMoreLabel.text = L10n.Common.Controls.Timeline.Loader.loadingMissingPosts
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        self.loadMoreLabel.textColor = Asset.Colors.buttonDefault.color
        self.loadMoreLabel.text = L10n.Common.Controls.Timeline.Loader.loadMissingPosts
    }
    
    func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor, constant: 14),
            loadMoreButton.heightAnchor.constraint(equalToConstant: TimelineLoaderTableViewCell.buttonHeight).priority(.defaultHigh),
        ])
        
        loadMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadMoreLabel)
        NSLayoutConstraint.activate([
            loadMoreLabel.centerXAnchor.constraint(equalTo: loadMoreButton.centerXAnchor),
            loadMoreLabel.centerYAnchor.constraint(equalTo: loadMoreButton.centerYAnchor),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerYAnchor.constraint(equalTo: loadMoreButton.centerYAnchor),
            activityIndicatorView.trailingAnchor.constraint(equalTo: loadMoreLabel.leadingAnchor),
        ])
        
        activityIndicatorView.isHidden = true
    }
    
}
