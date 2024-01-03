//
//  Task.swift
//  
//
//  Created by Jed Fox on 2022-12-23.
//

import Combine

extension Task {
    func store(in set: inout Set<AnyCancellable>) {
        set.insert(AnyCancellable(cancel))
    }
}
