//
//  DoubleTitleLabelNavigationBarTitleView.swift
//  Mastodon
//
//  Created by BradGao on 2021/4/1.
//

import UIKit
import Meta
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class DoubleTitleLabelNavigationBarTitleView: UIView {
    
    let containerView = UIStackView()
    
    let titleLabel = MetaLabel(style: .titleView)
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.isHidden = true
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

extension DoubleTitleLabelNavigationBarTitleView {
    private func _init() {
        containerView.axis = .vertical
        containerView.alignment = .center
        containerView.distribution = .fill
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        containerView.pinToParent()
        
        containerView.addArrangedSubview(titleLabel)
        containerView.addArrangedSubview(subtitleLabel)

        isAccessibilityElement = true
    }

    func update(title: String, subtitle: String?) {
        titleLabel.configure(content: PlaintextMetaContent(string: title))
        update(subtitle: subtitle)
        accessibilityLabel = subtitle.map { "\(title), \($0)" } ?? title
    }
    
    func update(titleMetaContent: MetaContent, subtitle: String?) {
        titleLabel.configure(content: titleMetaContent)
        update(subtitle: subtitle)
        accessibilityLabel = subtitle.map { "\(titleMetaContent.string), \($0)" } ?? titleMetaContent.string
    }

    func update(subtitle: String?) {
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.text = nil
            subtitleLabel.isHidden = true
        }
    }
}

#if canImport(SwiftUI) && DEBUG

import SwiftUI

struct DoubleTitleLabelNavigationBarTitleView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            DoubleTitleLabelNavigationBarTitleView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

