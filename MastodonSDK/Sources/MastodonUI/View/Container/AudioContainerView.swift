//
//  AudioViewContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/8.
//

import CoreDataStack
import UIKit
import MastodonAsset
import MastodonLocalization

//public final class AudioContainerView: UIView {
//    static let cornerRadius: CGFloat = 22
//    
//    let container: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.distribution = .fill
//        stackView.alignment = .center
//        stackView.spacing = 11
//        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
//        stackView.isLayoutMarginsRelativeArrangement = true
//        stackView.layer.cornerRadius = AudioContainerView.cornerRadius
//        stackView.clipsToBounds = true
//        stackView.backgroundColor = Asset.Colors.brandBlue.color
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        return stackView
//    }()
//
//    let playButtonBackgroundView: UIView = {
//        let view = UIView()
//        view.layer.cornerRadius = 16
//        view.clipsToBounds = true
//        view.backgroundColor = Asset.Colors.brandBlue.color
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    let playButton: UIButton = {
//        let button = HighlightDimmableButton(type: .custom)
//        let image = UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .bold))!
//        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
//        
//        let pauseImage = UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .bold))!
//        button.setImage(pauseImage.withRenderingMode(.alwaysTemplate), for: .selected)
//        
//        button.tintColor = .white
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.isEnabled = true
//        return button
//    }()
//    
//    let slider: UISlider = {
//        let slider = UISlider()
//        slider.isContinuous = true
//        slider.translatesAutoresizingMaskIntoConstraints = false
//        slider.minimumTrackTintColor = Asset.Colors.Slider.track.color
//        slider.maximumTrackTintColor = Asset.Colors.Slider.track.color
//        if let image = UIImage.placeholder(size: CGSize(width: 22, height: 22), color: .white).withRoundedCorners(radius: 11) {
//            slider.setThumbImage(image, for: .normal)
//        }
//        return slider
//    }()
//    
//    let timeLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 13, weight: .regular)
//        label.textColor = .white
//        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .right : .left
//        return label
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//}
//
//extension AudioContainerView {
//    private func _init() {
//        addSubview(container)
//        NSLayoutConstraint.activate([
//            container.topAnchor.constraint(equalTo: topAnchor),
//            container.leadingAnchor.constraint(equalTo: leadingAnchor),
//            trailingAnchor.constraint(equalTo: container.trailingAnchor),
//            bottomAnchor.constraint(equalTo: container.bottomAnchor),
//        ])
//        
//        // checkmark
//        playButtonBackgroundView.addSubview(playButton)
//        container.addArrangedSubview(playButtonBackgroundView)
//        NSLayoutConstraint.activate([
//            playButton.centerXAnchor.constraint(equalTo: playButtonBackgroundView.centerXAnchor),
//            playButton.centerYAnchor.constraint(equalTo: playButtonBackgroundView.centerYAnchor),
//            playButtonBackgroundView.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1),
//            playButtonBackgroundView.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1),
//        ])
//
//        container.addArrangedSubview(slider)
//        
//        container.addArrangedSubview(timeLabel)
//        NSLayoutConstraint.activate([
//            timeLabel.widthAnchor.constraint(equalToConstant: 40).priority(.required - 1),
//        ])
//    }
//}
//
//extension AudioContainerView {
//    public struct Configuration: Hashable {
//        
//    }
//}
//
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//struct AudioContainerView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        UIViewPreview(width: 375) {
//            AudioContainerView()
//        }
//        .previewLayout(.fixed(width: 375, height: 100))
//    }
//    
//}
//#endif
//
