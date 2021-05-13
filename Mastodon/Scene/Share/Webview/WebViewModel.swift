//
//  WebViewModel.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/30.
//

import Foundation

final class WebViewModel {
    public init(url: URL) {
        self.url = url
    }

    // input
    let url: URL
}
