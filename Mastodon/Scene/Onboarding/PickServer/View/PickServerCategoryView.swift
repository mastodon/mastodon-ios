//
//  PickServerCategoryView.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonSDK

class PickServerCategoryView: UIView {
    
    var bgShadowView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 30
        return view
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
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
        addSubview(bgView)
        addSubview(titleLabel)

        bgView.backgroundColor = Asset.Theme.Mastodon.secondaryGroupedSystemBackground.color

        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bgView.topAnchor.constraint(equalTo: self.topAnchor),
            bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
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
