//
//  WelcomeIllustrationView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-1.
//

import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

fileprivate extension CGFloat {
    static let cloudsStartPosition = -20.0
    static let centerHillStartPosition = 20.0
    static let airplaneStartPosition = -178.0
    static let leftHillStartPosition = 30.0
    static let rightHillStartPosition = -125.0
}

final class WelcomeIllustrationView: UIView {
    
    private let cloudBaseImage = Asset.Scene.Welcome.Illustration.cloudBase.image
    private let elephantThreeOnGrassWithTreeTwoImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image
    private let elephantThreeOnGrassWithTreeThreeImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeThree.image
    private let elephantThreeOnGrassImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrass.image
    private let elephantThreeOnGrassExtendImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassExtend.image
    
    let elephantOnAirplaneWithContrailImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantOnAirplaneWithContrail.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let rightHillImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let leftHillImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeThree.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let centerHillImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantThreeOnGrass.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let cloudBaseImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.cloudBase.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    var aspectLayoutConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    // modifiers for animations
    private lazy var cloudsDrag: CGFloat = -(bounds.width / 64)
    private lazy var airplaneDrag: CGFloat = bounds.width / 64
}

extension WelcomeIllustrationView {
    
    private func _init() {
        backgroundColor = Asset.Scene.Welcome.Illustration.backgroundCyan.color
        
        cloudBaseImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cloudBaseImageView)

        NSLayoutConstraint.activate([
            cloudBaseImageView.leftAnchor.constraint(equalTo: leftAnchor),
            cloudBaseImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cloudBaseImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cloudBaseImageView.topAnchor.constraint(equalTo: topAnchor)
        ])

        addSubview(rightHillImageView)
        NSLayoutConstraint.activate([
            rightHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.64),
            rightAnchor.constraint(equalTo: rightHillImageView.rightAnchor, constant: .rightHillStartPosition),
            bottomAnchor.constraint(equalTo: rightHillImageView.bottomAnchor, constant: 149),
        ])

        addSubview(leftHillImageView)
        NSLayoutConstraint.activate([
            leftHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
            leftAnchor.constraint(equalTo: leftHillImageView.leftAnchor, constant: .leftHillStartPosition),
            bottomAnchor.constraint(equalTo: leftHillImageView.bottomAnchor, constant: 187),
        ])

        addSubview(elephantOnAirplaneWithContrailImageView)

        addSubview(centerHillImageView)
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: centerHillImageView.leftAnchor, constant: .centerHillStartPosition),
            bottomAnchor.constraint(equalTo: centerHillImageView.bottomAnchor),
            centerHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.1),
        ])

        NSLayoutConstraint.activate([
            elephantOnAirplaneWithContrailImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: .airplaneStartPosition),
            elephantOnAirplaneWithContrailImageView.bottomAnchor.constraint(equalTo: leftHillImageView.topAnchor),
            // make a little bit large
            elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.84),
        ])
        
    }
    
    func setup() {
        contentMode = .scaleAspectFit
        
        cloudBaseImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -5, maxX: 5, minY: -5, maxY: 5)
        )
        rightHillImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -15, maxX: 25, minY: -10, maxY: 10)
        )
        leftHillImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -25, maxX: 15, minY: -15, maxY: 15)
        )
        centerHillImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -14, maxX: 14, minY: -5, maxY: 25)
        )
        
        elephantOnAirplaneWithContrailImageView.addMotionEffect(
            UIInterpolatingMotionEffect.motionEffect(minX: -20, maxX: 12, minY: -20, maxY: 12)  // maxX should not larger then the bleeding (12pt)
        )
    }
}
