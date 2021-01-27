//
//  Query.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

protocol GetQuery {
    var queryItems: [URLQueryItem]? { get }
}

protocol PostQuery {
    var body: Data? { get }
}
