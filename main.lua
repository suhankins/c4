--C4
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

local increaseKey = GetString("savegame.mod.increaseKey")
local decreaseKey = GetString("savegame.mod.decreaseKey")
local timerKey = GetString("savegame.mod.timerKey")
local detonateKey = GetString("savegame.mod.detonateKey")

local timerPresets = { 0, 0.1, 0.25, 0.5, 1, 2, 5 }

Bombs = {}
TimerTime = 0
BombsToExplode = 0
Sound = LoadSound("MOD/snd/c4plant.ogg")

local CONTROLS = {
	['increaseKey'] = {
		[1] = increaseKey,
		[2] = 'extra2'
	},
	['decreaseKey'] = {
		[1] = decreaseKey,
		[2] = 'extra1'
	},
	['timerKey'] = {
		[1] = timerKey,
		[2] = 'extra3'
	},
	['detonateKey'] = {
		[1] = detonateKey,
		[2] = 'extra0'
	}
}

local function getDeviceId()
	return LastInputDevice() or 1 -- We assume deviceId 0 is keyboard
end

local function getKey(key)
	return CONTROLS[key][getDeviceId()]
end

local function formatIcon(icon)
	return '[[' .. icon .. ';iconsize=40,40]]'
end

local DEFAULT_EXTRA_KEYS = {
	['extra0'] = {'gamepad_button_r3', 'gamepad_dpad_up'},
	['extra1'] = {'gamepad_button_r3', 'gamepad_dpad_right'},
	['extra2'] = {'gamepad_button_r3', 'gamepad_dpad_left'},
	['extra3'] = {'gamepad_button_r3', 'gamepad_dpad_down'},
}

local function getKeyText(key)
	if key == 'usetool' then
		return getDeviceId() == 1 and 'left mouse button' or formatIcon('usetool')
	end
	local keyCode = getKey(key)
	if getDeviceId() == 1 then
		return keyCode:upper()
	end
	local string = nil
	for _,icon in ipairs(DEFAULT_EXTRA_KEYS[keyCode]) do
		if string == nil then
			string = formatIcon(icon)
		else
			string = string .. '+' .. formatIcon(icon)
		end
	end
	return string
end

local function checkAmmo()
	if GetBool("savegame.mod.limitedammo") then
		return true
	elseif GetFloat("game.tool.cfour.ammo") > 0 then
		return true
	else
		return false
	end
end


local function CalculateQuat(normal, dir)
	local quat = QuatLookAt(Vec(), normal)
	if VecLength(VecCross(normal, Vec(0, 1, 0))) == 0 then
		quat = QuatRotateQuat(QuatEuler(0, math.deg(math.atan2(dir[1], dir[3])) + 180, 0), quat)
	end
	return quat
end

function init()
	--Register tool and enable it
	RegisterTool("cfour", "C4", "MOD/vox/c4.vox")
	SetBool("game.tool.cfour.enabled", true)
	if GetBool("savegame.mod.usetool") then
		RegisterTool("cfourdetonate", "Detonate C4", "")
		SetBool("game.tool.cfourdetonate.enabled", true)
	end

	--Setting ammo if limited ammo is... Disabled? Oh god, i messed it up
	if not GetBool("savegame.mod.limitedammo") then
		SetFloat("game.tool.cfour.ammo", 36)
	end

	--Setting the default explosion size value
	if GetFloat("savegame.mod.explosionSize") == 0 then
		SetFloat("savegame.mod.explosionSize", 2)
	end
	--Setting the default delay between explosions
	if GetInt("savegame.mod.explosionTimer") == 0 then
		SetInt("savegame.mod.explosionTimer", 1)
	end
end

---@param bombId number | nil
local function explodeBomb(bombId)
	--if bombId was not provided, set it to 1
	bombId = bombId or 1
	local bombPos = GetBodyTransform(Bombs[bombId][2]).pos
	Explosion(bombPos, GetFloat("savegame.mod.explosionSize"))
	for _, handle in ipairs(Bombs[bombId]) do
		Delete(handle)
	end
	table.remove(Bombs, bombId)
end

local function isDetonateKeyPressed()
	return InputDown(getKey('detonateKey')) and not GetBool("savegame.mod.usetool")
end

local function isDetonateToolUsed()
	return GetString("game.player.tool") == "cfourdetonate" and InputDown("usetool")
end

