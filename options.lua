local changeKey = nil

local keyboard = { { "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12" },
	{ "1",   "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "0" },
	{ "tab", "q",  "w",  "e",  "r",  "t",  "y",  "u",  "i",  "o",   "p" },
	{ "a",   "s",  "d",  "f",  "g",  "h",  "j",  "k",  "l" },
	{ "z",   "x",  "c",  "v",  "b",  "n",  "m",  ",",  "." } }

--Setting default values, just in case
if GetString("savegame.mod.increaseKey") == "" then
	SetString("savegame.mod.increaseKey", "p")
end
if GetString("savegame.mod.decreaseKey") == "" then
	SetString("savegame.mod.decreaseKey", "l")
end
if GetString("savegame.mod.timerKey") == "" then
	SetString("savegame.mod.timerKey", "o")
end
if GetString("savegame.mod.detonateKey") == "" then
	SetString("savegame.mod.detonateKey", "k")
end


local keys = {
	["increaseKey"] = "Increase Explosion Size key",
	["decreaseKey"] = "Decrease Explosion Size key",
	["timerKey"] = "Change Time Between Explosions key",
	["detonateKey"] = "Detonation key"
}


---@param str string
---@return string, integer
local function firstToUpper(str)
	return str:gsub("%a", string.upper, 1)
end

---@param title string
---@param position number
---@param size number | nil
local function drawTitle(title, position, size)
	size = size or 30
	UiPush()
	UiTranslate(UiCenter(), position)
	UiAlign("center middle")
	UiFont("bold.ttf", 48)
	UiText(title)
	UiPop()
end

---@param x number
---@param y number
---@param text string
---@param active boolean
---@param onClick function
local function drawButton(x, y, text, active, onClick)
	UiPush() --Keyboard Key
	UiTranslate(x, y)
	UiAlign("center middle")
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	UiFont("regular.ttf", 26)
	if active then
		UiPush()
		UiColor(0.5, 1, 0.5, 0.2)
		UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
		UiPop()
	end
	if UiTextButton(text, 200, 40) then
		onClick()
	end
	UiPop()
end

---@param y number
---@param key string
---@param inactive boolean | nil
local function drawRemappingLabel(y, key, inactive)
	UiPush()
	UiTranslate(UiCenter() + 45, y)
	UiAlign("right middle")
	if inactive then
		UiColor(1, 1, 1, 0.4)
	end
	UiFont("regular.ttf", 26)
	UiText(keys[key] .. ":")
	UiPop()
	UiPush()
	UiTranslate(UiCenter() + 65, y)
	UiAlign("left middle")
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	UiFont("regular.ttf", 26)
	if inactive then
		UiColor(1, 1, 1, 0.4)
	end
	if UiTextButton(firstToUpper(GetString("savegame.mod." .. key)), 150, 40) then
		changeKey = key
	end
	UiPop()
end

---@param x number
---@param y number
---@param keyToChange string
---@param key string
---@param width number | nil
---@param height number | nil
---@param text string | nil
local function drawKeyboardButton(x, y, keyToChange, key, width, height, text)
	width = width or 50
	height = height or 50
	text = text or firstToUpper(key)
	UiPush()
	UiTranslate(x, y)
	if GetString("savegame.mod." .. keyToChange) == key then
		UiPush()
		UiColor(0.5, 1, 0.5, 0.2)
		UiImageBox("ui/common/box-solid-6.png", width, height, 6, 6)
		UiPop()
	end
	if UiTextButton(text, width, height) then
		SetString("savegame.mod." .. keyToChange, key)
	end
	UiPop()
end

function draw()
	if changeKey == nil then
		drawTitle("C4 Options", 100, 48)
		--Draw buttons
		--Tool/Keyboard Key Switch
		drawTitle('Detonate C4 using', 180)
		drawButton(UiCenter() - 110, 230, "Keyboard key", not GetBool("savegame.mod.usetool"), function()
			SetBool("savegame.mod.usetool", false)
		end)
		drawButton(UiCenter() + 110, 230, "'Detonate C4' tool", GetBool("savegame.mod.usetool"), function()
			SetBool("savegame.mod.usetool", true)
		end)

		--Tool/Keyboard Key Switch
		drawTitle('Should C4 charges collide with each other', 300)
		drawButton(UiCenter() - 110, 350, "Yes", GetBool("savegame.mod.collide"), function()
			SetBool("savegame.mod.collide", true)
		end)
		drawButton(UiCenter() + 110, 350, "No", not GetBool("savegame.mod.collide"), function()
			SetBool("savegame.mod.collide", false)
		end)

		--Limited/Unlimited ammo Switch
		drawTitle("Ammo", 420)
		drawButton(UiCenter() - 110, 470, "Limited", not GetBool("savegame.mod.limitedammo"), function()
			SetBool("savegame.mod.limitedammo", false)
		end)
		drawButton(UiCenter() + 110, 470, "Unlimited", GetBool("savegame.mod.limitedammo"), function()
			SetBool("savegame.mod.limitedammo", true)
		end)

		--Key remapping
		drawTitle("Key remapping", 550)
		drawRemappingLabel(650, "increaseKey")
		drawRemappingLabel(700, "decreaseKey")
		drawRemappingLabel(750, "timerKey")
		drawRemappingLabel(800, "detonateKey", GetBool("savegame.mod.usetool"))

		--Close
		drawButton(UiCenter(), 1000, "Close", false, function()
			Menu()
		end)
		--------------------------KEYBOARD CUSTOMIZATION STARTS HERE
	else
		UiAlign("center middle")
		UiFont("regular.ttf", 26)
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		UiPush()
		--F1-F12 key row
		UiTranslate(UiCenter() - 200, 350)
		for i = 1, #keyboard[1] do
			drawKeyboardButton(-330 + (i - 1) * 55, 0, changeKey, keyboard[1][i])
		end
		--Number key row
		UiTranslate(0, 55)
		for i = 1, #keyboard[2] do
			drawKeyboardButton(-350 + (i - 1) * 55, 0, changeKey, keyboard[2][i])
		end
		drawKeyboardButton(240, 0, changeKey, 'backspace', 125)
		--First key row
		UiTranslate(0, 55)
		for i = 1, #keyboard[3] do
			drawKeyboardButton(-330 + (i - 1) * 55, 0, changeKey, keyboard[3][i])
		end
		--Second key row
		UiTranslate(0, 55)
		for i = 1, #keyboard[4] do
			drawKeyboardButton(-320 + (i - 1) * 55, 0, changeKey, keyboard[4][i])
		end
		drawKeyboardButton(210, 0, changeKey, "return", 125)
		--Third key row
		UiTranslate(0, 55)
		for i = 1, #keyboard[5] do
			drawKeyboardButton(-300 + (i - 1) * 55, 0, changeKey, keyboard[5][i])
		end
		UiPop()
		--Some other keys
		UiPush()
		UiFont("regular.ttf", 18)
		UiTranslate(UiCenter() + 200, 405)
		--First row
		drawKeyboardButton(0, 0, changeKey, "insert", 60, 60)
		drawKeyboardButton(65, 0, changeKey, "home", 60, 60)
		drawKeyboardButton(130, 0, changeKey, "pgup", 60, 60, "Page\nup")
		--Second row
		UiTranslate(0, 65)
		drawKeyboardButton(0, 0, changeKey, "delete", 60, 60)
		drawKeyboardButton(65, 0, changeKey, "end", 60, 60)
		drawKeyboardButton(130, 0, changeKey, "pgdown", 60, 60, "Page\ndown")
		UiPop()
		--Text above and actually the entire logic of this thing
		drawTitle("Remapping: " .. keys[changeKey], 100, 48)
		--Cancel
		drawButton(UiCenter(), 1000, "Cancel", false, function()
			changeKey = nil
		end)
	end
end
