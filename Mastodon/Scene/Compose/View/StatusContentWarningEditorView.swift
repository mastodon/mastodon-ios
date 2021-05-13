//
//  StatusContentWarningEditorView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-25.
//

import UIKit

final class StatusContentWarningEditorView: UIView {
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        return view
    }()
    
    // due to section following readable inset. We overlap the bleeding to make backgorund fill
    // default hidden
    let containerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        view.isHidden = true
        return view
    }()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.shield")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.primary.color
        imageView.contentMode = .center
        return imageView
    }()
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.placeholder = L10n.Scene.Compose.ContentWarning.placeholder
        textView.backgroundColor = .clear
        return textView
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

extension StatusContentWarningEditorView {
    private func _init() {
        let contentWarningStackView = UIStackView()
        contentWarningStackView.axis = .horizontal
        contentWarningStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentWarningStackView)
        NSLayoutConstraint.activate([
            contentWarningStackView.topAnchor.constraint(equalTo: topAnchor),
            contentWarningStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentWarningStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentWarningStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        contentWarningStackView.addArrangedSubview(containerView)
        
        containerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(containerBackgroundView)
        NSLayoutConstraint.activate([
            containerBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -1024),
            containerBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 1024),
            containerBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.readableContentGuide.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: StatusView.avatarImageSize.width).priority(.defaultHigh),    // center alignment to avatar
        ])
        iconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            textView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: StatusView.avatarToLabelSpacing - 4),    // align to name label. minus magic 4pt to remove addtion inset
            textView.trailingAnchor.constraint(equalTo: containerView.readableContentGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: 6),
        ])
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct StatusContentWarningEditorView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            StatusContentWarningEditorView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

