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
_user = {}
_loadingHtml = """
        <h1>HieroGIFics</h1>
        <h2>Loading...</h2>
    """

# =======================================================
# BACKGROUND INTERACTION
# =======================================================

# Listens for button click
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
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
        await getUserData defer data
        if data.loggedIn
            _user = data
            # getPageInfo data.userId, window.location.href
            fillMenuScreen data.userId
        else
            fillLoginScreen()

# Closes the panel, then destroys the html fo the panel
closePanel = () ->
    getPanel().animate {"left": "-300px"}, 250, () ->
        destroyPanelHtml()

constructBaseHtml = () ->
    $('body').prepend "<div id='js-gifics-panel' class='gifics-panel'></div>"
    getPanel().html _loadingHtml

# =======================================================
# SCREEN DRAWING
# =======================================================

fillLoginScreen = ->
    _state = STATE.LOGIN
    await $.get chrome.extension.getURL("html/login.html"), defer data
    getPanel().html data
    $('#js-login').click ->
        chrome.runtime.sendMessage {"action": "facebook_auth"}, (response) ->
            console.log "Got token:" + response.token
            createNewUser response.token, (id)->
                setUserData true, response.token, id
                fillMenuScreen id

fillMenuScreen = (userId) ->
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
                    "body": "I don't like this.",
                    "date": new Date(),
                    "author": {
                        "id": 2,
                        "firstName": "Michael",
                        "lastName": "Toth"
                    }
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
                    "date": new Date(),
                    "author": {
                        "id": 1,
                        "firstName": "Greyson",
                        "lastName": "Parrelli"
                    }
                },
                "author": {
                    "id": 2,
                    "firstName": "Michael",
                    "lastName": "Toth"
                }
            }
        ]   
    }
    # Format dates
    for p in _pages.pages
        p.date = formatDate p.date
        p.lastComment.date = formatDate p.lastComment.date

    _pages["groupName"] = group.name
    await $.get chrome.extension.getURL("html/groups.html"), defer data 
    templatePanel data, _pages

    $('.gifics-pages li').each (index) ->
        $(this).click ->
            fillInteractScreen _pages.pages[index]


fillInteractScreen = (page) ->
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
    # Format dates
    for c in _comments.comments
        c.date = formatDate c.date
    _comments["pageTitle"] = page.title

    await $.get chrome.extension.getURL("html/interact.html"), defer data
    templatePanel data, _comments

    #Add event for draw button
    $('#js-gifics-draw').click ->
        enterDrawMode()

enterDrawMode = ->
    $('body').prepend """
        <canvas id="js-gifics-canvas" class="gifics-canvas"></canvas>
    """

# =======================================================
# REMOTE METHODS
# =======================================================

createNewUser = (token, callback) ->
    # DO STUFF HERE
    # callback {"id": 1}
    callback 1

# =======================================================
# LOCAL STORAGE
# =======================================================

setUserData = (isLoggedIn, token, userId) ->
    chrome.storage.local.set {
        "user": {
            "id": userId,
            "loggedIn": isLoggedIn,
            "token": token
        }
    }

getUserData = (callback) ->
    await chrome.storage.local.get "user", defer data
    if Object.keys(data).length <= 0
        callback {"loggedIn": false}
    else
        callback data.user

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
    embedFont "Raleway-Regular", "css/fonts/Raleway-Regular.ttf"
    embedFont "Raleway-Bold", "css/fonts/Raleway-Bold.ttf"
    embedFont "FontAwesome", "css/fonts/fontawesome-webfont.ttf"

embedFont = (name, path) ->
    node = document.createElement ("style");
    node.type = "text/css"
    url = chrome.extension.getURL path
    node.textContent = "@font-face { font-family: '#{name}'; src: url('#{url}'); }"
    document.head.appendChild node
embedFonts()

formatDate = (dateString) ->
    date = new Date(dateString)
    # dotw = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    # months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

    # dotwString = dotw[date.getDay()]
    # monthString = months[date.getMonth()]
    # dateString = date.getDate()
    # yearString = date.getFullYear()

    # return dotwString + ', ' + monthString + ' ' + dateString + ', ' + yearString; 
    return "#{date.getMonth()}/#{date.getDay()}/#{date.getFullYear()}"

formatTime = (dateString) ->
    date = new Date(dateString)
    isAM = true
    hours = date.getHours()
    if hours > 12
        isAM = false
        hours -= 12
    
    minutes = date.getMinutes()
    if minutes.toString().length < 2
        minutes = '0' + minutes

    if isAM
        return "#{hours}:#{minutes} AM"
    else
        return "#{hours}:#{minutes} PM"