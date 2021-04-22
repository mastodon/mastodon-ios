//
//  SuggestionAccountTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit

protocol SuggestionAccountTableViewCellDelegate: AnyObject {
    func accountButtonPressed(objectID: NSManagedObjectID, cell: SuggestionAccountTableViewCell)
}

final class SuggestionAccountTableViewCell: UITableViewCell {
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: SuggestionAccountTableViewCellDelegate?
    
    let _imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.primary.color
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.brandBlue.color
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
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
        if let plusImage = UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))?.withRenderingMode(.alwaysTemplate) {
            button.setImage(plusImage, for: .normal)
        }
        if let minusImage = UIImage(systemName: "minus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))?.withRenderingMode(.alwaysTemplate) {
            button.setImage(minusImage, for: .selected)
        }
        return button
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = .white
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        _imageView.af.cancelImageRequest()
        _imageView.image = nil
        disposeBag.removeAll()
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
        backgroundColor = .clear
        
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.spacing = 12
        containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 21, bottom: 12, right: 12)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.widthAnchor.constraint(equalToConstant: 42).priority(.required - 1),
            _imageView.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1)
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
    }
    
    func config(with account: MastodonUser, isSelected: Bool) {
        if let url = account.avatarImageURL() {
            _imageView.af.setImage(
                withURL: url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
        }
        titleLabel.text = account.displayName.isEmpty ? account.username : account.displayName
        subTitleLabel.text = account.acct
        button.isSelected = isSelected
        button.publisher(for: .touchUpInside)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.accountButtonPressed(objectID: account.objectID, cell: self)
            }
            .store(in: &disposeBag)
        button.publisher(for: \.isSelected)
            .sink { [weak self] isSelected in
                if isSelected {
                    self?.button.tintColor = Asset.Colors.danger.color
                } else {
                    self?.button.tintColor = Asset.Colors.Label.secondary.color
                }
            }
            .store(in: &disposeBag)
        activityIndicatorView.publisher(for: \.isHidden)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                self?.button.isHidden = !isHidden
            }
            .store(in: &disposeBag)

    }
    
    func startAnimating() {
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }
}
