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
  static let centerHillStartPosition = 20.0
  static let airplaneStartPosition = -178.0
  static let leftHillStartPosition = 30.0
  static let rightHillStartPosition = -161.0

  static let airplaneSpeed = 50.0
  static let leftHillSpeed = 20.0
  static let centerHillSpeed = 40.0
  static let rightHillSpeed = 20.0
}

final class WelcomeIllustrationView: UIView {

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
    imageView.contentMode = .scaleAspectFit
    imageView.alpha = 0.3
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

    let rightHillRightConstraint = rightAnchor.constraint(equalTo: rightHillImageView.rightAnchor, constant: .rightHillStartPosition)
    addSubview(rightHillImageView)
    NSLayoutConstraint.activate([
      rightHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.64),
      rightHillRightConstraint,
      bottomAnchor.constraint(equalTo: rightHillImageView.bottomAnchor, constant: 149),
    ])
    self.rightHillRightConstraint = rightHillRightConstraint

    let leftHillLeftConstraint = leftAnchor.constraint(equalTo: leftHillImageView.leftAnchor, constant: .leftHillStartPosition)
    addSubview(leftHillImageView)
    NSLayoutConstraint.activate([
      leftHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
      leftHillLeftConstraint,
      bottomAnchor.constraint(equalTo: leftHillImageView.bottomAnchor, constant: 187),
    ])

    self.leftHillLeftConstraint = leftHillLeftConstraint

    let centerHillLeftConstraint = leftAnchor.constraint(equalTo: centerHillImageView.leftAnchor, constant: .centerHillStartPosition)

    addSubview(centerHillImageView)
    NSLayoutConstraint.activate([
      centerHillLeftConstraint,
      bottomAnchor.constraint(equalTo: centerHillImageView.bottomAnchor, constant: -18),
      centerHillImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.2),
    ])

    self.centerHillLeftConstraint = centerHillLeftConstraint

    addSubview(elephantOnAirplaneWithContrailImageView)

    let elephantOnAirplaneLeftConstraint = elephantOnAirplaneWithContrailImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: .airplaneStartPosition)  // add 12pt bleeding
    NSLayoutConstraint.activate([
      elephantOnAirplaneLeftConstraint,
      elephantOnAirplaneWithContrailImageView.bottomAnchor.constraint(equalTo: leftHillImageView.topAnchor),
      // make a little bit large
      elephantOnAirplaneWithContrailImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.84),
    ])

    self.elephantOnAirplaneLeftConstraint = elephantOnAirplaneLeftConstraint
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
    elephantOnAirplaneLeftConstraint?.constant = contentOffset / .airplaneSpeed + .airplaneStartPosition
    leftHillLeftConstraint?.constant = contentOffset / .leftHillSpeed + .leftHillStartPosition
    centerHillLeftConstraint?.constant = contentOffset / .centerHillSpeed + .centerHillStartPosition
    rightHillRightConstraint?.constant = contentOffset / .rightHillSpeed + .rightHillStartPosition
  }
}
