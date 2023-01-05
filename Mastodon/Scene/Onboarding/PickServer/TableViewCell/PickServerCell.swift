//
//  PickServerCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import AlamofireImage
import Kanna
import MastodonAsset
import MastodonLocalization

class PickServerCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
        
    let containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4
        return view
    }()
    
    let domainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.numberOfLines = 0
        label.textColor = Asset.Colors.Label.primary.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Theme.System.separator.color
        return view
    }()
    
    let langValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let usersValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private var collapseConstraints: [NSLayoutConstraint] = []
    private var expandConstraints: [NSLayoutConstraint] = []
    
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

// MARK: - Methods to configure appearance
extension PickServerCell {
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Scene.Onboarding.background.color
                
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 1),
            checkbox.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1),
            checkbox.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1),
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            containerView.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 22),
            containerView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 11),
            checkbox.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        
        containerView.addArrangedSubview(domainLabel)
        containerView.addArrangedSubview(descriptionLabel)
        containerView.setCustomSpacing(6, after: descriptionLabel)
        containerView.addArrangedSubview(infoStackView)
        
        infoStackView.addArrangedSubview(usersValueLabel)
        infoStackView.addArrangedSubview(langValueLabel)
        infoStackView.addArrangedSubview(UIView())
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
            checkbox.tintColor = Asset.Colors.Label.primary.color
        } else {
            checkbox.image = UIImage(systemName: "circle")
            checkbox.tintColor = Asset.Colors.Label.secondary.color
        }
    }

}

