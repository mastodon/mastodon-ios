//
//  ProfileStatusDashboardMeterView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit

final class ProfileStatusDashboardMeterView: UIView {
    
    let numberLabel: UILabel = {
        let label = UILabel()
        label.font = {
            let font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            return font.fontDescriptor.withDesign(.rounded).flatMap {
                UIFont(descriptor: $0, size: 20)
            } ?? font
        }()
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "999"
        label.textAlignment = .center
        return label
    }()
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Profile.Dashboard.posts
        label.textAlignment = .center
        return label
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

extension ProfileStatusDashboardMeterView {
    private func _init() {
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: topAnchor),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: numberLabel.trailingAnchor),
        ])
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: textLabel.bottomAnchor),
        ])
    }
}

#if DEBUG
import SwiftUI

struct ProfileStatusDashboardMeterView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 54) {
            ProfileStatusDashboardMeterView()
        }
        .previewLayout(.fixed(width: 54, height: 41))
    }
}
#endif
