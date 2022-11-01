//
//  AttachmentContainerView+EmptyStateView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

//extension AttachmentContainerView {
//    final class EmptyStateView: UIView {
//
//        static let photoFillSplitImage = Asset.Connectivity.photoFillSplit.image.withRenderingMode(.alwaysTemplate)
//        static let videoSplashImage: UIImage = {
//            let image = UIImage(systemName: "video.slash")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 64))
//            return image
//        }()
//
//        let imageView: UIImageView = {
//            let imageView = UIImageView()
//            imageView.tintColor = Asset.Colors.Label.secondary.color
//            imageView.image = AttachmentContainerView.EmptyStateView.photoFillSplitImage
//            return imageView
//        }()
//        let label: UILabel = {
//            let label = UILabel()
//            label.font = .preferredFont(forTextStyle: .body)
//            label.textColor = Asset.Colors.Label.secondary.color
//            label.textAlignment = .center
//            label.text = L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
//            label.numberOfLines = 2
//            label.adjustsFontSizeToFitWidth = true
//            label.minimumScaleFactor = 0.3
//            return label
//        }()
//
//        override init(frame: CGRect) {
//            super.init(frame: frame)
//            _init()
//        }
//
//        required init?(coder: NSCoder) {
//            super.init(coder: coder)
//            _init()
//        }
//
//    }
//}

//extension AttachmentContainerView.EmptyStateView {
//    private func _init() {
//        layer.masksToBounds = true
//        layer.cornerRadius = AttachmentContainerView.containerViewCornerRadius
//        layer.cornerCurve = .continuous
//        backgroundColor = ThemeService.shared.currentTheme.value.systemGroupedBackgroundColor
//
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.alignment = .center
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(stackView)
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: topAnchor),
//            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//        let topPaddingView = UIView()
//        let middlePaddingView = UIView()
//        let bottomPaddingView = UIView()
//
//        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.addArrangedSubview(topPaddingView)
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.addArrangedSubview(imageView)
//        NSLayoutConstraint.activate([
//            imageView.widthAnchor.constraint(equalToConstant: 92).priority(.defaultHigh),
//            imageView.heightAnchor.constraint(equalToConstant: 76).priority(.defaultHigh),
//        ])
//        imageView.setContentHuggingPriority(.required - 1, for: .vertical)
//        middlePaddingView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.addArrangedSubview(middlePaddingView)
//        stackView.addArrangedSubview(label)
//        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.addArrangedSubview(bottomPaddingView)
//        NSLayoutConstraint.activate([
//            topPaddingView.heightAnchor.constraint(equalTo: middlePaddingView.heightAnchor, multiplier: 1.5),
//            bottomPaddingView.heightAnchor.constraint(equalTo: middlePaddingView.heightAnchor, multiplier: 1.5),
//        ])
//    }
//}

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct AttachmentContainerView_EmptyStateView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        Group {
//            UIViewPreview(width: 375) {
//                let emptyStateView = AttachmentContainerView.EmptyStateView()
//                NSLayoutConstraint.activate([
//                    emptyStateView.heightAnchor.constraint(equalToConstant: 205)
//                ])
//                return emptyStateView
//            }
//            .previewLayout(.fixed(width: 375, height: 205))
//            UIViewPreview(width: 375) {
//                let emptyStateView = AttachmentContainerView.EmptyStateView()
//                NSLayoutConstraint.activate([
//                    emptyStateView.heightAnchor.constraint(equalToConstant: 205)
//                ])
//                return emptyStateView
//            }
//            .preferredColorScheme(.dark)
//            .previewLayout(.fixed(width: 375, height: 205))
//            UIViewPreview(width: 375) {
//                let emptyStateView = AttachmentContainerView.EmptyStateView()
//                emptyStateView.imageView.image = AttachmentContainerView.EmptyStateView.videoSplashImage
//                emptyStateView.label.text = L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.video)
//
//                NSLayoutConstraint.activate([
//                    emptyStateView.heightAnchor.constraint(equalToConstant: 205)
//                ])
//                return emptyStateView
//            }
//            .previewLayout(.fixed(width: 375, height: 205))
//        }
//    }
//
//}
//
//#endif
