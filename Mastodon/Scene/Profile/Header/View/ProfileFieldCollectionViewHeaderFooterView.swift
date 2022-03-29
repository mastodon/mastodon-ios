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

    }
}
