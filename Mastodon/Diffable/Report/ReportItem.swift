//
//  ReportItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-27.
//

import Foundation
import CoreDataStack // needed until ReportStatusViewController is replaced
import MastodonSDK

enum ReportItem: Hashable, Sendable {
    case header(context: HeaderContext)
    case status(record: MastodonStatus)
    case comment(context: CommentContext)
    case bottomLoader
}

extension ReportItem {
    struct HeaderContext: Hashable {
        let primaryLabelText: String
        let secondaryLabelText: String
    }
    
    class CommentContext: Hashable {
        let id = UUID()
        @Published var comment: String = ""
        
        static func == (
            lhs: ReportItem.CommentContext,
            rhs: ReportItem.CommentContext
        ) -> Bool {
            lhs.comment == rhs.comment
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
