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

  private let cloudBaseImage = Asset.Scene.Welcome.Illustration.cloudBase.image
  private let cloudBaseExtendImage = Asset.Scene.Welcome.Illustration.cloudBaseExtend.image
  private let elephantThreeOnGrassWithTreeTwoImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image
  private let elephantThreeOnGrassWithTreeThreeImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeThree.image
  private let elephantThreeOnGrassImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrass.image
  private let elephantThreeOnGrassExtendImage = Asset.Scene.Welcome.Illustration.elephantThreeOnGrassExtend.image

  var elephantOnAirplaneLeftConstraint: NSLayoutConstraint?
  var leftHillLeftConstraint: NSLayoutConstraint?
  var centerHillLeftConstraint: NSLayoutConstraint?
  var rightHillRightConstraint: NSLayoutConstraint?

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
    let imageView = UIImageView(image: Asset.Scene.Welcome.Illustration.elephantThreeOnGrassWithTreeTwo.image)
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

  private func _init() {
    backgroundColor = Asset.Scene.Welcome.Illustration.backgroundCyan.color

    cloudBaseImageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(cloudBaseImageView)
    NSLayoutConstraint.activate([
      cloudBaseImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      cloudBaseImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      cloudBaseImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      cloudBaseImageView.topAnchor.constraint(equalTo: topAnchor)
    ])

    rightHillImageView.translatesAutoresizingMaskIntoConstraints = false

    let rightHillRightConstraint = rightAnchor.constraint(equalTo: rightHillImageView.rightAnchor)
    addSubview(rightHillImageView)
    NSLayoutConstraint.activate([
      rightHillImageView.widthAnchor.constraint(equalTo: widthAnchor),
      rightHillRightConstraint,
      bottomAnchor.constraint(equalTo: rightHillImageView.bottomAnchor),
    ])
    self.rightHillRightConstraint = rightHillRightConstraint

    leftHillImageView.translatesAutoresizingMaskIntoConstraints = false

    let leftHillLeftConstraint = leftHillImageView.leftAnchor.constraint(equalTo: leftAnchor)
    addSubview(leftHillImageView)
    NSLayoutConstraint.activate([
      leftHillImageView.widthAnchor.constraint(equalTo: widthAnchor),
      leftHillLeftConstraint,
      bottomAnchor.constraint(equalTo: leftHillImageView.bottomAnchor),
    ])

    self.leftHillLeftConstraint = leftHillLeftConstraint

    centerHillImageView.translatesAutoresizingMaskIntoConstraints = false

    let centerHillLeftConstraint = centerHillImageView.leftAnchor.constraint(equalTo: leftAnchor)

    addSubview(centerHillImageView)
    NSLayoutConstraint.activate([
      centerHillLeftConstraint,
      bottomAnchor.constraint(equalTo: centerHillImageView.bottomAnchor),
      trailingAnchor.constraint(equalTo: centerHillImageView.trailingAnchor),
    ])

    self.centerHillLeftConstraint = centerHillLeftConstraint

    addSubview(elephantOnAirplaneWithContrailImageView)

    let elephantOnAirplaneLeftConstraint = leftAnchor.constraint(equalTo: elephantOnAirplaneWithContrailImageView.leftAnchor, constant: 178)  // add 12pt bleeding
    NSLayoutConstraint.activate([
      elephantOnAirplaneLeftConstraint,
      elephantOnAirplaneWithContrailImageView.bottomAnchor.constraint(equalTo: centerYAnchor),
      // make a little bit large
      elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.84),
    ])

    self.elephantOnAirplaneLeftConstraint = elephantOnAirplaneLeftConstraint

//    aspectLayoutConstraint = cloudBaseImageView.widthAnchor.constraint(equalTo: cloudBaseImageView.heightAnchor, multiplier: layout.artworkImageSize.width / layout.artworkImageSize.height)
//    aspectLayoutConstraint.isActive = true
  }

  func setup() {

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
    leftHillLeftConstraint?.constant = (contentOffset / 50) + 111
    centerHillLeftConstraint?.constant = (contentOffset / 50) + 111
    rightHillRightConstraint?.constant = (contentOffset / 50) + 111
  }
}
