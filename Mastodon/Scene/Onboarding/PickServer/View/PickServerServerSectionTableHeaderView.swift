//
//  PickServerServerSectionTableHeaderView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-4.
//

import os.log
import UIKit
import Tabman
import MastodonAsset
import MastodonUI
import MastodonLocalization

protocol PickServerServerSectionTableHeaderViewDelegate: AnyObject {
    func pickServerServerSectionTableHeaderView(_ headerView: PickServerServerSectionTableHeaderView, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    func pickServerServerSectionTableHeaderView(_ headerView: PickServerServerSectionTableHeaderView, searchTextDidChange searchText: String?)
}

final class PickServerServerSectionTableHeaderView: UIView {
    
    static let collectionViewHeight: CGFloat = 30
    static let searchTextFieldHeight: CGFloat = 38
    static let spacing: CGFloat = 11
    
    static let height: CGFloat = collectionViewHeight + spacing + searchTextFieldHeight + spacing
    
    weak var delegate: PickServerServerSectionTableHeaderViewDelegate?

    var diffableDataSource: UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem>?
    
    static func createCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(88), heightDimension: .absolute(PickServerServerSectionTableHeaderView.collectionViewHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: itemSize.widthDimension, heightDimension: itemSize.heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsetsReference = .readableContent
        section.interGroupSpacing = 16
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    let collectionView: UICollectionView = {
        let collectionViewLayout = PickServerServerSectionTableHeaderView.createCollectionViewLayout()
        let view = ControlContainableCollectionView(
            frame: CGRect(origin: .zero, size: CGSize(width: 100, height: PickServerServerSectionTableHeaderView.collectionViewHeight)),
            collectionViewLayout: collectionViewLayout
        )
        view.register(PickServerCategoryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PickServerCategoryCollectionViewCell.self))
        view.backgroundColor = .clear
        view.alwaysBounceVertical = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        return view
    }()
    
    let searchTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = Asset.Scene.Onboarding.searchBarBackground.color
        textField.leftView = {
            let imageView = UIImageView(
                image: UIImage(
                    systemName: "magnifyingglass",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
                )
            )
            imageView.tintColor = Asset.Colors.Label.secondary.color.withAlphaComponent(0.6)
            
            let containerView = UIView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
            
            let paddingView = UIView()
            paddingView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(paddingView)
            NSLayoutConstraint.activate([
                paddingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                paddingView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor),
                paddingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                paddingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                paddingView.widthAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
            ])
            return containerView
        }()
        textField.leftViewMode = .always
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.tintColor = Asset.Colors.Label.primary.color
        textField.textColor = Asset.Colors.Label.primary.color
        textField.adjustsFontForContentSizeCategory = true
        textField.attributedPlaceholder = NSAttributedString(
            string: L10n.Scene.ServerPicker.Input.searchServersOrEnterUrl,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: Asset.Colors.Label.secondary.color.withAlphaComponent(0.6)
            ]
        )
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.keyboardType = .URL
        textField.borderStyle = .none
        
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 10
        textField.layer.cornerCurve = .continuous
        
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.invalidateIntrinsicContentSize()
    }
    
}

extension PickServerServerSectionTableHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        backgroundColor = Asset.Scene.Onboarding.background.color
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.preservesSuperviewLayoutMargins = true
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: PickServerServerSectionTableHeaderView.collectionViewHeight).priority(.required - 1),
        ])
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchTextField)
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: PickServerServerSectionTableHeaderView.spacing),
            searchTextField.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: PickServerServerSectionTableHeaderView.spacing),
            searchTextField.heightAnchor.constraint(equalToConstant: PickServerServerSectionTableHeaderView.searchTextFieldHeight).priority(.required - 1),
        ])
        
        collectionView.delegate = self
        searchTextField.delegate = self        
        searchTextField.addTarget(self, action: #selector(PickServerServerSectionTableHeaderView.textFieldDidChange(_:)), for: .editingChanged)
    }
}

extension PickServerServerSectionTableHeaderView {
    @objc private func textFieldDidChange(_ textField: UITextField) {
        delegate?.pickServerServerSectionTableHeaderView(self, searchTextDidChange: textField.text)
    }
}

// MARK: - UICollectionViewDelegate
extension PickServerServerSectionTableHeaderView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        delegate?.pickServerServerSectionTableHeaderView(self, collectionView: collectionView, didSelectItemAt: indexPath)
    }

}

extension PickServerServerSectionTableHeaderView {

    override func accessibilityElementCount() -> Int {
        guard let diffableDataSource = diffableDataSource else { return 0 }
        return diffableDataSource.snapshot().itemIdentifiers.count + 1
    }

    override func accessibilityElement(at index: Int) -> Any? {
        if let item = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) { return item }
        return searchTextField
    }

}

// MARK: - UITextFieldDelegate
extension PickServerServerSectionTableHeaderView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
