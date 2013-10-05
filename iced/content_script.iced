chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    console.log request
    if request.action is "open_panel"
        openPanel()

openPanel = () ->
    constructHtml()

constructHtml = () ->
    $('body').prepend """
        <div id="js-gifics-panel" class="gifics-panel">
            {{info}}
        </div>
    """
    fillData()

fillData = () ->
    source   = $('#js-gifics-panel').html();
    template = Handlebars.compile(source);
    context = {"info": "Hello, world!"}
    html = template context
    $('#js-gifics-panel').html html
    console.log html

destroyHtml = () ->
