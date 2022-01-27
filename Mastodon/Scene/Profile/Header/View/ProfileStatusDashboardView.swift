//
//  ProfileStatusDashboardView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import os.log
import UIKit
import MastodonAsset
import MastodonLocalization

protocol ProfileStatusDashboardViewDelegate: AnyObject {
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView, meter: ProfileStatusDashboardView.Meter)
}

final class ProfileStatusDashboardView: UIView {
    
    let postDashboardMeterView = ProfileStatusDashboardMeterView()
    let followingDashboardMeterView = ProfileStatusDashboardMeterView()
    let followersDashboardMeterView = ProfileStatusDashboardMeterView()
    
    weak var delegate: ProfileStatusDashboardViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileStatusDashboardView {
    enum Meter: Hashable {
        case post
        case following
        case follower
    }
}

extension ProfileStatusDashboardView {
    private func _init() {
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
            containerStackView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        let spacing: CGFloat = UIView.isZoomedMode ? 4 : 16
        containerStackView.spacing = spacing
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        containerStackView.alignment = .top
        containerStackView.addArrangedSubview(postDashboardMeterView)
        containerStackView.setCustomSpacing(spacing - 2, after: postDashboardMeterView)
        containerStackView.addArrangedSubview(followingDashboardMeterView)
        containerStackView.setCustomSpacing(spacing + 2, after: followingDashboardMeterView)
        containerStackView.addArrangedSubview(followersDashboardMeterView)
        
        postDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.posts
        followingDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.following
        followersDashboardMeterView.textLabel.text = L10n.Scene.Profile.Dashboard.followers
        
        [postDashboardMeterView, followingDashboardMeterView, followersDashboardMeterView].forEach { meterView in
            let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
            tapGestureRecognizer.addTarget(self, action: #selector(ProfileStatusDashboardView.tapGestureRecognizerHandler(_:)))
            meterView.addGestureRecognizer(tapGestureRecognizer)
        }
    }
}

extension ProfileStatusDashboardView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let sourceView = sender.view as? ProfileStatusDashboardMeterView else {
            assertionFailure()
            return
        }
        switch sourceView {
        case postDashboardMeterView:
            delegate?.profileStatusDashboardView(self, dashboardMeterViewDidPressed: sourceView, meter: .post)
        case followingDashboardMeterView:
            delegate?.profileStatusDashboardView(self, dashboardMeterViewDidPressed: sourceView, meter: .following)
        case followersDashboardMeterView:
            delegate?.profileStatusDashboardView(self, dashboardMeterViewDidPressed: sourceView, meter: .follower)
        default:
            assertionFailure()
        }
    }
}


#if DEBUG
import SwiftUI

struct ProfileBannerStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            ProfileStatusDashboardView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
}
#endif
