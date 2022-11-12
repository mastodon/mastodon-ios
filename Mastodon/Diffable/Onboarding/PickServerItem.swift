//
//  PickServerItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import Foundation
import Combine
import MastodonSDK

/// Note: update Equatable when change case
enum PickServerItem {
    case header
    case server(server: Mastodon.Entity.Server, attribute: ServerItemAttribute)
    case loader(attribute: LoaderItemAttribute)
}

extension PickServerItem {
    final class ServerItemAttribute: Equatable, Hashable {
        var isLast: CurrentValueSubject<Bool, Never>
        var isExpand: Bool
        
        init(isLast: Bool, isExpand: Bool) {
            self.isLast = CurrentValueSubject(isLast)
            self.isExpand = isExpand
        }
        
        static func == (lhs: PickServerItem.ServerItemAttribute, rhs: PickServerItem.ServerItemAttribute) -> Bool {
            return lhs.isExpand == rhs.isExpand
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isExpand)
        }
    }
    
    final class LoaderItemAttribute: Equatable, Hashable {
        let id = UUID()
        
        var isLast: Bool
        var isNoResult: Bool
        
        init(isLast: Bool, isEmptyResult: Bool) {
            self.isLast = isLast
            self.isNoResult = isEmptyResult
        }
        
        static func == (lhs: PickServerItem.LoaderItemAttribute, rhs: PickServerItem.LoaderItemAttribute) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension PickServerItem: Equatable {
    static func == (lhs: PickServerItem, rhs: PickServerItem) -> Bool {
        switch (lhs, rhs) {
        case (.header, .header):
            return true
        case (.server(let serverLeft, _), .server(let serverRight, _)):
            return serverLeft.domain == serverRight.domain
        case (.loader(let attributeLeft), loader(let attributeRight)):
            return attributeLeft == attributeRight
        default:
            return false
        }
    }
}

extension PickServerItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .header:
            hasher.combine(String(describing: PickServerItem.header.self))
        case .server(let server, _):
            hasher.combine(server.domain)
        case .loader(let attribute):
            hasher.combine(attribute)
        }
    }
}
