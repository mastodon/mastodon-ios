//
//  DisposeBagCollectable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import Foundation
import Combine

protocol DisposeBagCollectable: class {
    var disposeBag: Set<AnyCancellable> { get set }
}
