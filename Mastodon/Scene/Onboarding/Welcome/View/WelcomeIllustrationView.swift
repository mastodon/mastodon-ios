//
//  WelcomeIllustrationView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-1.
//

import UIKit

final class WelcomeIllustrationView: UIView {
    
    static let artworkImageSize = CGSize(width: 375, height: 1500)
    
    let cloudBaseImageView = UIImageView()
    let rightHillImageView = UIImageView()
    let leftHillImageView = UIImageView()
    let centerHillImageView = UIImageView()
    
    private let cloudBaseImage = Asset.Scene.Welcome.Illustration.cloudBase.image
    private let elephantThreeOnGrassWithTreeTwoImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image
    private let elephantThreeOnGrassWithTreeThreeImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeThree.image
    private let elephantThreeOnGrassImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrass.image
    
    // layout outside
    let elephantOnAirplaneWithContrailImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantOnAirplaneWithContrail.image)
        imageView.contentMode = .scaleAspectFill
        return imageView
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

extension WelcomeIllustrationView {
    
    private func _init() {
        backgroundColor = Asset.Scene.Welcome.Illustration.backgroundCyan.color
        
        let topPaddingView = UIView()
        
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.topAnchor.constraint(equalTo: topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        cloudBaseImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cloudBaseImageView)
        NSLayoutConstraint.activate([
            cloudBaseImageView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            cloudBaseImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cloudBaseImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cloudBaseImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cloudBaseImageView.widthAnchor.constraint(equalTo: cloudBaseImageView.heightAnchor, multiplier: WelcomeIllustrationView.artworkImageSize.width / WelcomeIllustrationView.artworkImageSize.height),
        ])
        
        [
            rightHillImageView,
            leftHillImageView,
            centerHillImageView,
        ].forEach { imageView in
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: cloudBaseImageView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: cloudBaseImageView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: cloudBaseImageView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: cloudBaseImageView.bottomAnchor),
            ])
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateImage()
    }
    
    private func updateImage() {
        let size = WelcomeIllustrationView.artworkImageSize
        let width = size.width
        let height = size.height
        
        cloudBaseImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw cloud
            cloudBaseImage.draw(at: CGPoint(x: 0, y: height - cloudBaseImage.size.height))
        }

        rightHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantThreeOnGrassWithTreeTwoImage
            // elephantThreeOnGrassWithTreeTwo.bottomY - 25 align to elephantThreeOnGrassImage.centerY
            elephantThreeOnGrassWithTreeTwoImage.draw(at: CGPoint(x: width - elephantThreeOnGrassWithTreeTwoImage.size.width, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeTwoImage.size.height + 25))
        }

        leftHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantThreeOnGrassWithTreeThree
            // elephantThreeOnGrassWithTreeThree.bottomY + 30 align to elephantThreeOnGrassImage.centerY
            elephantThreeOnGrassWithTreeThreeImage.draw(at: CGPoint(x: 0, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeThreeImage.size.height - 30))
        }

        centerHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantThreeOnGrass
            elephantThreeOnGrassImage.draw(at: CGPoint(x: 0, y: height - elephantThreeOnGrassImage.size.height))
        }
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct WelcomeIllustrationView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                WelcomeIllustrationView()
            }
            .previewLayout(.fixed(width: 375, height: 1500))
            UIViewPreview(width: 1125) {
                WelcomeIllustrationView()
            }
            .previewLayout(.fixed(width: 1125, height: 5000))
        }
    }
    
}

#endif

