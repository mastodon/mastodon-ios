//
//  ContentWarningOverlayView.swift
//
//
//  Created by MainasuK on 2021-12-14.
//

import UIKit
import MastodonLocalization

public final class ContentWarningOverlayView: UIView {
        
    let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.text = L10n.Common.Controls.Status.tapToReveal
        label.textAlignment = .center
        label.textColor = .white.withAlphaComponent(0.7)
        label.layer.shadowOpacity = 0.3
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 2
        label.layer.shadowColor = UIColor.black.cgColor
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ContentWarningOverlayView {
    private func _init() {
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: hintLabel.trailingAnchor, constant: 8),
            centerYAnchor.constraint(equalTo: hintLabel.centerYAnchor, constant: 10),
        ])
    }
}
