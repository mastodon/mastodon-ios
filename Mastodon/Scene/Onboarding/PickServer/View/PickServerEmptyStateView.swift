//
//  PickServerEmptyStateView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/6.
//

import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class PickServerEmptyStateView: UIView {
    
    var topPaddingViewTopLayoutConstraint: NSLayoutConstraint!
    
    let networkIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        let configuration = UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        imageView.image = UIImage(systemName: "wifi.exclamationmark", withConfiguration: configuration)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    let infoLabel: UILabel = {
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

extension PickServerEmptyStateView {
    
    private func _init() {
        backgroundColor = .clear
        
        let topPaddingView = UIView()
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topPaddingView)
        topPaddingViewTopLayoutConstraint = topPaddingView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            topPaddingViewTopLayoutConstraint,
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
        containerStackView.addArrangedSubview(networkIndicatorImageView)
        
        let infoContainerStackView = UIStackView()
        infoContainerStackView.axis = .horizontal
        infoContainerStackView.distribution = .fill
        
        infoContainerStackView.addArrangedSubview(activityIndicatorView)
        infoContainerStackView.spacing = 4
        activityIndicatorView.setContentHuggingPriority(.required - 1, for: .horizontal)
        
        infoContainerStackView.addArrangedSubview(infoLabel)
        infoLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        infoLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        containerStackView.addArrangedSubview(infoContainerStackView)
        
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
            topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor, multiplier: 2.5).priority(.defaultHigh),    // magic scale
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
    }
    
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct PickServerEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let emptyStateView = PickServerEmptyStateView()
                emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.badNetwork
                emptyStateView.infoLabel.textAlignment = .center
                emptyStateView.activityIndicatorView.stopAnimating()
                return emptyStateView
            }
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Bad Network")
            UIViewPreview(width: 375) {
                let emptyStateView = PickServerEmptyStateView()
                emptyStateView.networkIndicatorImageView.isHidden = true
                emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.findingServers
                emptyStateView.infoLabel.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .right : .left
                emptyStateView.activityIndicatorView.startAnimating()
                return emptyStateView
            }
            .previewLayout(.fixed(width: 375, height: 44))
            .previewDisplayName("Loading…")
        }
    }
}
#endif
