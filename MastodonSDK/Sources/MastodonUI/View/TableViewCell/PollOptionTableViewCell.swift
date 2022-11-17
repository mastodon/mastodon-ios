//
//  PollOptionTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-25.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

public final class PollOptionTableViewCell: UITableViewCell {

    static let height: CGFloat = PollOptionView.height

    public var disposeBag = Set<AnyCancellable>()
    
    public let pollOptionView = PollOptionView()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        pollOptionView.prepareForReuse()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        pollOptionView.alpha = highlighted ? 0.5 : 1
    }

}

extension PollOptionTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        pollOptionView.isUserInteractionEnabled = false
        // pollOptionView.optionTextField.isUserInteractionEnabled = false
        
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        pollOptionView.pinToParent()
        pollOptionView.setup(style: .plain)
    }
    
}
