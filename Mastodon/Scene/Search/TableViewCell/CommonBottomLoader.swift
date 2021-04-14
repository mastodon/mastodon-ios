//
//  CommonBottomLoader.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import UIKit

final class CommonBottomLoader: UITableViewCell {
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = Asset.Colors.Label.primary.color
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }
    
    func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        contentView.addSubview(activityIndicatorView)
        activityIndicatorView.constrainToCenter()
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
