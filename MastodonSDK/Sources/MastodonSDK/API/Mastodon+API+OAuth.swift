//
//  Mastodon+API+OAuth.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.API.OAuth {

    public static let authorizationField = "Authorization"

    public struct Authorization {
        public let accessToken: String
    }

}
