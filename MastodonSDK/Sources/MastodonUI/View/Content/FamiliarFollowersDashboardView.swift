//
//  FamiliarFollowersDashboardView.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import UIKit
import MastodonAsset
import MetaTextKit

public final class FamiliarFollowersDashboardView: UIView {
    
    let avatarContainerView = UIView()
    var avatarContainerViewWidthLayoutConstraint: NSLayoutConstraint!
    var avatarContainerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    let descriptionMetaLabel = MetaLabel(style: .profileCardFamiliarFollowerFooter)
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension FamiliarFollowersDashboardView {
    
    private func _init() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.pinToParent()
        
        avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(avatarContainerView)
        avatarContainerViewWidthLayoutConstraint = avatarContainerView.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1)
        avatarContainerViewHeightLayoutConstraint = avatarContainerView.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1)
        NSLayoutConstraint.activate([
            avatarContainerViewWidthLayoutConstraint,
            avatarContainerViewHeightLayoutConstraint
        ])
        stackView.addArrangedSubview(descriptionMetaLabel)
        descriptionMetaLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        descriptionMetaLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        descriptionMetaLabel.isUserInteractionEnabled = false
    }
    
}


#if DEBUG
import SwiftUI
struct FamiliarFollowersDashboardView_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            FamiliarFollowersDashboardView()
        }
    }
}
#endif
