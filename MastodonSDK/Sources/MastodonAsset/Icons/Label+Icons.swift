//
//  Label+Icons.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 9/25/26.
//

import SwiftUI

public extension Label where Title == Text, Icon == Image {
    init(_ title: String, icon: Image) {
        self.init {
            Text(title)
        } icon: {
            icon
        }
    }
    
    init(_ title: String, phosphor phosphorIcon: PhosphorIcon, filled: Bool = false) {
        self.init(title, icon: Image(phosphor: phosphorIcon, filled: filled))
    }
}
