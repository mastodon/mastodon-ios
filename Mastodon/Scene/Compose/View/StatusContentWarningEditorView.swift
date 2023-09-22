//
//  StatusContentWarningEditorView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-25.
//

import UIKit
import MastodonUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class StatusContentWarningEditorView: UIView {

    // due to section following readable inset. We overlap the bleeding to make background fill
    // default hidden
    let containerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
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

        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 6),
        ])

        containerStackView.addArrangedSubview(iconImageView)
        iconImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        containerStackView.addArrangedSubview(textView)
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

