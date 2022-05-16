//
//  FamiliarFollowersDashboardView.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import UIKit
import MastodonAsset

public final class FamiliarFollowersDashboardView: UIView {
    
    let avatarContainerView = UIView()
    var avatarContainerViewWidthLayoutConstraint: NSLayoutConstraint!
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.text = "Followed by Pixelflowers, Lee’s Food, and 4 other mutuals"
        label.textColor = Asset.Colors.Label.secondary.color
        label.numberOfLines = 0
        return label
    }()
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    public func prepareForReuse() {
        
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

extension FamiliarFollowersDashboardView {
    
    private func _init() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(avatarContainerView)
        avatarContainerViewWidthLayoutConstraint = avatarContainerView.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1)
        NSLayoutConstraint.activate([
            avatarContainerViewWidthLayoutConstraint,
            avatarContainerView.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1)
        ])
        stackView.addArrangedSubview(descriptionLabel)
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
