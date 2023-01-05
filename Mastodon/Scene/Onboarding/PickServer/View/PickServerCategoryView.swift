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
    
    let highlightedIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Label.primary.color
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension PickServerCategoryView {
    
    private func configure() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2
        container.distribution = .fillProportionally
        
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        container.pinToParent()
        
        container.addArrangedSubview(titleLabel)
        highlightedIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(highlightedIndicatorView)
        NSLayoutConstraint.activate([
            highlightedIndicatorView.heightAnchor.constraint(equalToConstant: 3)//.priority(.required - 1),
        ])
        titleLabel.setContentHuggingPriority(.required - 1, for: .vertical)
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
