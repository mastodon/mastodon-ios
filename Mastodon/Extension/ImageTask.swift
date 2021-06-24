//
//  ImageTask.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-24.
//

import Foundation
import Nuke

extension ImageTask {
    func store(in set: inout Set<ImageTask?>) {
        set.insert(self)
    }
}
