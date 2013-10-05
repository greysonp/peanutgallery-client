content_script = --join js/content_script.js --runtime window --compile iced/content_script.iced  
background_script = --join js/background_script.js --runtime window --compile iced/background_script.iced  

stylus = stylus stylus/*.styl --out css/

default: 
	iced $(content_script)
	iced $(background_script)
	$(stylus)

watch:
	iced --watch $(content_script)
	iced --watch $(background_script)
	$(stylus) --watch