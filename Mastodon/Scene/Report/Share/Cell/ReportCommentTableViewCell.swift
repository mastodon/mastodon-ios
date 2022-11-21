//
//  ReportCommentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import Combine
import MastodonUI
import MastodonAsset
import MastodonLocalization
import UITextView_Placeholder

final class ReportCommentTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let commentTextViewShadowBackgroundContainer: ShadowBackgroundContainer = {
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        return shadowBackgroundContainer
    }()
    
    let commentTextView: UITextView = {
        let textView = UITextView()
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        textView.font = font
        textView.attributedPlaceholder = NSAttributedString(
            string: L10n.Scene.Report.textPlaceholder,
            attributes: [
                .font: font,
                .foregroundColor: Asset.Colors.Label.secondary.color
            ]
        )
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.isScrollEnabled = false
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 10
        return textView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ReportCommentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        commentTextViewShadowBackgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(commentTextViewShadowBackgroundContainer)
        NSLayoutConstraint.activate([
            commentTextViewShadowBackgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            commentTextViewShadowBackgroundContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            commentTextViewShadowBackgroundContainer.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: commentTextViewShadowBackgroundContainer.bottomAnchor, constant: 24),
        ])
        
        commentTextView.translatesAutoresizingMaskIntoConstraints = false
        commentTextViewShadowBackgroundContainer.addSubview(commentTextView)
        commentTextView.pinToParent()
        NSLayoutConstraint.activate([
            commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).priority(.defaultHigh),
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        commentTextView.attributedPlaceholder = NSAttributedString(
            string: L10n.Scene.Report.textPlaceholder,
            attributes: [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
                .foregroundColor: Asset.Colors.Label.secondary.color
            ]
        )
    }
    
}
