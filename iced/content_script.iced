# =======================================================
# BACKGROUND INTE
# =======================================================

# Listens for button click
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    console.log request
    if request.action is "toggle_panel"
        if isPanelOpen()
            closePanel()
        else
            openPanel()

# =======================================================
# OPEN/CLOSE
# =======================================================

# Constructs the base html of the panel, then shows it
openPanel = () ->
    if $('#js-gifics-panel').length <= 0
        constructBaseHtml()
    getPanel().animate {"left": "0"}, 250, ()->
        fillMenuScreen()

# Closes the panel, then destroys the html fo the panel
closePanel = () ->
    getPanel().animate {"left": "-300px"}, 250, () ->
        destroyPanelHtml()

constructBaseHtml = () ->
    $('body').prepend """
        <div id="js-gifics-panel" class="gifics-panel">
            {{info}}
        </div>
    """
    templatePanel getPanel().html(), {"info": "With great power comes great responsibility."}

# =======================================================
# DATE RETRIEVAL
# =======================================================

fillMenuScreen = () ->
    await $.get chrome.extension.getURL("html/main_menu.html"), defer data
    
    context = {
        "groups": [
            {
                "name": "Family",
                "newShares": 13
            },
            {   
                "name": "Sinister Six",
                "newShares": 6
            }
        ]
    }
    templatePanel data, context

fillGroupSelect = () ->
    return

# =======================================================
# LOCAL STORAGE
# =======================================================

setLoggedIn = (isLoggedIn, token = undefined) ->
    chrome.storage.local.put {
        "user": {
            "loggedIn": isLoggedIn,
            "token": token
        }
    }

# =======================================================
# MISCELLANEOUS
# =======================================================

# Templates the panel with the given context
templatePanel = (sourceHtml, context) ->
    template = Handlebars.compile(sourceHtml);
    compiledHtml = template context
    getPanel().html compiledHtml

# True if panel is open, otherwise false
isPanelOpen = () ->
    return $('#js-gifics-panel').length > 0

# Gets rid of the panel
destroyPanelHtml = () ->
    $('#js-gifics-panel').remove()

# Retrievs jQuery object of panel
getPanel = () ->
    return $('#js-gifics-panel')