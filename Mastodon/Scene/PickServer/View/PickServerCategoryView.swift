//
//  PickServerCategoryView.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonSDK

class PickServerCategoryView: UIView {
    var category: PickServerViewModel.Category? {
        didSet {
            updateCategory()
        }
    }
    var selected: Bool = false {
        didSet {
            updateSelectStatus()
        }
    }
    
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
        
        bgView.backgroundColor = Asset.Colors.lightWhite.color
        
        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bgView.topAnchor.constraint(equalTo: self.topAnchor),
            bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
    
    private func updateCategory() {
        guard let category = category else { return }
        titleLabel.text = category.title
        switch category {
        case .All:
            titleLabel.font = UIFont.systemFont(ofSize: 17)
        case .Some:
            titleLabel.font = UIFont.systemFont(ofSize: 28)
        }
    }
    
    private func updateSelectStatus() {
        if selected {
            bgView.backgroundColor = Asset.Colors.lightBrandBlue.color
            bgView.applyShadow(color: Asset.Colors.lightBrandBlue.color, alpha: 1, x: 0, y: 0, blur: 4.0)
            if case .All = category {
                titleLabel.textColor = Asset.Colors.lightWhite.color
            }
        } else {
            bgView.backgroundColor = Asset.Colors.lightWhite.color
            bgView.applyShadow(color: Asset.Colors.lightBrandBlue.color, alpha: 0, x: 0, y: 0, blur: 0.0)
            if case .All = category {
                titleLabel.textColor = Asset.Colors.lightBrandBlue.color
            }
        }
    }
}
