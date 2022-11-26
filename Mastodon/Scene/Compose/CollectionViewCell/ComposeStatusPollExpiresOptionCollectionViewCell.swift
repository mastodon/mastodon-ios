//
//  ComposeStatusPollExpiresOptionCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

//protocol ComposeStatusPollExpiresOptionCollectionViewCellDelegate: AnyObject {
//    func composeStatusPollExpiresOptionCollectionViewCell(_ cell: ComposeStatusPollExpiresOptionCollectionViewCell, didSelectExpiresOption expiresOption: ComposeStatusPollItem.PollExpiresOptionAttribute.ExpiresOption)
//}
//
//final class ComposeStatusPollExpiresOptionCollectionViewCell: UICollectionViewCell {
//    
//    var disposeBag = Set<AnyCancellable>()
//    weak var delegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate?
//    
//    let durationButton: UIButton = {
//        let button = HighlightDimmableButton()
//        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 12))
//        button.expandEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: -20, right: -20)
//        button.setTitle(L10n.Scene.Compose.Poll.durationTime(L10n.Scene.Compose.Poll.thirtyMinutes), for: .normal)
//        button.setTitleColor(Asset.Colors.brand.color, for: .normal)
//        return button
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//    
//}
//
//extension ComposeStatusPollExpiresOptionCollectionViewCell {
//    
//    private typealias ExpiresOption = ComposeStatusPollItem.PollExpiresOptionAttribute.ExpiresOption
//    
//    private func _init() {
//        durationButton.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(durationButton)
//        NSLayoutConstraint.activate([
//            durationButton.topAnchor.constraint(equalTo: contentView.topAnchor),
//            durationButton.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: PollOptionView.checkmarkBackgroundLeadingMargin),
//            durationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//        
//        let children = ExpiresOption.allCases.map { expiresOption -> UIAction in
//            UIAction(title: expiresOption.title, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] action in
//                guard let self = self else { return }
//                self.expiresOptionActionHandler(action, expiresOption: expiresOption)
//            }
//        }
//        durationButton.menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
//        durationButton.showsMenuAsPrimaryAction = true
//    }
//    
//}
//
//extension ComposeStatusPollExpiresOptionCollectionViewCell {
//
//    private func expiresOptionActionHandler(_ sender: UIAction, expiresOption: ExpiresOption) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, expiresOption.title)
//        delegate?.composeStatusPollExpiresOptionCollectionViewCell(self, didSelectExpiresOption: expiresOption)
//    }
//    
//}
