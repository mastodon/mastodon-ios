//
//  NewsView.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonAsset

public final class NewsView: UIView {
    
    let container = UIStackView()
    
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
    
    public func prepareForReuse() {
        imageView.prepareForReuse()
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
        container.axis = .horizontal
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // textContainer: V - [ providerContainer | headlineLabel | (spacer) | footnoteLabel ]
        let textContainer = UIStackView()
        textContainer.axis = .vertical
        textContainer.spacing = 4
        container.addArrangedSubview(textContainer)
        
        // providerContainer: H - [ providerFavIconImageView | providerNameLabel | (spacer) ]
        let providerContainer = UIStackView()
        providerContainer.axis = .horizontal
        textContainer.addArrangedSubview(providerContainer)

        providerContainer.addArrangedSubview(providerNameLabel)
        
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
        imageView.isUserInteractionEnabled = false
    }
}

