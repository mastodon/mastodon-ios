//
//  DragIndicatorView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-14.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class DragIndicatorView: UIView {

    static let height: CGFloat = 38

    let barView = UIView()
    let separatorLine = UIView.separatorLine
    let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)
        _init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

extension DragIndicatorView {

    private func _init() {
        barView.backgroundColor = Asset.Colors.Label.secondary.color
        barView.layer.masksToBounds = true
        barView.layer.cornerRadius = 2.5

        barView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barView)
        NSLayoutConstraint.activate([
            barView.centerXAnchor.constraint(equalTo: centerXAnchor),
            barView.centerYAnchor.constraint(equalTo: centerYAnchor),
            barView.heightAnchor.constraint(equalToConstant: 5).priority(.required - 1),
            barView.widthAnchor.constraint(equalToConstant: 36).priority(.required - 1),
        ])

        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = L10n.Scene.AccountList.dismissAccountSwitcher
    }

    override func accessibilityActivate() -> Bool {
        self.onDismiss()
        return true
    }
}
