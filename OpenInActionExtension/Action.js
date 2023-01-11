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
        let alertMessage = arguments["alert"]
        if (alertMessage) {
            alert(alertMessage)
        } else {
            window.location = arguments["openURL"]
        }
    }
    
};

function detectUsername() {
    var uriUsername = document.documentURI.match("@(.+)@([a-z0-9]+\.[a-z0-9]+)")
    
    if (Array.isArray(uriUsername)) {
        return uriUsername[0]
    }
    
    var querySelector = document.head.querySelector('[property="profile:username"]')
    if (querySelector !== null && typeof querySelector === "object") {
        return querySelector.content
    }

    return undefined
}

var ExtensionPreprocessingJS = new Action
