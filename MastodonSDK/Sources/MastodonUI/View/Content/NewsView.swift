//
//  NewsView.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import Combine
import MastodonAsset

public final class NewsView: UIView {
        
    static let imageViewWidth: CGFloat = 132
    
    var disposeBag = Set<AnyCancellable>()
    
    let container = UIStackView()
    
    let providerFaviconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 2
        imageView.layer.cornerCurve = .continuous
        return imageView
    }()
    
    let providerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        return label
    }()
    
    let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.numberOfLines = 0
        return label
    }()
    
    let footnoteLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 12, weight: .medium))
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
    let imageView = MediaView()

//    let imageView = UIImageView()
//    var imageViewMediaConfiguration: MediaView.Configuration?
    
    public func prepareForReuse() {
        providerFaviconImageView.tag = (0..<Int.max).randomElement() ?? -1
        imageView.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NewsView {
    private func _init() {
        // container: H - [ textContainer | imageView ]
        container.distribution = .fill
        container.axis = .horizontal
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        container.pinToParent()
        
        // textContainer: V - [ providerContainer | headlineLabel | (spacer) | footnoteLabel ]
        let textContainer = UIStackView()
        textContainer.axis = .vertical
        textContainer.spacing = 4
        container.addArrangedSubview(textContainer)
        
        // providerContainer: H - [ providerFaviconImageView | providerNameLabel | (spacer) ]
        let providerContainer = UIStackView()
        providerContainer.axis = .horizontal
        providerContainer.spacing = 4
        textContainer.addArrangedSubview(providerContainer)

        providerFaviconImageView.translatesAutoresizingMaskIntoConstraints = false
        providerContainer.addArrangedSubview(providerFaviconImageView)
        providerContainer.addArrangedSubview(providerNameLabel)
        NSLayoutConstraint.activate([
            providerFaviconImageView.heightAnchor.constraint(equalTo: providerNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
            providerFaviconImageView.widthAnchor.constraint(equalTo: providerNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
        ])
        // low priority for intrinsic size hugging
        providerFaviconImageView.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        providerFaviconImageView.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
        // high priority but lower then layout constraint for size compression
        providerFaviconImageView.setContentCompressionResistancePriority(.required - 11, for: .vertical)
        providerFaviconImageView.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
        providerNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        providerNameLabel.setContentHuggingPriority(.required - 1, for: .vertical)

        // headlineLabel
        textContainer.addArrangedSubview(headlineLabel)
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: 24).priority(.required - 1),
        ])
        // footnoteLabel
        textContainer.addArrangedSubview(footnoteLabel)
        
        // imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 132).priority(.required - 1),
        ])
        imageView.setContentHuggingPriority(.defaultLow - 100, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        imageView.imageView.setContentHuggingPriority(.defaultLow - 100, for: .vertical)
        imageView.imageView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        imageView.blurhashImageView.setContentHuggingPriority(.defaultLow - 100, for: .vertical)
        imageView.blurhashImageView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        imageView.isUserInteractionEnabled = false
    }
}

