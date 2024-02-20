//
//  PollOptionTextViewModel.swift
//  Mastodon
//
//  Created by Natalia Ossipova on 2023-01-13.
//

import UIKit
import MastodonAsset

public final class PollOptionTextViewModel: ObservableObject {

    let isLeftToRight = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight

    @Published public var text: String
    @Published public var textColor: UIColor

    init(text: String = "", textColor: UIColor = Asset.Colors.Label.primary.color) {
        self.text = text
        self.textColor = textColor
    }
}
