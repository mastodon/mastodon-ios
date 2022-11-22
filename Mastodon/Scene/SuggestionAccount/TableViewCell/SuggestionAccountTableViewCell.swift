//
//  SuggestionAccountTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import os.log
import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonLocalization
import MastodonUI

protocol SuggestionAccountTableViewCellDelegate: AnyObject {
    func suggestionAccountTableViewCell(_ cell: SuggestionAccountTableViewCell, friendshipDidPressed button: UIButton)
}

final class SuggestionAccountTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "SuggestionAccountTableViewCell", category: "View")
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SuggestionAccountTableViewCellDelegate?
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    let avatarButton = AvatarButton()
    
    let titleLabel = MetaLabel(style: .statusName)
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    let buttonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    let button: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        let image = UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
        button.setImage(image, for: .normal)
        return button
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        avatarButton.avatarImageView.prepareForReuse()
        viewModel.prepareForReuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

}

extension SuggestionAccountTableViewCell {
    
    private func configure() {
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.spacing = 12
        containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 21, bottom: 12, right: 12)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        containerStackView.pinToParent()
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: 42).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1),
        ])
        
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.distribution = .fill
        textStackView.alignment = .leading
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(titleLabel)
        subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(subTitleLabel)
        subTitleLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        
        containerStackView.addArrangedSubview(textStackView)
        textStackView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(buttonContainer)
        NSLayoutConstraint.activate([
            buttonContainer.widthAnchor.constraint(equalToConstant: 24).priority(.required - 1),
            buttonContainer.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1),
        ])
        buttonContainer.setContentHuggingPriority(.required - 1, for: .horizontal)
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(button)
        buttonContainer.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            buttonContainer.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
            buttonContainer.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),
            buttonContainer.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            buttonContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        
        button.addTarget(self, action: #selector(SuggestionAccountTableViewCell.buttonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension SuggestionAccountTableViewCell {
    @objc private func buttonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.suggestionAccountTableViewCell(self, friendshipDidPressed: sender)
    }
}

extension SuggestionAccountTableViewCell {
    
    func startAnimating() {
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        button.isHidden = true
    }

    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
        button.isHidden = false
    }
    
}
