//
//  MetaTextView+PasteExtensions.swift
//  Mastodon
//
//  Created by Rick Kerkhof on 30/10/2022.
//

import Foundation
import MetaTextKit
import UIKit

extension MetaTextView {
    public override func paste(_ sender: Any?) {
        super.paste(sender)
        
        // fix #660
        // https://github.com/mastodon/mastodon-ios/issues/660
        if #available(iOS 15.0, *) {
            var nextResponder = self.next;
            
            // Force the event to bubble through ALL responders
            // This is a workaround as somewhere down the chain the paste event gets eaten
            while (nextResponder != nil) {
                if let nextResponder = nextResponder {
                    if (nextResponder.responds(to: #selector(UIResponderStandardEditActions.paste(_:)))) {
                        nextResponder.perform(#selector(UIResponderStandardEditActions.paste(_:)), with: sender)
                    }
                }
                nextResponder = nextResponder?.next;
            }
        }   // end if
    }
}
