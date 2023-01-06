//
//  Action.js
//  FollowActionExtension
//
//  Created by Marcus Kida on 03.01.23.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        var username = document.documentURI.match("@(.+)@([a-z0-9]+\.[a-z0-9]+)")[0];
        
        if (!username) {
            username = document.head.querySelector('[property="profile:username"]').content
        }

        console.log("username" + username)
        
        arguments.completionFunction({ "username" : username })
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
    
var ExtensionPreprocessingJS = new Action
