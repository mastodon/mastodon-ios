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
            "url": document.documentURI
        }

        arguments.completionFunction(payload)
    },
    finalize: function(arguments) {
        const alertMessage = arguments["alert"]
        const openURL = arguments["openURL"]
        
        if (alertMessage) {
            alert(alertMessage)
        } else if (openURL) {
            window.location = openURL
        }
    }
};

var ExtensionPreprocessingJS = new Action
