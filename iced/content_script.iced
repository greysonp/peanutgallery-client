# =======================================================
# STATE VARIABLES
# =======================================================

STATE = {
    "MAIN_MENU": 0,
    "GROUP": 1,
    "INTERACT": 2,
    "LOG_IN": 3,
    "DRAWING": 4,
    "NEW": 5
}
_state = STATE.MAIN_MENU
_groups = {}
_group = {}
_pages = {}
_comments = {}
_user = {}
_loadingHtml = """
        <h1>PeanutGallery</h1>
        <h2>Loading...</h2>
    """

_lastPoint = null
POINT_INTERVAL = 2

ROOT_URL = "http://whispering-sierra-9270.herokuapp.com/"


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
        if _user.loggedIn
            fillMenuScreen data.id
        else
            fillLoginScreen()

        addPanelEvents()

# Closes the panel, then destroys the html fo the panel
closePanel = ->
    getPanel().animate {"left": "-300px"}, 250, () ->
        destroyPanelHtml()

constructBaseHtml = ->
    $('body').prepend "<div id='js-gifics-panel' class='gifics-panel'></div>"
    getPanel().html _loadingHtml


addPanelEvents = ->
    getPanel().mouseenter ->
        if _state is STATE.DRAWING
            getPanel().animate {"left":0}, 250
    getPanel().mouseleave ->
        if _state is STATE.DRAWING
            getPanel().animate {"left":"-285px"}, 250
    $('.gifics-textarea').css {"top": getPanel().scrollTop() - $('.gifics-textarea').height() + getPanel().height() - 10 + "px"}
    getPanel().scroll ->
        $('.gifics-textarea').css {"top": getPanel().scrollTop() - $('.gifics-textarea').height() + getPanel().height() - 10 + "px"}


# =======================================================
# SCREEN DRAWING
# =======================================================

fillLoginScreen = ->
    _state = STATE.LOGIN
    await $.get chrome.extension.getURL("html/login.html"), defer data
    getPanel().html data
    $('#js-login').click ->
        chrome.runtime.sendMessage {"action": "facebook_auth"}, (response) ->
            console.log "Got token: #{response.token}"
            createNewUser response.token, (id)->
                setUserData true, response.token, id
                console.log "Got id: #{id}"
                fillMenuScreen id

fillMenuScreen = (userId) ->
    _state = STATE.MAIN_MENU
    await $.get chrome.extension.getURL("html/main_menu.html"), defer data
    await getGroups userId, defer groups
    _groups = groups
    templatePanel data, _groups
    $('.gifics-groups li').each (index) ->
        $(this).click ->
            fillGroupScreen _groups.groups[index]
    $('#js-gifics-share').click ->
        fillShareScreen()

fillGroupScreen = (group) ->
    _state = STATE.GROUP
    getPanel().html _loadingHtml

    await getPages group.id, defer pages
    _pages = pages

    # Format dates
    for p in _pages.pages
        p.date = formatDate p.date
        # p.lastComment.date = formatDate p.lastComment.date

    _pages["groupName"] = group.name
    await $.get chrome.extension.getURL("html/groups.html"), defer data 
    templatePanel data, _pages

    # Click event
    $('.gifics-pages li').each (index) ->
        $(this).click ->
            window.location.href = _pages.pages[index].url

    # Back button
    $('.gifics-back').click ->
        fillMenuScreen _user.id


fillInteractScreen = (page) ->
    _state = STATE.INTERACT
    getPanel().html _loadingHtml

    # Should get data from server
    await getComments (page.id or page.pageId), defer comments
    _comments = comments

    # Format dates
    for c in _comments.comments
        c.date = formatDate c.date
    _comments["pageTitle"] = page.title

    await $.get chrome.extension.getURL("html/interact.html"), defer data
    templatePanel data, _comments

    # Add event for draw button
    $('#js-gifics-draw').click ->
        # Don't add a canvas if one exists
        if $('#js-gifics-canvas').length > 0
            exitDrawMode()
        else
            enterDrawMode page.id

    # Add event for submitting comment
    $('.gifics-textarea').keydown (e) ->
        if e.keyCode is 13
            date = new Date()
            submitComment _user.id, _group.id, formatDate(date.toString()), $('.gifics-textarea').val()
            $('.gifics-textarea').blur()

    # Back Button
    $('.gifics-back').click ->
        fillMenuScreen _user.id

    # Size the thread so it doesn't go below comment box
    tHeight = $('.gifics-textarea').height()

    $('.gifics-textarea').css {"top": getPanel().scrollTop() - $('.gifics-textarea').height() + getPanel().height() - 10 + "px"}