function tick(dt)
	--////////////////Explosion//////////////
	TimerTime = TimerTime + dt

	--Making the actual explosion happen
	if ((isDetonateKeyPressed() or isDetonateToolUsed()) and #Bombs > 0) then
		local temp = BombsToExplode
		BombsToExplode = #Bombs
		if (temp == 0) then
			TimerTime = 0
			explodeBomb()
			BombsToExplode = BombsToExplode - 1
		end
	end
	if BombsToExplode > 0 then
		if GetInt("savegame.mod.explosionTimer") == 1 then
			while BombsToExplode > 0 do
				explodeBomb()
				BombsToExplode = BombsToExplode - 1
			end
		elseif TimerTime > timerPresets[GetInt("savegame.mod.explosionTimer")] then
			TimerTime = 0
			explodeBomb()
			BombsToExplode = BombsToExplode - 1
		end
	end
	--////////////////Planting//////////////
	--Check if C4 is selected
	if GetString("game.player.tool") == "cfour" then
		SetToolHandPoseLocalTransform(Transform(Vec(0.1, 0, 0.0), QuatEuler(90, 180, 0)),
			Transform(Vec(-0.1, 0, 0.0), QuatEuler(-90, 0, 0)))
		SetToolTransform(Transform(Vec(0, -0.3, -0.5), QuatEuler(40, 0, 0)))

		--Check if tool is firing
		if GetBool("game.player.canusetool") and InputPressed("usetool") and checkAmmo() then
			if not GetBool("savegame.mod.limitedammo") then
				SetFloat("game.tool.cfour.ammo", GetFloat("game.tool.cfour.ammo") - 1)
			end
			local t = GetPlayerCameraTransform()
			local fwd = TransformToParentVec(t, Vec(0, 0, -1))
			-- Camera is further away in third person
			local maxDist = GetBool("game.thirdperson") and 8 or 4
			-- Making sure raycast collides with everything but the player and tool
			QueryInclude("physical dynamic static large small visible animator")
			if not GetBool('savegame.mod.collide') then
				for _, listOfObjects in ipairs(Bombs) do
					for _, handle in ipairs(listOfObjects) do
						QueryRejectShape(handle)
					end
				end
			end
			local hit, dist, normal = QueryRaycast(t.pos, fwd, maxDist)
			if hit then
				--Adding new bomb
				local hitVec = VecAdd(t.pos, VecScale(fwd, dist))
				local bombTransform = Transform(hitVec,
					QuatRotateQuat(CalculateQuat(normal, fwd), QuatEuler(-90, 0, 180)))
				local spawnedObjects = Spawn('MOD/c4.xml', bombTransform, true, true)
				if not GetBool('savegame.mod.collide') then
					for _, handle in ipairs(spawnedObjects) do
						SetShapeCollisionFilter(handle, 2, 255 - 2)
					end
				end
				Bombs[#Bombs + 1] = spawnedObjects

				--Playing the sounds
				PlaySound(Sound)
			end
		end

		--Making explosion bigger
		if InputDown(getKey('increaseKey')) then
			SetFloat("savegame.mod.explosionSize", GetFloat("savegame.mod.explosionSize") + 0.5 * dt)
			if (GetFloat("savegame.mod.explosionSize") > 4.0) then
				SetFloat("savegame.mod.explosionSize", 4.0)
			end
		end

		--Making explosion smaller
		if InputDown(getKey('decreaseKey')) then
			SetFloat("savegame.mod.explosionSize", GetFloat("savegame.mod.explosionSize") - 0.5 * dt)
			if (GetFloat("savegame.mod.explosionSize") < 0.5) then
				SetFloat("savegame.mod.explosionSize", 0.5)
			end
		end

		--Changing the timer
		if InputPressed(getKey('timerKey')) then
			SetInt("savegame.mod.explosionTimer", GetInt("savegame.mod.explosionTimer") + 1)
			if GetInt("savegame.mod.explosionTimer") > #timerPresets then
				SetInt("savegame.mod.explosionTimer", 1)
			end
		end
	end
end

function draw()
	if GetString("game.player.tool") == "cfour" and GetPlayerVehicle() == 0 then --I don't want it to draw this thing when player is in a car
		UiPush()
		UiTranslate(0, UiHeight() - 100)
		UiAlign("left bottom")
		UiFont("bold.ttf", 24)

		--I separated it into multiple lines for convenience
		local text = ""
		text = text .. "Active charges of C4: " .. #Bombs .. "\n"
		text = text ..
			"Explosion size: " ..
			math.floor(GetFloat("savegame.mod.explosionSize") * 100) /
			100 -- This math is needed to only leave 2 numbers after the decimal point
		text = text .. " (" .. math.floor((GetFloat("savegame.mod.explosionSize") - 0.5) / 3.5 * 100) .. "%)\n"
		text = text .. "Time between explosions: " .. timerPresets[GetInt("savegame.mod.explosionTimer")] .. "s\n"
		text = text .. "Press " .. getKeyText('usetool') .. " to plant a charge\n"
		if not GetBool("savegame.mod.usetool") then
			text = text .. "Press " .. getKeyText('detonateKey') .. " to detonate the charges\n"
		end
		text = text ..
			"Hold " .. getKeyText('increaseKey') .. "/" .. getKeyText('decreaseKey') .. " to change the size of explosion\n"
		text = text .. "Press " .. getKeyText('timerKey') .. " to change time between explosions"
		UiText(text)
		UiPop()
	end
end
