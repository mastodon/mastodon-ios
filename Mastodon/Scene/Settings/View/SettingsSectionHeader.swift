//
//  SettingsSectionHeader.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit

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
        view.layoutMargins = UIEdgeInsets(top: 40, left: 12, bottom: 10, right: 12)
        view.axis = .vertical
        return view
    }()
    
    init(frame: CGRect, customView: UIView? = nil) {
        super.init(frame: frame)
        
        backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        stackView.addArrangedSubview(titleLabel)
        if let view = customView {
            stackView.addArrangedSubview(view)
        }
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
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
