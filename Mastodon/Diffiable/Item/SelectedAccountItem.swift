//
//  SelectedAccountItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/22.
//

import Foundation
import CoreData

enum SelectedAccountItem {
    case accountObjectID(accountObjectID: NSManagedObjectID)
    case placeHolder(uuid: UUID)
}

extension SelectedAccountItem: Equatable {
    static func == (lhs: SelectedAccountItem, rhs: SelectedAccountItem) -> Bool {
        switch (lhs, rhs) {
        case (.accountObjectID(let idLeft), .accountObjectID(let idRight)):
            return idLeft == idRight
        case (.placeHolder(let uuidLeft), .placeHolder(let uuidRight)):
            return uuidLeft == uuidRight
        default:
            return false
        }
    }
}

extension SelectedAccountItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .accountObjectID(let id):
            hasher.combine(id)
        case .placeHolder(let id):
            hasher.combine(id.uuidString)
        }
    }
}
