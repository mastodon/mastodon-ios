//
//  SettingsSectionHeader.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit
import MastodonAsset
import MastodonLocalization

struct GroupedTableViewConstraints {
    static let topMargin: CGFloat = 40
    static let bottomMargin: CGFloat = 10
}

/// section header which supports add a custom view blelow the title
class SettingsSectionHeader: UIView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(
            top: GroupedTableViewConstraints.topMargin,
            left: 0,
            bottom: GroupedTableViewConstraints.bottomMargin,
            right: 0
        )
        view.axis = .vertical
        return view
    }()
    
    init(frame: CGRect, customView: UIView? = nil) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        stackView.addArrangedSubview(titleLabel)
        if let view = customView {
            stackView.addArrangedSubview(view)
        }
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String?) {
        titleLabel.text = title?.uppercased()
    }
}
