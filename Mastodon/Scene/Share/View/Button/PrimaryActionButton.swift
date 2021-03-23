//
//  PrimaryActionButton.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit

class PrimaryActionButton: UIButton {
    
    var isLoading: Bool = false
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var originalButtonTitle: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension PrimaryActionButton {
    
    private func _init() {
        titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        setTitleColor(.white, for: .normal)
        setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Button.normal.color), for: .normal)
        setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Button.normal.color.withAlphaComponent(0.5)), for: .highlighted)
        setBackgroundImage(UIImage.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        applyCornerRadius(radius: 10)
    }
    
    func showLoading() {
        guard !isLoading else { return }
        isEnabled = false
        isLoading = true
        originalButtonTitle = title(for: .disabled)
        self.setTitle("", for: .disabled)
        
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        guard isLoading else { return }
        isLoading = false
        if activityIndicator.superview == self {
            activityIndicator.removeFromSuperview()
        }
        isEnabled = true
        self.setTitle(originalButtonTitle, for: .disabled)
    }
}
