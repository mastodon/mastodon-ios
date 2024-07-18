//
//  IntentHandler.swift
//  MastodonIntent
//
//  Created by Cirno MainasuK on 2021-7-26.
//

import Intents
import MastodonCore

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        AuthenticationServiceProvider.shared.restore()

        switch intent {
        case is SendPostIntent:
            return SendPostIntentHandler()
        case is FollowersCountIntent:
            return FollowersCountIntentHandler()
        case is MultiFollowersCountIntent:
            return MultiFollowersCountIntentHandler()
        case is HashtagIntent:
            return HashtagIntentHandler()
        default:
            return self
        }
    }
    
}
