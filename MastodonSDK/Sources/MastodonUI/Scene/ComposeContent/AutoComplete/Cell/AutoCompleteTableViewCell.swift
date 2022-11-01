//
//  AutoCompleteTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import UIKit
import FLAnimatedImage
import MetaTextKit
import MastodonAsset
import MastodonLocalization

public final class AutoCompleteTableViewCell: UITableViewCell {
    
    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4
    static let avatarToLabelSpacing: CGFloat = 12

    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()
    
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    let avatarImageView = AvatarImageView()
    
    let titleLabel: MetaLabel = {
        let label = MetaLabel(style: .autoCompletion)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "subtitle"
        return label
    }()
    
    let separatorLine = UIView.separatorLine
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        // workaround for hitTest trigger highlighted issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isHighlighted {
                self.setHighlighted(false, animated: true)
            }
        }
    }
    
}

extension AutoCompleteTableViewCell {
    
    private func _init() {
        let topPaddingView = UIView()
        let bottomPaddingView = UIView()
        
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topPaddingView.heightAnchor.constraint(equalToConstant: 12).priority(.defaultHigh),
        ])
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(equalToConstant: AutoCompleteTableViewCell.avatarImageSize.height).priority(.required - 1),
            avatarImageView.widthAnchor.constraint(equalToConstant: AutoCompleteTableViewCell.avatarImageSize.width).priority(.required - 1),
        ])
        containerStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
        
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.topAnchor.constraint(equalTo: contentStackView.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 1.0),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.defaultHigh),
        ])
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AutoCompleteTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview() {
                let cell = AutoCompleteTableViewCell()
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 66))
            UIViewPreview() {
                let cell = AutoCompleteTableViewCell()
                return cell
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 66))
        }
    }
    
}

#endif
