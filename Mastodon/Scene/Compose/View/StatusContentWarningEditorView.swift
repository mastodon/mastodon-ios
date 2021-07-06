//
//  StatusContentWarningEditorView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-25.
//

import UIKit

final class StatusContentWarningEditorView: UIView {

    // due to section following readable inset. We overlap the bleeding to make background fill
    // default hidden
    let containerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
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

        containerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerBackgroundView)
        NSLayoutConstraint.activate([
            containerBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            containerBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -1024),
            containerBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 1024),
            containerBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: StatusView.avatarImageSize.width).priority(.defaultHigh),    // center alignment to avatar
        ])
        iconImageView.setContentHuggingPriority(.required - 2, for: .horizontal)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6).priority(.required - 1),
            textView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: StatusView.avatarToLabelSpacing - 4),    // align to name label. minus magic 4pt to remove addition inset
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: textView.bottomAnchor, constant: 6).priority(.required - 1),
            //textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])

        textView.setContentHuggingPriority(.required - 1, for: .vertical)
        textView.setContentCompressionResistancePriority(.required - 1, for: .vertical)
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

