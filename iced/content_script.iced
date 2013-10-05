chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    console.log request
    if request.action is "open_panel"
        sendResponse {"response": "some text"}