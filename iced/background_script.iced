chrome.browserAction.onClicked.addListener ->
    chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
        chrome.tabs.sendMessage tabs[0].id, {action: "toggle_panel"}, (response) ->
            console.log "Got a response."

