//
//  WelcomeIllustrationView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-1.
//

import UIKit

final class WelcomeIllustrationView: UIView {
    
    static let artworkImageSize = CGSize(width: 870, height: 2000)
    let artworkImageView = UIImageView()
    
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
        
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(artworkImageView)
        NSLayoutConstraint.activate([
            artworkImageView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            artworkImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            artworkImageView.widthAnchor.constraint(equalTo: artworkImageView.heightAnchor, multiplier: WelcomeIllustrationView.artworkImageSize.width / WelcomeIllustrationView.artworkImageSize.height),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        artworkImageView.image = WelcomeIllustrationView.artworkImage()
    }
    
    static func artworkImage() -> UIImage {
        let size = artworkImageSize
        let width = artworkImageSize.width
        let height = artworkImageSize.height
        let image = UIGraphicsImageRenderer(size: size).image { context in
            // clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: artworkImageSize))
            
            // draw cloud
            let cloudBaseImage = Asset.Welcome.Illustration.cloudBase.image
            cloudBaseImage.draw(at: CGPoint(x: 0, y: height - cloudBaseImage.size.height))
            
            let elephantFourOnGrassWithTreeTwoImage = Asset.Welcome.Illustration.elephantFourOnGrassWithTreeTwo.image
            let elephantThreeOnGrassWithTreeFourImage = Asset.Welcome.Illustration.elephantThreeOnGrassWithTreeFour.image
            let elephantThreeOnGrassImage = Asset.Welcome.Illustration.elephantThreeOnGrass.image
            let elephantTwoImage = Asset.Welcome.Illustration.elephantTwo.image
            let lineDashTwoImage = Asset.Welcome.Illustration.lineDashTwo.image
            
            // let elephantOnAirplaneWithContrailImageView = Asset.Welcome.Illustration.elephantOnAirplaneWithContrail.image
            
            // draw elephantFourOnGrassWithTreeTwo
            // elephantFourOnGrassWithTreeTwo.bottomY + 40 align to elephantThreeOnGrassImage.centerY
            elephantFourOnGrassWithTreeTwoImage.draw(at: CGPoint(x: 0, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantFourOnGrassWithTreeTwoImage.size.height - 40))
            
            // draw elephantThreeOnGrassWithTreeFour
            // elephantThreeOnGrassWithTreeFour.bottomY + 40 align to elephantThreeOnGrassImage.centerY
            elephantThreeOnGrassWithTreeFourImage.draw(at: CGPoint(x: width - elephantThreeOnGrassWithTreeFourImage.size.width, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeFourImage.size.height - 40))
                        
            // draw elephantThreeOnGrass
            elephantThreeOnGrassImage.draw(at: CGPoint(x: 0, y: height - elephantThreeOnGrassImage.size.height))
            
            // darw ineDashTwoImage
            lineDashTwoImage.draw(at: CGPoint(x: 0.5 * elephantThreeOnGrassImage.size.width + 60, y: height - elephantThreeOnGrassImage.size.height - 50))
            
            // draw elephantTwo.image
            elephantTwoImage.draw(at: CGPoint(x: 0, y: height - elephantTwoImage.size.height - 125))
            
            // draw elephantOnAirplaneWithContrailImageView
            // elephantOnAirplaneWithContrailImageView.draw(at: CGPoint(x: 0, y: height - cloudBaseImage.size.height - 0.5 * elephantOnAirplaneWithContrailImageView.size.height))
        }
        
        return image
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

