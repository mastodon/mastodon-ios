//
//  ProfileFieldCollectionViewHeaderFooterView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-26.
//

import UIKit

final class ProfileFieldCollectionViewHeaderFooterView: UICollectionReusableView {
    
    static let headerReuseIdentifer = "ProfileFieldCollectionViewHeaderFooterView.Header"
    static let footerReuseIdentifer = "ProfileFieldCollectionViewHeaderFooterView.Footer"
    
    let separatorLine = UIView.separatorLine

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldCollectionViewHeaderFooterView {
    private func _init() {
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)).priority(.defaultHigh),
        ])
    }
}
