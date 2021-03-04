//
//  PickServerCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import UIKit
import MastodonSDK
import Kingfisher
import Kanna

protocol PickServerCellDelegate: class {
    func pickServerCell(modeChange server: Mastodon.Entity.Server, newMode: PickServerCell.Mode, updates: (() -> Void))
}

class PickServerCell: UITableViewCell {
    
    weak var delegate: PickServerCellDelegate?
    
    enum Mode {
        case collapse
        case expand
    }
    
    private var containerView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 10, right: 16)
        view.backgroundColor = Asset.Colors.lightWhite.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var domainLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.lightDarkGray.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.tintColor = Asset.Colors.lightSecondaryText.color
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textColor = Asset.Colors.lightDarkGray.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let thumbnailActivityIdicator = UIActivityIndicatorView(style: .medium)
    
    private var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var expandBox: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var expandButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(L10n.Scene.ServerPicker.Button.seemore, for: .normal)
        button.setTitle(L10n.Scene.ServerPicker.Button.seeless, for: .selected)
        button.setTitleColor(Asset.Colors.lightBrandBlue.color, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var seperator: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.lightBackground.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var langValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var usersValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var categoryValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var langTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.language
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var usersTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.users
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.category
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var collapseConstraints: [NSLayoutConstraint] = []
    private var expandConstraints: [NSLayoutConstraint] = []
    
    var mode: PickServerCell.Mode = .collapse {
        didSet {
            updateMode()
        }
    }
    
    var server: Mastodon.Entity.Server? {
        didSet {
            updateServerInfo()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.af.cancelImageRequest()
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
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(domainLabel)
        containerView.addSubview(checkbox)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(seperator)
        
        containerView.addSubview(expandButton)
        
        // Always add the expandbox which contains elements only visible in expand mode
        containerView.addSubview(expandBox)
        expandBox.addSubview(thumbnailImageView)
        expandBox.addSubview(infoStackView)
        expandBox.isHidden = true
        
        let verticalInfoStackViewLang = makeVerticalInfoStackView(arrangedView: langValueLabel, langTitleLabel)
        let verticalInfoStackViewUsers = makeVerticalInfoStackView(arrangedView: usersValueLabel, usersTitleLabel)
        let verticalInfoStackViewCategory = makeVerticalInfoStackView(arrangedView: categoryValueLabel, categoryTitleLabel)
        infoStackView.addArrangedSubview(verticalInfoStackViewLang)
        infoStackView.addArrangedSubview(verticalInfoStackViewUsers)
        infoStackView.addArrangedSubview(verticalInfoStackViewCategory)
        
        let expandButtonTopConstraintInCollapse = expandButton.topAnchor.constraint(equalTo: descriptionLabel.lastBaselineAnchor, constant: 12).priority(.required)
        collapseConstraints.append(expandButtonTopConstraintInCollapse)
        
        let expandButtonTopConstraintInExpand = expandButton.topAnchor.constraint(equalTo: expandBox.bottomAnchor, constant: 8).priority(.defaultHigh)
        expandConstraints.append(expandButtonTopConstraintInExpand)
        
        NSLayoutConstraint.activate([
            // Set background view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 1),
            
            // Set bottom separator
            seperator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: seperator.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: seperator.topAnchor),
            seperator.heightAnchor.constraint(equalToConstant: 1).priority(.defaultHigh),
            
            domainLabel.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            domainLabel.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            
            checkbox.widthAnchor.constraint(equalToConstant: 23),
            checkbox.heightAnchor.constraint(equalToConstant: 22),
            containerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: checkbox.trailingAnchor),
            checkbox.leadingAnchor.constraint(equalTo: domainLabel.trailingAnchor, constant: 16),
            checkbox.centerYAnchor.constraint(equalTo: domainLabel.centerYAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: domainLabel.bottomAnchor, constant: 8),
            containerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            
            // Set expandBox constraints
            expandBox.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            containerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: expandBox.trailingAnchor),
            expandBox.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            expandBox.bottomAnchor.constraint(equalTo: infoStackView.bottomAnchor).priority(.defaultHigh),
            
            thumbnailImageView.topAnchor.constraint(equalTo: expandBox.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: expandBox.leadingAnchor),
            expandBox.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor, multiplier: 151.0 / 303.0).priority(.defaultHigh),
            
            infoStackView.leadingAnchor.constraint(equalTo: expandBox.leadingAnchor),
            expandBox.trailingAnchor.constraint(equalTo: infoStackView.trailingAnchor),
            infoStackView.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 16),
            
            expandButton.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            containerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: expandButton.trailingAnchor),
            containerView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: expandButton.bottomAnchor),
        ])
        
        thumbnailActivityIdicator.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.addSubview(thumbnailActivityIdicator)
        NSLayoutConstraint.activate([
            thumbnailActivityIdicator.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            thumbnailActivityIdicator.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
        ])
        thumbnailActivityIdicator.hidesWhenStopped = true
        thumbnailActivityIdicator.stopAnimating()
        
        NSLayoutConstraint.activate(collapseConstraints)
        
        domainLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        domainLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        descriptionLabel.setContentHuggingPriority(.required - 2, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        expandButton.addTarget(self, action: #selector(expandButtonDidClicked(_:)), for: .touchUpInside)
    }
    
    private func makeVerticalInfoStackView(arrangedView: UIView...) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 2
        arrangedView.forEach { stackView.addArrangedSubview($0) }
        return stackView
    }
    
    private func updateMode() {
        switch mode {
        case .collapse:
            expandBox.isHidden = true
            expandButton.isSelected = false
            NSLayoutConstraint.deactivate(expandConstraints)
            NSLayoutConstraint.activate(collapseConstraints)
        case .expand:
            expandBox.isHidden = false
            expandButton.isSelected = true
            NSLayoutConstraint.activate(expandConstraints)
            NSLayoutConstraint.deactivate(collapseConstraints)
            
            updateThumbnail()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkbox.image = UIImage(systemName: "circle")
        }
    }
    
    @objc
    private func expandButtonDidClicked(_ sender: UIButton) {
        let newMode: Mode = mode == .collapse ? .expand : .collapse
        delegate?.pickServerCell(modeChange: server!, newMode: newMode, updates: { [weak self] in
            self?.mode = newMode
        })
    }
}

// MARK: - Methods to update data
extension PickServerCell {
    private func updateServerInfo() {
        guard let serverInfo = server else { return }
        domainLabel.text = serverInfo.domain
        descriptionLabel.text = {
            guard let html = try? HTML(html: serverInfo.description, encoding: .utf8) else {
                return serverInfo.description
            }
            
            return html.text ?? serverInfo.description
        }()
        langValueLabel.text = serverInfo.language.uppercased()
        usersValueLabel.text = parseUsersCount(serverInfo.totalUsers)
        categoryValueLabel.text = serverInfo.category.uppercased()
    }
    
    private func updateThumbnail() {
        guard let serverInfo = server else { return }
        
        thumbnailActivityIdicator.startAnimating()
        thumbnailImageView.af.setImage(
            withURL: URL(string: serverInfo.proxiedThumbnail ?? "")!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.33),
            completion: { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success, .failure:
                    self.thumbnailActivityIdicator.stopAnimating()
                }
            }
        )
    }
    
    private func parseUsersCount(_ usersCount: Int) -> String {
        switch usersCount {
        case 0..<1000:
            return "\(usersCount)"
        default:
            let usersCountInThousand = Float(usersCount) / 1000.0
            return String(format: "%.1fK", usersCountInThousand)
        }
    }
}
