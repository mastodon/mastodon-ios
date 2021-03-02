//
//  WelcomeIllustrationView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-1.
//

import UIKit

final class WelcomeIllustrationView: UIView {
    
    static let artworkImageSize = CGSize(width: 870, height: 2000)
    
    let cloudBaseImageView = UIImageView()
    let rightHillImageView = UIImageView()
    let leftHillImageView = UIImageView()
    let centerHillImageView = UIImageView()
    let lineDashTwoImageView = UIImageView()
    let elephantTwoImageView = UIImageView()
    
    // layout outside
    let elephantOnAirplaneWithContrailImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Welcome.Illustration.elephantOnAirplaneWithContrail.image)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    let cloudFirstImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Welcome.Illustration.cloudFirst.image)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    let cloudSecondImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Welcome.Illustration.cloudSecond.image)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    let cloudThirdImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.Welcome.Illustration.cloudThird.image)
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
        backgroundColor = Asset.Welcome.Illustration.backgroundCyan.color
        
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
            lineDashTwoImageView,
            elephantTwoImageView,
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
        
        let elephantFourOnGrassWithTreeTwoImage = Asset.Welcome.Illustration.elephantFourOnGrassWithTreeTwo.image
        let elephantThreeOnGrassWithTreeFourImage = Asset.Welcome.Illustration.elephantThreeOnGrassWithTreeFour.image
        let elephantThreeOnGrassImage = Asset.Welcome.Illustration.elephantThreeOnGrass.image
        let elephantTwoImage = Asset.Welcome.Illustration.elephantTwo.image
        let lineDashTwoImage = Asset.Welcome.Illustration.lineDashTwo.image
        
        
        cloudBaseImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // draw cloud
            let cloudBaseImage = Asset.Welcome.Illustration.cloudBase.image
            cloudBaseImage.draw(at: CGPoint(x: 0, y: height - cloudBaseImage.size.height))
        }
        
        rightHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantThreeOnGrassWithTreeFour
            // elephantThreeOnGrassWithTreeFour.bottomY + 40 align to elephantThreeOnGrassImage.centerY
            elephantThreeOnGrassWithTreeFourImage.draw(at: CGPoint(x: width - elephantThreeOnGrassWithTreeFourImage.size.width, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeFourImage.size.height - 40))
        }
        
        leftHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
    
            // draw elephantFourOnGrassWithTreeTwo
            // elephantFourOnGrassWithTreeTwo.bottomY + 40 align to elephantThreeOnGrassImage.centerY
            elephantFourOnGrassWithTreeTwoImage.draw(at: CGPoint(x: 0, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantFourOnGrassWithTreeTwoImage.size.height - 40))
        }
        
        centerHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantThreeOnGrass
            elephantThreeOnGrassImage.draw(at: CGPoint(x: 0, y: height - elephantThreeOnGrassImage.size.height))
        }
        
        lineDashTwoImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // darw ineDashTwoImage
            lineDashTwoImage.draw(at: CGPoint(x: 0.5 * elephantThreeOnGrassImage.size.width + 60, y: height - elephantThreeOnGrassImage.size.height - 50))
        }
        
        elephantTwoImageView.image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // draw elephantTwo.image
            elephantTwoImage.draw(at: CGPoint(x: 0, y: height - elephantTwoImage.size.height - 125))
        }
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct WelcomeIllustrationView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 870) {
                WelcomeIllustrationView()
            }
            .previewLayout(.fixed(width: 870, height: 2000))
            UIViewPreview(width: 375) {
                WelcomeIllustrationView()
            }
            .previewLayout(.fixed(width: 375, height: 812))
            UIViewPreview(width: 428) {
                WelcomeIllustrationView()
            }
            .previewLayout(.fixed(width: 428, height: 926))
        }
    }
    
}

#endif

