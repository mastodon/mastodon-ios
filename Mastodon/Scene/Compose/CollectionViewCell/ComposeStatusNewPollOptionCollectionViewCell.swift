//
//  ComposeStatusNewPollOptionCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import os.log
import UIKit

protocol ComposeStatusNewPollOptionCollectionViewCellDelegate: class {
    func ComposeStatusNewPollOptionCollectionViewCellDidPressed(_ cell: ComposeStatusNewPollOptionCollectionViewCell)
}

final class ComposeStatusNewPollOptionCollectionViewCell: UICollectionViewCell {
    
    let pollOptionView = PollOptionView()
    
    let singleTagGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    override var isHighlighted: Bool {
        didSet {
            pollOptionView.roundedBackgroundView.backgroundColor = isHighlighted ? Asset.Colors.Background.secondarySystemBackground.color : Asset.Colors.Background.systemBackground.color
            pollOptionView.plusCircleImageView.tintColor = isHighlighted ? Asset.Colors.Button.normal.color.withAlphaComponent(0.5) : Asset.Colors.Button.normal.color
        }
    }
    
    weak var delegate: ComposeStatusNewPollOptionCollectionViewCellDelegate?
    
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

extension ComposeStatusNewPollOptionCollectionViewCell {
    
    private func _init() {
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        NSLayoutConstraint.activate([
            pollOptionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pollOptionView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            pollOptionView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            pollOptionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        pollOptionView.checkmarkImageView.isHidden = true
        pollOptionView.checkmarkBackgroundView.isHidden = true
        pollOptionView.optionPercentageLabel.isHidden = true
        pollOptionView.optionTextField.isHidden = true
        pollOptionView.plusCircleImageView.isHidden = false
        
        pollOptionView.roundedBackgroundView.backgroundColor = Asset.Colors.Background.systemBackground.color
        setupBorderColor()
        
        pollOptionView.addGestureRecognizer(singleTagGestureRecognizer)
        singleTagGestureRecognizer.addTarget(self, action: #selector(ComposeStatusNewPollOptionCollectionViewCell.singleTagGestureRecognizerHandler(_:)))
    }
    
    private func setupBorderColor() {
        pollOptionView.roundedBackgroundView.layer.borderWidth = 1
        pollOptionView.roundedBackgroundView.layer.borderColor = Asset.Colors.Background.secondarySystemBackground.color.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupBorderColor()
    }
    
}

extension ComposeStatusNewPollOptionCollectionViewCell {

    @objc private func singleTagGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.ComposeStatusNewPollOptionCollectionViewCellDidPressed(self)
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ComposeStatusNewPollOptionCollectionViewCell_Previews: PreviewProvider {
    
    static var controls: some View {
        Group {
            UIViewPreview() {
                let cell = ComposeStatusNewPollOptionCollectionViewCell()
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
