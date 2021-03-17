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
    static let labelFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .medium))
    
    var disposeBag = Set<AnyCancellable>()
    
    var stateBindDispose: AnyCancellable?
    
    let loadMoreButton: UIButton = {
        let button = HighlightDimmableButton()
        button.titleLabel?.font = TimelineLoaderTableViewCell.labelFont
        button.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        button.setTitleColor(Asset.Colors.Button.normal.color, for: .normal)
        button.setTitle(L10n.Common.Controls.Timeline.Loader.loadMissingPosts, for: .normal)
        button.setTitle("", for: .disabled)
        return button
    }()
    
    let loadMoreLabel: UILabel = {
        let label = UILabel()
        label.font = TimelineLoaderTableViewCell.labelFont
        return label
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = Asset.Colors.Label.secondary.color
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
        self.loadMoreButton.isEnabled = false
        self.loadMoreLabel.textColor = Asset.Colors.Label.secondary.color
        self.loadMoreLabel.text = L10n.Common.Controls.Timeline.Loader.loadingMissingPosts
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        self.loadMoreButton.isEnabled = true
        self.loadMoreLabel.textColor = Asset.Colors.buttonDefault.color
        self.loadMoreLabel.text = ""
    }
    
    func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor, constant: 14),
            loadMoreButton.heightAnchor.constraint(equalToConstant: TimelineLoaderTableViewCell.buttonHeight).priority(.required - 1),
        ])
        
        // use stack view to alignlment content center
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: loadMoreButton.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: loadMoreButton.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor),
        ])
        let leftPaddingView = UIView()
        leftPaddingView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(leftPaddingView)
        stackView.addArrangedSubview(activityIndicatorView)
        stackView.addArrangedSubview(loadMoreLabel)
        let rightPaddingView = UIView()
        rightPaddingView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(rightPaddingView)
        NSLayoutConstraint.activate([
            leftPaddingView.widthAnchor.constraint(equalTo: rightPaddingView.widthAnchor, multiplier: 1.0),
        ])
        
        // default set hidden and let subclass override it
        loadMoreButton.isHidden = true
        loadMoreLabel.isHidden = true
        activityIndicatorView.isHidden = true
    }
    
}
