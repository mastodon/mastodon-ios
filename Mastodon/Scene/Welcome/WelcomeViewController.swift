//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by 高原 on 2021/2/20.
//

import UIKit

final class WelcomeViewController: UIViewController {
    let logoImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.welcomeLogo.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let sloganLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = .black
        label.text = L10n.Common.Label.slogon
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 35),
            logoImageView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -35),
            logoImageView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor, constant: 46),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 65.4/265.1),
        ])
        
        view.addSubview(sloganLabel)
        NSLayoutConstraint.activate([
            sloganLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 16),
            sloganLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -16),
            sloganLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 168),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
