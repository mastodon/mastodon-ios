//
//  Action.js
//  OpenInActionExtension
//
//  Created by Marcus Kida on 03.01.23.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        
        var username = detectUsername()
        
        if (username) {
            arguments.completionFunction({ "username" : username })
        }
    
    },
    
    finalize: function(arguments) {

        var openURL = arguments["openURL"]
        var error = arguments["error"]
        
        if (error) {
            alert(error)
        } else if (openURL) {
            window.location = openURL
        }
    }
    
};

function detectUsername() {
    var uriUsername = document.documentURI.match("@(.+)@([a-z0-9]+\.[a-z0-9]+)")
    
    if (typeof uriUsername === "Array") {
        return uriUsername[0]
    }

    return document.head.querySelector('[property="profile:username"]').content
}

function detectPost() {
    
}
    
var ExtensionPreprocessingJS = new Action
