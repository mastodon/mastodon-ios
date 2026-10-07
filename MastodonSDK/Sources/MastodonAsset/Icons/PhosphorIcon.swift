//
//  PhosphorIcon.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 9/24/26.
//
// This file uses Phosphor icons (https://phosphoricons.com), converted to .symbolsets and added to our Assets.xcassets in the Phosphor folder. Names match Phosphor at the time of conversion, except that "-fill" versions follow Apple's ".fill" convention so that standard system components can find them (such as for TabBar in compact width).
// Note: The filled version of arrowsClockwise is our own design, for stronger visual emphasis.
// Phosphor icons are used under the MIT license:
//                        
// Copyright (c) 2023 Phosphor Icons
//                     
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//                        
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//                     
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import SwiftUI

public enum PhosphorIcon: String, CaseIterable, Sendable {
    case arrowsClockwise = "arrows-clockwise" // the filled version of arrowsClockwise is our own design, for stronger visual emphasis
    case bell
    case bookmarkSimple = "bookmark-simple"
    case chatCircle = "chat-circle"
    case chatCircleDots = "chat-circle-dots"
    case circlesFour = "circles-four"
    case dotsThree = "dots-three"
    case gear
    case heart
    case house
    case list
    case magnifyingGlass = "magnifying-glass"
    case penNib = "pen-nib"
    case penNibLight = "pen-nib-light"
    case prohibit
    case rssSimple = "rss-simple"
    case signOut = "sign-out"
    case slidersHorizontal = "sliders-horizontal"
    case user
    case userPlus = "user-plus"
    case usersFour = "users-four"
    case usersThree = "users-three"
    
    var assetName: String { "Phosphor/\(rawValue)" }
}

public extension Image {
    init(phosphor icon: PhosphorIcon, filled: Bool = false) {
        if filled {
            self.init(icon.assetName + ".fill", bundle: MastodonAsset.bundle)
        } else {
            self.init(icon.assetName, bundle: MastodonAsset.bundle)
        }
    }
}
