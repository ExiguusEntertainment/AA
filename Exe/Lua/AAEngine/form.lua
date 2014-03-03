------------------------------------------------------------------------------
-- Groups of User Interface components come together into a single Form.
--


Form = {}
Form_mt = { __index = Form }

-- Global list of forms
G_forms = {}

local G_numButtons = 0;
local G_numTextBoxes = 0;
local wasGamma = false;

-- Handle processing of each form in the system
function G_forms.foreach(func)
	for i=1, #G_forms do
		func(G_forms[i])
	end
end

-- Walk all forms and all objects in the forms
function G_forms.forall(func)
	-- Walk all the forms
	G_forms.foreach(function (form) 
		form:foreach( function (form, obj)
			func(form, obj)
		end) 
	end)
end

-- Walk all the objects within a form
function Form:foreach(func)
	for i=1,#self.objects do
		func(self, self.objects[i])
	end
end

-- Global event to handle any button event going to a form
function _buttonHandleEvent(buttonID, event)
	G_forms.forall(function (form, obj)
		-- Do we have a button and matching buttonID?
		if ((obj.type == "button") and (obj.buttonID == buttonID)) then
			if (event == "press") then
				obj.press(buttonID, event)
			elseif (event == "release") then
				obj.release(buttonID, event)
			end
		end
	end)
end

-- Global event to handle any textbox event going to a form
function _textboxHandleEvent(textboxID, event)
	G_forms.forall(function (form, obj)
		-- Do we have a textbox and matching textboxID?
		if ((obj.type == "textbox") and (obj.textboxID == textboxID)) then
			obj.callback(form, obj, event)
		end
	end)
end

-- Create a new form (which is basically a collection of UI widgets)
Form.create = function(eventHandler)
print("Form.create")
print(inspect(eventHandler));
	local new_instance = {
		objects = {},
		eventHandler = eventHandler
	}
	setmetatable(new_instance, Form_mt);
	
	-- Add form to the list of forms
	G_forms[1+#G_forms] = new_instance;
	
	return new_instance;
end

-- Add to this form a new graphic
function Form:addGraphic(args)
	if (args.x == nil) then args.x = 0 end
	if (args.y == nil) then args.y = 0 end
	local graphicID = graphic.create(args.x, args.y, args.picName);
	local obj = { 
		type="graphic", 
		id=args.id, 
		x=args.x, y=args.y, 
		picName = args.picName, 
		graphicID = graphicID
	}
	self.objects[1+#self.objects] = obj
	return obj
end

-- One of the buttons on this form has been pressed
function Form:HandleButton(buttonID, event)
	-- TODO:
	print("HandleButton event " .. event)
	print(buttonID)
	print(self)
	if (self.eventHandler) then
		local buttonObj;
		self:foreach(function(form, obj) 
			if (obj.buttonID == buttonID) then 
				buttonObj = obj
			end;
		end)
		if (buttonObj) then
			self:eventHandler(event, buttonObj, buttonObj.id)
		end
	end
end

-- Add a button to this form
function Form:addButton(args)
	if (args.scankey1 == nil) then args.scankey1 = keyboard.scankeys.KEY_SCAN_CODE_NONE end
	if (args.scankey2 == nil) then args.scankey2 = keyboard.scankeys.KEY_SCAN_CODE_NONE end
	if (args.x == nil) then args.x = 0 end
	if (args.y == nil) then args.y = 0 end
	local funcDown = function(buttonID) Form.HandleButton(self, buttonID, "press") end
	local funcUp = function(buttonID) Form.HandleButton(self, buttonID, "release") end
	local buttonID = button.create(args.x, args.y, args.picName, args.toggleType, args.scankey1, args.scankey2)
	G_numButtons = G_numButtons+1;
	self.objects[1+#self.objects] = { 
		type="button", 
		id=args.id, 
		x=args.x, y=args.y, 
		picName = args.picName,
		toggleType = toggleType,
		press = funcDown,
		release = funcUp,
		buttonID = buttonID};
end

-- Handle a textbox event on this form
function Form:HandleTextbox(textboxObj, event)
	if (self.eventHandler) then
		self:eventHandler(event, textboxObj, textboxObj.id)
	end
end

-- Add a textbox to this form
function Form:addTextbox(args)
	-- Setup defaults
	if (args.scankey1 == nil) then args.scankey1 = keyboard.scankeys.KEY_SCAN_CODE_NONE end
	if (args.scankey2 == nil) then args.scankey2 = keyboard.scankeys.KEY_SCAN_CODE_NONE end
	if (args.x == nil) then args.x = 0 end
	if (args.y == nil) then args.y = 0 end
	if (args.width == nil) then args.width = 200 end
	if (args.height == nil) then args.height = 10 end
	if (args.length == nil) then args.length = -1 end
	if (args.filter == nil) then args.filter = "alpha" end
	if (args.justify == nil) then args.justify = "left" end
	if (args.font == nil) then args.font = "FontMedium" end
	if (args.upid == nil) then args.upid = 0 end
	if (args.downid == nil) then args.downid = 0 end
	if (args.mode == nil) then args.mode = "field" end

--	local funcDown = function(buttonID) Form.HandleButton(self, buttonID, "press") end
--	local funcUp = function(buttonID) Form.HandleButton(self, buttonID, "release") end
	local numericOnly = 0;
	if (args.filter == "digits") then numericOnly = 1 end
	
	-- Create it in the system		
	local newObj = textbox.create(args.x, args.y, args.width, args.height, 
		args.font, args.length, args.scankey1, args.scankey2, numericOnly, 
		args.justify, args.mode, Form.HandleTextbox)
	G_numTextBoxes = G_numTextBoxes+1;
	newObj.id = args.id;
	
	-- Add this object to the list with details
	self.objects[1+#self.objects] = newObj

	return newObj
end

function Form:controlUpdate()
	graphic.updateAllGraphics()
	mouse.updateEvents()
	keyboard.updateEvents()
	sound.update()
end

function Form:updateUI()
	self:controlUpdate()
	graphic.updateAllGraphics()	
end

function Form.handleMouseEvent(event, x, y, buttons)
	button.handleMouseEvent(event, x, y, buttons)
	slider.handleMouseEvent(event, x, y, buttons)
	if (G_numTextBoxes > 0) then
		textbox.handleMouseEvent(event, x, y, buttons)
	end
end

function Form.checkForGammaAdjust()
	-- At this point, the darkness can be adjusted with ALT-F11
	-- Check if the gamma key is pressed and adjust
	-- but don't keep adjusting until the key is released
	if (keyboard.getScanCode(keyboard.scankeys.KEY_SCAN_CODE_ALT)) then
		if (keymap.getScanCode(keymap.mapping.KEYMAP_GAMMA_CORRECT)) then
			if (wasGamma ~= true) then
				color.gammaAdjust()
				color.update(1)
				wasGamma = true
			end
		else
			wasGamma = false;
		end
	else
		wasGamma = false;
	end
end

function Form.handleKeyEvent(event, scankey)
	if (G_numButtons > 0) then 
		button.handleKeyEvent(event, scankey) 
	end 
	if (G_numTextBoxes > 0) then 
		textbox.handleKeyEvent(event, scankey) 
	end
	
	form.checkForGammaAdjust()	
end

function Form.start()
	keyboard.debounce()
	
	-- Intercept mouse and keyboard events
	mouse.pushEventHandler(Form.handleMouse)
 	keyboard.pushEventHandler(Form.handleKey)
end