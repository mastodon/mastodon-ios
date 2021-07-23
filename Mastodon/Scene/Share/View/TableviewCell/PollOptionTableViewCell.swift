//
//  PollOptionTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-25.
//

import UIKit
import Combine

final class PollOptionTableViewCell: UITableViewCell {

    static let height: CGFloat = PollOptionView.height

    var disposeBag = Set<AnyCancellable>()
    
    let pollOptionView = PollOptionView()
    var attribute: PollItem.Attribute?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        guard let voteState = attribute?.voteState else { return }
        switch voteState {
        case .hidden:
            let color = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
            pollOptionView.roundedBackgroundView.backgroundColor = isHighlighted ? color.withAlphaComponent(0.8) : color
        case .reveal:
            break
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        guard let voteState = attribute?.voteState else { return }
        switch voteState {
        case .hidden:
            let color = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
            pollOptionView.roundedBackgroundView.backgroundColor = isHighlighted ? color.withAlphaComponent(0.8) : color
        case .reveal:
            break
        }
    }

}

extension PollOptionTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        pollOptionView.optionTextField.isUserInteractionEnabled = false
        
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        NSLayoutConstraint.activate([
            pollOptionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pollOptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pollOptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pollOptionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
 
    func updateTextAppearance() {
        guard let voteState = attribute?.voteState else {
            pollOptionView.optionTextField.textColor = Asset.Colors.Label.primary.color
            pollOptionView.optionTextField.layer.removeShadow()
            return
        }
        
        switch voteState {
        case .hidden:
            pollOptionView.optionTextField.textColor = Asset.Colors.Label.primary.color
            pollOptionView.optionTextField.layer.removeShadow()
        case .reveal(_, let percentage, _):
            if CGFloat(percentage) * pollOptionView.voteProgressStripView.frame.width > pollOptionView.optionLabelMiddlePaddingView.frame.minX {
                pollOptionView.optionTextField.textColor = .white
                pollOptionView.optionTextField.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
            } else {
                pollOptionView.optionTextField.textColor = Asset.Colors.Label.primary.color
                pollOptionView.optionTextField.layer.removeShadow()
            }
            
            if CGFloat(percentage) * pollOptionView.voteProgressStripView.frame.width > pollOptionView.optionLabelMiddlePaddingView.frame.maxX {
                pollOptionView.optionPercentageLabel.textColor = .white
                pollOptionView.optionPercentageLabel.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
            } else {
                pollOptionView.optionPercentageLabel.textColor = Asset.Colors.Label.primary.color
                pollOptionView.optionPercentageLabel.layer.removeShadow()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextAppearance()
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PollTableViewCell_Previews: PreviewProvider {
    
    static var controls: some View {
        Group {
            UIViewPreview() {
                PollOptionTableViewCell()
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
            UIViewPreview() {
                let cell = PollOptionTableViewCell()
                PollSection.configure(cell: cell, selectState: .off)
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
            UIViewPreview() {
                let cell = PollOptionTableViewCell()
                PollSection.configure(cell: cell, selectState: .on)
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
        }
        .background(Color(.systemBackground))
    }
    
    static var previews: some View {
        Group {
            controls
                .colorScheme(.light)
            controls
                .colorScheme(.dark)
        }
    }
    
}

#endif

