//
//  NavigationBarProgressView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/16.
//

import UIKit
import MastodonAsset
import MastodonLocalization

class NavigationBarProgressView: UIView {
    
    static let progressAnimationDuration: TimeInterval = 0.3
    
    let sliderView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Brand.blurple.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var sliderTrailingAnchor: NSLayoutConstraint!
    
    var progress: CGFloat = 0 {
        willSet(value) {
            sliderTrailingAnchor.constant = (1 - progress) * bounds.width
            UIView.animate(withDuration: NavigationBarProgressView.progressAnimationDuration) {
                self.setNeedsLayout()
            }
        }
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

extension NavigationBarProgressView {
    func _init() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
        addSubview(sliderView)
        sliderTrailingAnchor = trailingAnchor.constraint(equalTo: sliderView.trailingAnchor)
        NSLayoutConstraint.activate([
            sliderView.topAnchor.constraint(equalTo: topAnchor),
            sliderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sliderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sliderTrailingAnchor
        ])
    }
}
