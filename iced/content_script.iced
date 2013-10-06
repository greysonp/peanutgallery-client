# =======================================================
# STATE VARIABLES
# =======================================================

STATE = {
    "MAIN_MENU": 0,
    "GROUP": 1,
    "INTERACT": 2,
    "LOG_IN": 3,
    "DRAWING": 4
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
_doodles = []

_lastPoint = null
POINT_INTERVAL = 2

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

        getPanel().mouseenter ->
            if _state is STATE.DRAWING
                getPanel().animate {"left":0}, 250
        getPanel().mouseleave ->
            if _state is STATE.DRAWING
                getPanel().animate {"left":"-285px"}, 250

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
        # Don't add a canvas if one exists
        if $('#js-gifics-canvas').length > 0
            exitDrawMode()
        else
            enterDrawMode()

exitDrawMode = ->
    _state = STATE.INTERACT
    $('#js-gifics-draw').html """<i class="icon-pencil"></i> Draw"""
    getPanel().animate {"left": 0}, 250

enterDrawMode = ->
    _state = STATE.DRAWING

    $('#js-gifics-draw').html """<i class="icon-ban-circle"></i> Stop"""

    $('body').prepend """
        <canvas id="js-gifics-canvas" class="gifics-canvas"></canvas>
    """

    # Animate the panel to hide mode
    getPanel().animate {"left": "-285px"}, 250

    # =================
    # DRAWING STUFF
    # =================
    canvas = $('#js-gifics-canvas')[0]
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    ctx = canvas.getContext "2d"

    # define a custom fillCircle method
    ctx.fillCircle = (x, y, radius, fillColor) ->
        this.fillStyle = fillColor
        this.beginPath()
        this.moveTo x, y
        this.arc x, y, radius, 0, Math.PI * 2, false
        this.fill()

    clearCanvas canvas

    # bind mouse events
    canvas.onmousemove = (e) ->
        if not canvas.isDrawing
           return
        
        x = e.pageX - $(document).scrollLeft()
        y = e.pageY - $(document).scrollTop()
        radius = 5
        color = "#cc0000"
        ctx.fillCircle x, y, radius, color
        if _lastPoint isnt null
            dx = x - _lastPoint[0]
            dy = y - _lastPoint[1]
            dist = Math.sqrt(dx * dx + dy * dy)
            rad = Math.atan2 dy, dx
            sx = Math.cos(rad) * POINT_INTERVAL
            sy = Math.sin(rad) * POINT_INTERVAL
            for i in [1..dist/POINT_INTERVAL]
                ctx.fillCircle(_lastPoint[0] + (sx * i), _lastPoint[1] + (sy * i), radius, color)

        _lastPoint = [x, y]

    canvas.onmousedown = (e) ->
        canvas.isDrawing = true

    canvas.onmouseup = (e) ->
        canvas.isDrawing = false
        _lastPoint = null
        exportAndResetCanvas()


# =======================================================
# REMOTE METHODS
# =======================================================

createNewUser = (token, callback) ->
    # DO STUFF HERE
    # callback {"id": 1}
    callback 1

exportAndResetCanvas = ->
    img = $('#js-gifics-canvas')[0].toDataURL "image/png"
    _doodles.push {
        "src": img,
        "top": $(window).scrollTop()
    }
    $('body').append "<img src='#{img}' class='gifics-doodle' style='top:#{$(window).scrollTop()}px' />"
    clearCanvas $('#js-gifics-canvas')[0]

clearCanvas = (canvas) ->
    ctx = canvas.getContext "2d"
    ctx.clearRect 0, 0, canvas.width, canvas.height

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