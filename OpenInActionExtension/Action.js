//
//  Action.js
//  OpenInActionExtension
//
//  Created by Marcus Kida on 03.01.23.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        var payload = {
            "username": detectUsername(),
            "url": document.documentURI
        }

        arguments.completionFunction(payload)
    },
    
    finalize: function(arguments) {
        window.location = arguments["openURL"]
    }
    
};

function detectUsername() {
    var uriUsername = document.documentURI.match("@(.+)@([a-z0-9]+\.[a-z0-9]+)")
    
    if (typeof uriUsername === "Array") {
        return uriUsername[0]
    }
    
    var querySelector = document.head.querySelector('[property="profile:username"]')
    if (typeof querySelector === "Object") {
        return querySelector.content
    }

    return undefined
}

var ExtensionPreprocessingJS = new Action
