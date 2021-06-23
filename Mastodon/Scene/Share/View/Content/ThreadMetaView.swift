//
//  ThreadMetaView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import UIKit

final class ThreadMetaView: UIView {
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.text = "Date"
        return label
    }()
    
    let reblogButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 reblog", for: .normal)
        button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
        button.setTitleColor(Asset.Colors.brandBlue.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 favorite", for: .normal)
        button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
        button.setTitleColor(Asset.Colors.brandBlue.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    let actionButtonStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ThreadMetaView {
    private func _init() {
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 12),
        ])
        
        containerStackView.addArrangedSubview(dateLabel)
        containerStackView.addArrangedSubview(actionButtonStackView)
        
        actionButtonStackView.axis = .horizontal
        actionButtonStackView.spacing = 20
        actionButtonStackView.addArrangedSubview(reblogButton)
        actionButtonStackView.addArrangedSubview(favoriteButton)
        
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        reblogButton.setContentHuggingPriority(.required - 2, for: .horizontal)
        favoriteButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        
        updateContainerLayout()
        
        // TODO: 
        reblogButton.isAccessibilityElement = false
        favoriteButton.isAccessibilityElement = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateContainerLayout()
    }
    
    private func updateContainerLayout() {
        if traitCollection.preferredContentSizeCategory < .accessibilityMedium {
            containerStackView.axis = .horizontal
            containerStackView.spacing = 20
            dateLabel.numberOfLines = 1
        } else {
            containerStackView.axis = .vertical
            containerStackView.spacing = 4
            dateLabel.numberOfLines = 0
        }
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ThreadMetaView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            ThreadMetaView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

