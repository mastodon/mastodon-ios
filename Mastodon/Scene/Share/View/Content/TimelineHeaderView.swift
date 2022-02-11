//
//  TimelineHeaderView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-6.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class TimelineHeaderView: UIView {
        
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "info"
        label.numberOfLines = 0
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

extension TimelineHeaderView {
    
    private func _init() {
        backgroundColor = .clear
        
        let topPaddingView = UIView()
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.topAnchor.constraint(equalTo: topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = 16
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(messageLabel)
        
        let bottomPaddingView = UIView()
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.topAnchor.constraint(equalTo: containerStackView.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            topPaddingView.heightAnchor.constraint(equalToConstant: 100).priority(.defaultHigh),
            bottomPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 1.0),
        ])
    }
    
}

//extension Item.EmptyStateHeaderAttribute.Reason {
//    var iconImage: UIImage? {
//        switch self {
//        case .noStatusFound, .blocking, .blocked:
//            return UIImage(systemName: "nosign", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .bold))!
//        case .suspended:
//            return UIImage(systemName: "person.crop.circle.badge.xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .bold))!
//        }
//    }
//    
//    var message: String {
//        switch self {
//        case .noStatusFound:
//            return L10n.Common.Controls.Timeline.Header.noStatusFound
//        case .blocking(let name):
//            if let name = name {
//                return L10n.Common.Controls.Timeline.Header.userBlockingWarning(name)
//            } else {
//                return L10n.Common.Controls.Timeline.Header.blockingWarning
//            }
//        case .blocked(let name):
//            if let name = name {
//                return L10n.Common.Controls.Timeline.Header.userBlockedWarning(name)
//            } else {
//                return L10n.Common.Controls.Timeline.Header.blockedWarning
//            }
//        case .suspended(let name):
//            if let name = name {
//                return L10n.Common.Controls.Timeline.Header.userSuspendedWarning(name)
//            } else {
//                return L10n.Common.Controls.Timeline.Header.suspendedWarning
//            }
//        }
//    }
//}

//#if DEBUG && canImport(SwiftUI)
//import SwiftUI
//
//struct TimelineHeaderView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewPreview(width: 375) {
//                let serverSectionHeaderView = TimelineHeaderView()
//                serverSectionHeaderView.iconImageView.image = Item.EmptyStateHeaderAttribute.Reason.blocking(name: nil).iconImage
//                serverSectionHeaderView.messageLabel.text = Item.EmptyStateHeaderAttribute.Reason.blocking(name: nil).message
//                return serverSectionHeaderView
//            }
//            .previewLayout(.fixed(width: 375, height: 400))
//        }
//    }
//}
//#endif
