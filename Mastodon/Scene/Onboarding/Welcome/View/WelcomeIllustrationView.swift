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

final class WelcomeIllustrationView: UIView {

  let cloudBaseImageView = UIImageView()
  let rightHillImageView = UIImageView()
  let leftHillImageView = UIImageView()
  let centerHillImageView = UIImageView()

  private let cloudBaseImage = Asset.Scene.Welcome.Illustration.cloudBase.image
  private let cloudBaseExtendImage = Asset.Scene.Welcome.Illustration.cloudBaseExtend.image
  private let elephantThreeOnGrassWithTreeTwoImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image
  private let elephantThreeOnGrassWithTreeThreeImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeThree.image
  private let elephantThreeOnGrassImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrass.image
  private let elephantThreeOnGrassExtendImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassExtend.image

  var bottomAnchorLayoutConstraint: NSLayoutConstraint?
  var elephantOnAirplaneLeftConstraint: NSLayoutConstraint?

  let elephantOnAirplaneWithContrailImageView: UIImageView = {
    let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantOnAirplaneWithContrail.image)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    return imageView
  }()

  var layout: Layout = .compact {
    didSet {
      setNeedsLayout()
    }
  }
  var aspectLayoutConstraint: NSLayoutConstraint!

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
  enum Layout {
    case compact
    case regular

    var artworkImageSize: CGSize {
      switch self {
        case .compact:      return CGSize(width: 375, height: 1500)
        case .regular:      return CGSize(width: 547, height: 3000)
      }
    }
  }
}

extension WelcomeIllustrationView {

  private func _init() {
    backgroundColor = Asset.Scene.Welcome.Illustration.backgroundCyan.color

    cloudBaseImageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(cloudBaseImageView)
    NSLayoutConstraint.activate([
      cloudBaseImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      cloudBaseImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      cloudBaseImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    addSubview(elephantOnAirplaneWithContrailImageView)

    let elephantOnAirplaneLeftConstraint = leftAnchor.constraint(equalTo: elephantOnAirplaneWithContrailImageView.leftAnchor, constant: 178)  // add 12pt bleeding
    NSLayoutConstraint.activate([
      elephantOnAirplaneLeftConstraint,
      elephantOnAirplaneWithContrailImageView.bottomAnchor.constraint(equalTo: centerYAnchor),
      // make a little bit large
      elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.84),
    ])

    self.elephantOnAirplaneLeftConstraint = elephantOnAirplaneLeftConstraint
    [
      rightHillImageView,
      leftHillImageView,
      centerHillImageView,
    ].forEach { imageView in
      imageView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(imageView)
      imageView.pinTo(to: cloudBaseImageView)
    }

    aspectLayoutConstraint = cloudBaseImageView.widthAnchor.constraint(equalTo: cloudBaseImageView.heightAnchor, multiplier: layout.artworkImageSize.width / layout.artworkImageSize.height)
    aspectLayoutConstraint.isActive = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    switch layout {
      case .compact:
        layoutCompact()
      case .regular:
        layoutRegular()
    }

    aspectLayoutConstraint.isActive = false
    aspectLayoutConstraint = cloudBaseImageView.widthAnchor.constraint(equalTo: cloudBaseImageView.heightAnchor, multiplier: layout.artworkImageSize.width / layout.artworkImageSize.height)
    aspectLayoutConstraint.isActive = true
  }

  private func layoutCompact() {
    let size = layout.artworkImageSize
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

  private func layoutRegular() {
    let size = layout.artworkImageSize
    let width = size.width
    let height = size.height

    cloudBaseImageView.image = UIGraphicsImageRenderer(size: size).image { context in
      // clear background
      UIColor.clear.setFill()
      context.fill(CGRect(origin: .zero, size: size))

      // draw cloud
      cloudBaseExtendImage.draw(at: CGPoint(x: 0, y: height - cloudBaseExtendImage.size.height))

      rightHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
        // clear background
        UIColor.clear.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // draw elephantThreeOnGrassWithTreeTwoImage
        // elephantThreeOnGrassWithTreeTwo.bottomY - 25 align to elephantThreeOnGrassImage.centerY
        elephantThreeOnGrassWithTreeTwoImage.draw(at: CGPoint(x: width - elephantThreeOnGrassWithTreeTwoImage.size.width, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeTwoImage.size.height - 20))
      }

      leftHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
        // clear background
        UIColor.clear.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // draw elephantThreeOnGrassWithTreeThree
        // elephantThreeOnGrassWithTreeThree.bottomY + 30 align to elephantThreeOnGrassImage.centerY
        elephantThreeOnGrassWithTreeThreeImage.draw(at: CGPoint(x: -160, y: height - 0.5 * elephantThreeOnGrassImage.size.height - elephantThreeOnGrassWithTreeThreeImage.size.height - 80))
      }

      centerHillImageView.image = UIGraphicsImageRenderer(size: size).image { context in
        // clear background
        UIColor.clear.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // draw elephantThreeOnGrass
        elephantThreeOnGrassExtendImage.draw(at: CGPoint(x: 0, y: height - elephantThreeOnGrassExtendImage.size.height))
      }
    }
  }

  func setup() {
    layout = {
      switch traitCollection.userInterfaceIdiom {
        case .phone:
          return .compact
        default:
          return .regular
      }
    }()

    // set illustration
    guard superview == nil else {
      return
    }
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

  func update(contentOffset: CGFloat) {
    // updating the constraints doesn't work smoothly.
    elephantOnAirplaneLeftConstraint?.constant = -(contentOffset / 50) + 111
  }
}
