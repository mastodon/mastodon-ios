//
//  ComposeStatusPollOptionAppendEntryCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate: AnyObject {
    func composeStatusPollOptionAppendEntryCollectionViewCellDidPressed(_ cell: ComposeStatusPollOptionAppendEntryCollectionViewCell)
}

final class ComposeStatusPollOptionAppendEntryCollectionViewCell: UICollectionViewCell {
        
    let pollOptionView = PollOptionView()
    let reorderBarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "line.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    let singleTagGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    weak var delegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate?
    
    override var isHighlighted: Bool {
        didSet {
            pollOptionView.roundedBackgroundView.backgroundColor = isHighlighted ? UIColor.tertiarySystemGroupedBackground.withAlphaComponent(0.6) : .tertiarySystemGroupedBackground
            pollOptionView.plusCircleImageView.tintColor = isHighlighted ? Asset.Colors.Brand.blurple.color.withAlphaComponent(0.5) : Asset.Colors.Brand.blurple.color
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return pollOptionView.frame.contains(point)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate = nil
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

extension ComposeStatusPollOptionAppendEntryCollectionViewCell {
    
    private func _init() {
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        NSLayoutConstraint.activate([
            pollOptionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pollOptionView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            pollOptionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        reorderBarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reorderBarImageView)
        NSLayoutConstraint.activate([
            reorderBarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            reorderBarImageView.leadingAnchor.constraint(equalTo: pollOptionView.trailingAnchor, constant: ComposeStatusPollOptionCollectionViewCell.reorderHandlerImageLeadingMargin),
            reorderBarImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            reorderBarImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        pollOptionView.checkmarkImageView.isHidden = true
        pollOptionView.checkmarkBackgroundView.isHidden = true
        pollOptionView.optionPercentageLabel.isHidden = true
        pollOptionView.optionTextField.isHidden = true
        pollOptionView.plusCircleImageView.isHidden = false
        
        pollOptionView.roundedBackgroundView.backgroundColor = .tertiarySystemGroupedBackground
        setupBorderColor()
        
        pollOptionView.addGestureRecognizer(singleTagGestureRecognizer)
        singleTagGestureRecognizer.addTarget(self, action: #selector(ComposeStatusPollOptionAppendEntryCollectionViewCell.singleTagGestureRecognizerHandler(_:)))
        
        reorderBarImageView.isHidden = true
    }
    
    private func setupBorderColor() {
        pollOptionView.roundedBackgroundView.layer.borderWidth = 1
        pollOptionView.roundedBackgroundView.layer.borderColor = SystemTheme.tableViewCellSelectionBackgroundColor.withAlphaComponent(0.3).cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupBorderColor()
    }
    
}

extension ComposeStatusPollOptionAppendEntryCollectionViewCell {

    @objc private func singleTagGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        delegate?.composeStatusPollOptionAppendEntryCollectionViewCellDidPressed(self)
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ComposeStatusNewPollOptionCollectionViewCell_Previews: PreviewProvider {
    
    static var controls: some View {
        Group {
            UIViewPreview() {
                let cell = ComposeStatusPollOptionAppendEntryCollectionViewCell()
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
    
}

#endif
