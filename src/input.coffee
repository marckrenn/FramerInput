Events.EnterKey = "EnterKey"
Events.SpaceKey = "SpaceKey"
Events.BackspaceKey = "BackspaceKey"
Events.CapsLockKey = "CapsLockKey"
Events.ShiftKey = "ShiftKey"
Events.ValueChange = "ValueChange"
Events.InputFocus = "InputFocus"
Events.InputBlur = "InputBlur"

class exports.InputLayer extends TextLayer

	constructor: (options={}) ->

		_.defaults options,
			backgroundColor: "#FFF"
			width: 375
			height: 60
			padding:
				left: 20
			text: "Type something..."
			fontSize: if Utils.isDesktop() then 40 / Utils.devicePixelRatio() else 40
			fontWeight: 300

		@_inputElement = document.createElement("input")
		@_inputElement.autocomplete = "off"
		@_inputElement.autocorrect = "off"
		@_inputElement.spellcheck = false

		super options

		# Globals
		@_background = undefined
		@_placeholder = undefined

		# Layer containing input element
		@input = new Layer
			backgroundColor: "transparent"
			name: "input"
			width: @width
			height: @height
			parent: @

		if @multiLine
			@_inputElement = document.createElement("textarea")

			# Add top padding to multi-line text area inputs
			@padding.top = 20

		# @on "change:width", =>
		# 	@_inputElement.style.width = "#{@input.width}px}"

		@on "change:padding", =>
			@_inputElement.style.paddingTop = "#{@padding.top}px"
			@_inputElement.style.paddingRight = "#{@padding.bottom}px"
			@_inputElement.style.paddingBottom = "#{@padding.right}px"
			@_inputElement.style.paddingLeft = "#{@padding.left}px"

		# Append element
		@input._element.appendChild(@_inputElement)

		# Match TextLayer defaults and type properties
		@_setTextProperties(@)

		# The id serves to differentiate multiple input elements from one another.
		# To allow styling the placeholder colors of seperate elements.
		@_inputElement.className = "input" + @id

		# All inherited properties
		textProperties =
			{@text, @fontFamily, @fontSize, @lineHeight, @fontWeight, @color, @backgroundColor, @width, @height}

		for property, value of textProperties

			@on "change:#{property}", (value) =>
				@_setTextProperties(@)
				@_setPlaceholderColor(@_id, @color)

				# Reset textLayer contents
				@_elementHTML.children[0].textContent = ""

		# Set default placeholder
		@_setPlaceholder(@text)
		@_setPlaceholderColor(@_id, @color)

		# Reset textLayer contents
		@_elementHTML.children[0].textContent = ""

		# Check if in focus
		@_isFocused = false

		# Default focus interaction
		@_inputElement.onfocus = (e) =>

			@focusColor ?= "#000"

			# Emit focus event
			@emit(Events.InputFocus, event)

			@_isFocused = true

		# Emit blur event
		@_inputElement.onblur = (e) =>
			@emit(Events.InputBlur, event)

			@_isFocused = false

		# To filter if value changed later
		currentValue = undefined

		# Store current value
		@_inputElement.onkeydown = (e) =>
			currentValue = @value

			# If caps lock key is pressed
			if e.which is 20
				@emit(Events.CapsLockKey, event)

			# If shift key is pressed
			if e.which is 16
				@emit(Events.ShiftKey, event)

		@_inputElement.onkeyup = (e) =>

			if currentValue isnt @value
				@emit("change:value", @value)
				@emit(Events.ValueChange, @value)

			# If enter key is pressed
			if e.which is 13
				@emit(Events.EnterKey, event)

			# If backspace key is pressed
			if e.which is 8
				@emit(Events.BackspaceKey, event)

			# If space key is pressed
			if e.which is 32
				@emit(Events.SpaceKey, event)

	_setPlaceholder: (text) =>
		@_inputElement.placeholder = text

	_setPlaceholderColor: (id, color) ->
		document.styleSheets[0].addRule(".input#{id}::-webkit-input-placeholder", "color: #{color}")

	_setTextProperties: (layer) =>

		if Utils.isDesktop()
			dpr = Utils.devicePixelRatio()
		else
			dpr = 1

		@_inputElement.style.fontFamily = layer.fontFamily
		@_inputElement.style.fontSize = "#{layer.fontSize / dpr}px"

		@_inputElement.style.fontWeight = layer.fontWeight ? "normal"
		@_inputElement.style.outline = "none"
		@_inputElement.style.backgroundColor = "transparent"
		@_inputElement.style.width = "#{((layer.width - layer.padding.left * 2) * 2 / dpr)}px"
		@_inputElement.style.height = "#{layer.height * 2 / dpr}px"
		@_inputElement.style.cursor = "auto"
		@_inputElement.style.webkitAppearance = "none"
		@_inputElement.style.resize = "none"
		@_inputElement.style.paddingTop = "#{layer.padding.top * 2 / dpr}px"
		@_inputElement.style.paddingRight = "#{layer.padding.bottom * 2 / dpr}px"
		@_inputElement.style.paddingBottom = "#{layer.padding.right * 2 / dpr}px"
		@_inputElement.style.paddingLeft = "#{layer.padding.left * 2 / dpr}px"
		@_inputElement.style.overflow = "hidden"

	addBackgroundLayer: (layer) ->
		@_background = layer
		@_background.parent = @
		@_background.name = "background"
		@_background.x = @_background.y = 0
		@_background._element.appendChild(@_inputElement)

		return @_background

	addPlaceHolderLayer: (layer) ->
		@_inputElement.className = "input" + layer.id

		@_setPlaceholder(layer.text)
		@_setTextProperties(layer)
		@_setPlaceholderColor(layer.id, layer.color)

		# Remove original layer
		layer.visible = false

		# Convert position to padding
		@_inputElement.style.fontSize = "#{layer.fontSize * 2 / Utils.devicePixelRatio()}px"
		@_inputElement.style.paddingTop = "#{layer.y * 2 / Utils.devicePixelRatio()}px"
		@_inputElement.style.paddingLeft = "#{layer.x * 2 / Utils.devicePixelRatio()}px"
		@_inputElement.style.width = "#{((@_background.width) - layer.x * 2) * 2 / Utils.devicePixelRatio()}px"

		return @_placeholder

	focus: ->
		@_inputElement.focus()

	@define "value",
		get: -> @_inputElement.value
		set: (value) ->
			@_inputElement.value = value

	@define "focusColor",
		get: ->
			@_inputElement.style.color
		set: (value) ->
			@_inputElement.style.color = value

	@define "multiLine", @simpleProperty("multiLine", false)

	# New Constructor
	@wrap = (background, placeholder, options) ->
		return wrapInput(new @(options), background, placeholder, options)

	onEnterKey: (cb) -> @on(Events.EnterKey, cb)
	onSpaceKey: (cb) -> @on(Events.SpaceKey, cb)
	onBackspaceKey: (cb) -> @on(Events.BackspaceKey, cb)
	onCapsLockKey: (cb) -> @on(Events.CapsLockKey, cb)
	onShiftKey: (cb) -> @on(Events.ShiftKey, cb)
	onValueChange: (cb) -> @on(Events.ValueChange, cb)
	onInputFocus: (cb) -> @on(Events.InputFocus, cb)
	onInputBlur: (cb) -> @on(Events.InputBlur, cb)

wrapInput = (instance, background, placeholder) ->

	if not (background instanceof Layer)
		throw new Error("InputLayer expects a background layer.")

	if not (placeholder instanceof TextLayer)
		throw new Error("InputLayer expects a text layer.")

	input = instance

	input.frame = background.frame
	input.parent = background.parent
	input.index = background.index

	input.addBackgroundLayer(background)
	input.addPlaceHolderLayer(placeholder)


	return input