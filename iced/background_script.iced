chrome.browserAction.onClicked.addListener ->
    chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
        chrome.tabs.sendMessage tabs[0].id, {action: "toggle_panel"}, (response) ->
            console.log "Got a response."


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    console.log "Receiving a message"
    if request.action is "facebook_auth"
        chrome.tabs.query {"active":true, "currentWindow":true}, (tabs) ->
            chrome.tabs.create {
                "url": "https://www.facebook.com/dialog/oauth?client_id=394922043969304&redirect_uri=http://whispering-sierra-9270.herokuapp.com/grey.php&scope=user_groups,friends_groups"
            }, null
        
            currTab = tabs[0]
            listener = () ->
                chrome.tabs.getAllInWindow null, (tabs) ->
                    for t in tabs
                        if t.url.indexOf("http://whispering-sierra-9270.herokuapp.com/grey.php?access_token") is 0
                            token = t.url.substring (t.url.indexOf("=") + 1)
                            chrome.tabs.onUpdated.removeListener listener
                            sendResponse {"token": token}
                            chrome.tabs.remove(t.id);
                            chrome.tabs.update currTab.id, {"active": true}
                            return
            chrome.tabs.onUpdated.addListener listener
        return true
    return false
        