//
//  PickServerCategoryView.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonSDK
import MastodonAsset
import MastodonUI
import MastodonLocalization

class PickServerCategoryView: UIView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()

    //TODO: @zeitschlag add chevron
    
    init() {
        super.init(frame: .zero)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    private func _init() {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 4
        container.distribution = .fillProportionally
        
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        let constraints = [
            container.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 12),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 6),
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        container.addArrangedSubview(titleLabel)

        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1.0
        applyCornerRadius(radius: 15)
    }
    
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct PickServerCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            PickServerCategoryView()
        }
    }
}
#endif
