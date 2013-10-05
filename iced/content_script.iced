# =======================================================
# STATE VARIABLES
# =======================================================

STATE = {
    "MAIN_MENU": 0,
    "GROUP": 1,
    "INTERACT": 2,
    "LOG_IN": 3
}
_state = STATE.MAIN_MENU
_groups = {}
_pages = {}
_comments = {}

_loadingHtml = """
        <h1>HieroGIFics</h1>
        <h2>Loading...</h2>
    """

# =======================================================
# BACKGROUND INTERACTION
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
    $('body').prepend "<div id='js-gifics-panel' class='gifics-panel'></div>"
    getPanel().html _loadingHtml

# =======================================================
# DATE RETRIEVAL
# =======================================================

fillMenuScreen = () ->
    _state = STATE.MAIN_MENU
    await $.get chrome.extension.getURL("html/main_menu.html"), defer data
    _groups = {
        "groups": [
            {
                "id": 1
                "name": "Spidey-Friends",
                "newShares": 2
            },
            {   
                "id": 2
                "name": "Sinister Six",
                "newShares": 6
            }
        ]
    }
    templatePanel data, _groups
    $('.gifics-groups li').each (index) ->
        $(this).click ->
            fillGroupScreen _groups.groups[index]

fillGroupScreen = (group) ->
    _state = STATE.GROUP
    getPanel().html _loadingHtml

    _pages = {
        "pages": [
            {
                "id": 1,
                "title": "Spider-Man Wiki",
                "url": "http://en.wikipedia.org/wiki/Spider-man",
                "date": new Date(),
                "numComments": 3,
                "lastComment": {
                    "body": "You're dumb.",
                    "date": new Date()
                },
                "author": {
                    "id": 1,
                    "firstName": "Greyson",
                    "lastName": "Parrelli"
                }
            },
            {
                "id": 2,
                "title": "Venom Wiki",
                "url": "http://en.wikipedia.org/wiki/Venom",
                "date": new Date(),
                "numComments": 2,
                "lastComment": {
                    "body": "You're dumb.",
                    "date": new Date()
                },
                "author": {
                    "id": 2,
                    "firstName": "Michael",
                    "lastName": "Toth"
                }
            }
        ]   
    }
    _pages["groupName"] = group.name
    await $.get chrome.extension.getURL("html/groups.html"), defer data 
    templatePanel data, _pages


fillInteractScreen = (pageId) ->
    _state = STATE.INTERACT
    getPanel().html _loadingHtml

    # Should get data from server
    _comments = {
        "comments": [
            {
                "id": 1,
                "author": {
                    "id": 1
                    "firstName": "Greyson",
                    "lastName": "Parrelli",
                },
                "date": new Date(),
                "body": "This site so cool.",
                "likes": 2
            },
            {
                "id": 2,
                "author": {
                    "id": 2
                    "firstName": "Michael",
                    "lastName": "Toth",
                },
                "date": new Date(),
                "body": "No it isn't.",
                "likes": 1
            },
            {
                "id": 3,
                "author": {
                    "id": 1
                    "firstName": "Greyson",
                    "lastName": "Parrelli",
                },
                "date": new Date(),
                "body": "Yes it is.",
                "likes": 3
            }
        ]
    }

    await $.get chrome.extension.getURL("html/main_menu.html"), defer data




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

embedFonts = () ->
    # Normal
    normalNode = document.createElement ("style");
    normalNode.type = "text/css"
    url = chrome.extension.getURL "css/fonts/Raleway-Regular.ttf"
    normalNode.textContent = "@font-face { font-family: 'Raleway-Regular'; src: url('#{url}'); }"
    document.head.appendChild normalNode
embedFonts()


