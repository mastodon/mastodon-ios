//
//  ProfileFieldView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import ActiveLabel

final class ProfileFieldView: UIView {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Title"
        return label
    }()
    
    let valueActiveLabel: ActiveLabel = {
        let label = ActiveLabel(style: .profileField)
        label.configure(content: "value", emojiDict: [:])
        return label
    }()
    
    let topSeparatorLine = UIView.separatorLine
    let bottomSeparatorLine = UIView.separatorLine
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldView {
    private func _init() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        valueActiveLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueActiveLabel)
        NSLayoutConstraint.activate([
            valueActiveLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueActiveLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            valueActiveLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
        valueActiveLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        topSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparatorLine)
        NSLayoutConstraint.activate([
            topSeparatorLine.topAnchor.constraint(equalTo: topAnchor),
            topSeparatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)).priority(.defaultHigh),
        ])
        
        bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSeparatorLine)
        NSLayoutConstraint.activate([
            bottomSeparatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparatorLine.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            bottomSeparatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)).priority(.defaultHigh),
        ])
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ProfileFieldView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            let filedView = ProfileFieldView()
            filedView.valueActiveLabel.configure(field: "https://mastodon.online")
            return filedView
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

