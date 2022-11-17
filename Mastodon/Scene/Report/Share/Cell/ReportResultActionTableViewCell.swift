//
//  ReportResultActionTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import UIKit
import Combine
import MastodonAsset
import MastodonUI
import MastodonLocalization

final class ReportResultActionTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let containerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let avatarImageView: AvatarImageView = {
        let imageView = AvatarImageView()
        imageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 27)))
        return imageView
    }()
    
    let reportBannerShadowContainer = ShadowBackgroundContainer()
    let reportBannerLabel: UILabel = {
        let label = UILabel()
        let padding = Array(repeating: " ", count: 2).joined()
        label.text = padding + L10n.Scene.Report.reported + padding
        label.textColor = Asset.Scene.Report.reportBanner.color
        label.font = FontFamily.Staatliches.regular.font(size: 49)
        label.backgroundColor = Asset.Scene.Report.background.color
        label.layer.borderColor = Asset.Scene.Report.reportBanner.color.cgColor
        label.layer.borderWidth = 6
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 12
        return label
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

extension ReportResultActionTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        let avatarContainer = UIStackView()
        avatarContainer.axis = .horizontal
        containerView.addArrangedSubview(avatarContainer)
        
        let avatarLeadingPaddingView = UIView()
        let avatarTrailingPaddingView = UIView()
        avatarLeadingPaddingView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addArrangedSubview(avatarLeadingPaddingView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addArrangedSubview(avatarImageView)
        avatarTrailingPaddingView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addArrangedSubview(avatarTrailingPaddingView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 106).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: 106).priority(.required - 1),
            avatarLeadingPaddingView.widthAnchor.constraint(equalTo: avatarTrailingPaddingView.widthAnchor).priority(.defaultHigh),
        ])

        reportBannerShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(reportBannerShadowContainer)
        NSLayoutConstraint.activate([
            reportBannerShadowContainer.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            reportBannerShadowContainer.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
        ])
        reportBannerShadowContainer.transform = CGAffineTransform(rotationAngle: -(.pi / 180 * 5))
        
        reportBannerLabel.translatesAutoresizingMaskIntoConstraints = false
        reportBannerShadowContainer.addSubview(reportBannerLabel)
        reportBannerLabel.pinToParent()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        reportBannerShadowContainer.layer.setupShadow(
            color: .black,
            alpha: 0.25,
            x: 1,
            y: 0.64,
            blur: 0.64,
            spread: 0,
            roundedRect: reportBannerShadowContainer.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 12, height: 12)
        )
    }
    
}

#if DEBUG
import SwiftUI
struct ReportResultActionTableViewCell_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            let cell = ReportResultActionTableViewCell()
            cell.avatarImageView.configure(configuration: .init(image: .placeholder(color: .blue)))
            return cell
        }
        .previewLayout(.fixed(width: 375, height: 106))
    }
}
#endif
