//
//  DragIndicatorView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-14.
//

import UIKit

final class DragIndicatorView: UIView {

    static let height: CGFloat = 38

    let barView = UIView()
    let separatorLine = UIView.separatorLine

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
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
    }

}