exitDrawMode = ->
    _state = STATE.INTERACT
    $('#js-gifics-draw').html """<i class="icon-pencil"></i> Draw"""
    $('#js-gifics-canvas').remove()
    getPanel().animate {"left": 0}, 250

enterDrawMode = (pageId) ->
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
        exportAndResetCanvas pageId

fillShareScreen = () ->
    _state = STATE.INTERACT
    getPanel().html _loadingHtml

    await $.get chrome.extension.getURL("html/share.html"), defer data
    templatePanel data, _groups

    $('.gifics-back').click ->
        fillMenuScreen _user.id

    $('#js-gifics-go').click ->
        index = $('#js-gifics-panel select')[0].selectedIndex
        await createPage _user.id, _groups.groups[index].id, window.location.href, $('title').text(), defer lame
        await getPageDetails _user.id, window.location.href, defer details
        fillInteractScreen details




# =======================================================
# REMOTE METHODS
# =======================================================

createNewUser = (token, callback) ->
    await $.get "#{ROOT_URL}?accessToken=#{token}", defer data
    console.log "Create new json: #{data}"
    json = JSON.parse data 
    callback json.id

getGroups = (userId, callback) ->
    await $.get "#{ROOT_URL}?getGroups=#{userId}", defer data
    console.log "Group json: #{data}"
    json = JSON.parse data 
    callback json

getPages = (groupId, callback) ->
    await $.get "#{ROOT_URL}?getPages=#{groupId}", defer data
    console.log "Page json: #{data}"
    json = JSON.parse data 
    callback json

getComments = (pageId, callback) ->
    await $.get "#{ROOT_URL}?getComments=#{pageId}", defer data
    console.log "#{ROOT_URL}?getComments=#{pageId}"
    console.log "Comment json: #{data}"
    json = JSON.parse data 
    callback json

getPageDetails = (userId, url, callback) ->
    await $.get "#{ROOT_URL}?userId=#{userId}&url=#{url}", defer data
    console.log "Comment json: #{data}"
    json = JSON.parse data 
    callback json

submitComment = (userId, groupId, date, body) ->
    console.log "Submitted Comment!"
    await $.get "#{ROOT_URL}?body=#{body}&userId=#{userId}&groupId=#{groupId}&date=#{date}&url=#{window.location.href}" , defer data
    console.log "#{ROOT_URL}?body=#{body}&userId=#{userId}&groupId=#{groupId}&date=#{date}&url=#{window.location.href}"
    window.location.reload true

createPage = (userId, groupId, url, title, callback) ->
    await $.get "#{ROOT_URL}?userId=#{userId}&groupId=#{groupId}&url=#{url}&title=#{title}", defer data
    console.log "Comment json: #{data}"
    json = JSON.parse data 
    callback json

exportAndResetCanvas = (pageId) ->
    img = $('#js-gifics-canvas')[0].toDataURL "image/png"
    saveImage pageId, img, $(window).scrollTop()
    $('body').append "<img src='#{img}' class='gifics-doodle' style='top:#{$(window).scrollTop()}px' />"
    clearCanvas $('#js-gifics-canvas')[0]

saveImage = (pageId, img, offsetTop) ->
    console.log "Making request."
    $.post "http://whispersinthebreeze.com/images.php", {
            "pageId": pageId, 
            "imageData": img,
            "offsetTop": offsetTop 
        }, (data) ->
            console.log data



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
    console.log data
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

clearCanvas = (canvas) ->
    ctx = canvas.getContext "2d"
    ctx.clearRect 0, 0, canvas.width, canvas.height

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


# =======================================================
# INITIAL PAGE CHECK
# =======================================================

await getUserData defer data
if data.loggedIn
    _user = data
    console.log "Initial load, storage: #{data.id}"
    getPageDetails _user.id, window.location.href, (details) ->
        console.log details
        if details.pageId isnt null
            _group = { "id": details.groupId }
            constructBaseHtml()
            addPanelEvents()
            getPanel().animate {"left": "0"}, 250
            fillInteractScreen details
