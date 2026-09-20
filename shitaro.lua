--==================================================--
-- WORLD standalone                                --
-- aura / skybox / shaders / crosshair /           --
-- fullbright / fog / time / effects / ambient /   --
-- exposure                                        --
-- no key, no third-party requests                 --
--==================================================--

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local function clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

-- original lighting values (for restore)
local O = {
	FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
	Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
	ClockTime = Lighting.ClockTime, ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	GeographicLatitude = Lighting.GeographicLatitude,
	ExposureCompensation = Lighting.ExposureCompensation,
}

-- live state
local S = {
	fogOn = false, fogColor = C(192, 192, 192), fogStart = 0, fogEnd = 1000,
	fbOn = false, ambOn = false, ambColor = C(128, 128, 128),
	timeOn = false, timeVal = 12, expOn = false, expVal = 0,
	shaderOn = false, shaderType = "morning",
	skyOn = false, skyName = "Jungle",
	auraOn = false, auraType = "angel", auraCol = C(133, 220, 255),
	fxOn = false, fxType = "Snow", fxColor = C(150, 200, 255), fxRate = 250,
	chOn = false,
}

------------------------------ SHADERS ------------------------------
local SHADERS = {
	morning = {
		Ambient = C(10, 10, 10), Brightness = 1.5, ClockTime = 7.5,
		ColorShift_Bottom = C(0, 0, 0), ColorShift_Top = C(200, 200, 200),
		EnvironmentDiffuseScale = 0.1, EnvironmentSpecularScale = 0.1,
		OutdoorAmbient = C(10, 10, 10), GeographicLatitude = 44,
		ExposureCompensation = 0.3, GlobalShadows = true,
		CC_Brightness = -0.02, CC_Contrast = 0.8, CC_Saturation = -0.5,
		CC_Tint = C(100, 150, 200),
		Bloom_Intensity = 0.2, Bloom_Size = 5, Bloom_Threshold = 0.8,
		Blur_Size = 2,
		DOF_Far = 0.5, DOF_Focus = 15, DOF_Radius = 5, DOF_Near = 0.5,
		Atmo_Density = 0.2, Atmo_Offset = 0.5, Atmo_Color = C(70, 120, 170),
		Atmo_Decay = C(10, 50, 100), Atmo_Glare = 0.3, Atmo_Haze = 1,
		Cloud_Cover = 0.6, Cloud_Density = 0.36, Cloud_Color = C(255, 255, 255),
	},
	midday = {
		Ambient = C(2, 2, 2), Brightness = 3.25, ClockTime = 8,
		ColorShift_Bottom = C(0, 0, 0), ColorShift_Top = C(255, 247, 237),
		EnvironmentDiffuseScale = 0.203, EnvironmentSpecularScale = 0.255,
		OutdoorAmbient = C(51, 54, 67), GeographicLatitude = -15.12,
		ExposureCompensation = 0.85, GlobalShadows = true,
		CC_Brightness = 0.1, CC_Contrast = 0.5, CC_Saturation = -0.3,
		CC_Tint = C(242, 243, 243),
		Bloom_Intensity = 0.3, Bloom_Size = 10, Bloom_Threshold = 0.8,
		Blur_Size = 5,
		DOF_Far = 0.277, DOF_Focus = 21.54, DOF_Radius = 16.77, DOF_Near = 0.277,
		Atmo_Density = 0.364, Atmo_Offset = 0.556, Atmo_Color = C(175, 221, 255),
		Atmo_Decay = C(13, 105, 172), Atmo_Glare = 0.36, Atmo_Haze = 0.72,
		Cloud_Cover = 0.75, Cloud_Density = 0.26, Cloud_Color = C(255, 255, 255),
	},
	evening = {
		Ambient = C(2, 2, 2), Brightness = 2.25, ClockTime = 16,
		ColorShift_Bottom = C(0, 0, 0), ColorShift_Top = C(255, 247, 237),
		EnvironmentDiffuseScale = 0.203, EnvironmentSpecularScale = 0.215,
		OutdoorAmbient = C(0, 0, 0), GeographicLatitude = 45,
		ExposureCompensation = 0.65, GlobalShadows = true,
		CC_Brightness = 0.1, CC_Contrast = 0.5, CC_Saturation = -0.3,
		CC_Tint = C(255, 205, 185),
		Bloom_Intensity = 0.3234, Bloom_Size = 10, Bloom_Threshold = 0.813,
		Blur_Size = 5,
		DOF_Far = 0.217, DOF_Focus = 21.54, DOF_Radius = 16.77, DOF_Near = 0.277,
		Atmo_Density = 0.364, Atmo_Offset = 5.556, Atmo_Color = C(199, 175, 166),
		Atmo_Decay = C(44, 39, 33), Atmo_Glare = 0.36, Atmo_Haze = 1.72,
		Cloud_Cover = 0.55, Cloud_Density = 0.43, Cloud_Color = C(199, 175, 166),
	},
	night = {
		Ambient = C(33, 33, 33), Brightness = 3.25, ClockTime = 20,
		ColorShift_Bottom = C(0, 0, 0), ColorShift_Top = C(255, 247, 237),
		EnvironmentDiffuseScale = 0.203, EnvironmentSpecularScale = 0.255,
		OutdoorAmbient = C(51, 54, 67), GeographicLatitude = -15,
		ExposureCompensation = 0.85, GlobalShadows = true,
		CC_Brightness = -0.06, CC_Contrast = -0.02, CC_Saturation = -0.2,
		CC_Tint = C(242, 243, 243),
		Bloom_Intensity = 0.34, Bloom_Size = 10, Bloom_Threshold = 0.813,
		Blur_Size = 5,
		DOF_Far = 0.217, DOF_Focus = 11.54, DOF_Radius = 16.77, DOF_Near = 0.277,
		Atmo_Density = 0.264, Atmo_Offset = 0.156, Atmo_Color = C(175, 221, 255),
		Atmo_Decay = C(13, 105, 172), Atmo_Glare = 0.36, Atmo_Haze = 1.72,
		Cloud_Cover = 0.65, Cloud_Density = 0.33, Cloud_Color = C(255, 255, 255),
	},
}

local bloomFx, blurFx, ccFx, dofFx, atmoFx, cloudFx = nil, nil, nil, nil, nil, nil
local origFx, madeFx = {}, {}

local function ensure_effects()
	if not bloomFx or not bloomFx.Parent then
		bloomFx = Lighting:FindFirstChildOfClass("BloomEffect")
		if not bloomFx then
			bloomFx = Instance.new("BloomEffect")
			bloomFx.Enabled = false
			bloomFx.Parent = Lighting
			madeFx.bloom = true
		end
	end
	if not blurFx or not blurFx.Parent then
		blurFx = Lighting:FindFirstChildOfClass("BlurEffect")
		if not blurFx then
			blurFx = Instance.new("BlurEffect")
			blurFx.Enabled = false
			blurFx.Size = 0
			blurFx.Parent = Lighting
			madeFx.blur = true
		end
	end
	if not ccFx or not ccFx.Parent then
		ccFx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if not ccFx then
			ccFx = Instance.new("ColorCorrectionEffect")
			ccFx.Enabled = false
			ccFx.Parent = Lighting
			madeFx.colorcor = true
		end
	end
	if not dofFx or not dofFx.Parent then
		dofFx = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
		if not dofFx then
			dofFx = Instance.new("DepthOfFieldEffect")
			dofFx.Enabled = false
			dofFx.Parent = Lighting
			madeFx.depth = true
		end
	end
	if not atmoFx or not atmoFx.Parent then
		atmoFx = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atmoFx then
			atmoFx = Instance.new("Atmosphere")
			atmoFx.Parent = Lighting
			madeFx.atmosphere = true
		end
	end
	if workspace:FindFirstChildOfClass("Terrain") and (not cloudFx or not cloudFx.Parent) then
		cloudFx = workspace.Terrain:FindFirstChildOfClass("Clouds")
		if not cloudFx then
			cloudFx = Instance.new("Clouds")
			cloudFx.Cover = 0
			cloudFx.Density = 0
			cloudFx.Parent = workspace.Terrain
			madeFx.cloud = true
		end
	end
end

local function save_original_effects()
	bloomFx = Lighting:FindFirstChildOfClass("BloomEffect")
	blurFx = Lighting:FindFirstChildOfClass("BlurEffect")
	ccFx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	dofFx = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	atmoFx = Lighting:FindFirstChildOfClass("Atmosphere")
	if workspace:FindFirstChildOfClass("Terrain") then
		cloudFx = workspace.Terrain:FindFirstChildOfClass("Clouds")
	end
	if ccFx then
		origFx.colorcor = { Brightness = ccFx.Brightness, Contrast = ccFx.Contrast,
			Saturation = ccFx.Saturation, TintColor = ccFx.TintColor, Enabled = ccFx.Enabled }
	end
	if bloomFx then
		origFx.bloom = { Intensity = bloomFx.Intensity, Size = bloomFx.Size,
			Threshold = bloomFx.Threshold, Enabled = bloomFx.Enabled }
	end
	if blurFx then
		origFx.blur = { Size = blurFx.Size, Enabled = blurFx.Enabled }
	end
	if dofFx then
		origFx.depth = { FarIntensity = dofFx.FarIntensity, FocusDistance = dofFx.FocusDistance,
			InFocusRadius = dofFx.InFocusRadius, NearIntensity = dofFx.NearIntensity, Enabled = dofFx.Enabled }
	end
	if atmoFx then
		origFx.atmosphere = { Density = atmoFx.Density, Offset = atmoFx.Offset,
			Color = atmoFx.Color, Decay = atmoFx.Decay, Glare = atmoFx.Glare, Haze = atmoFx.Haze }
	end
	if cloudFx then
		origFx.cloud = { Cover = cloudFx.Cover, Density = cloudFx.Density, Color = cloudFx.Color }
	end
end

local SHADER_FOG_INF = math.huge
local SHADER_FOG_COL = C(255, 255, 255)

local function apply_shader(d)
	ensure_effects()
	if Lighting.Ambient ~= d.Ambient then Lighting.Ambient = d.Ambient end
	if Lighting.Brightness ~= d.Brightness then Lighting.Brightness = d.Brightness end
	if Lighting.ClockTime ~= d.ClockTime then Lighting.ClockTime = d.ClockTime end
	if Lighting.ColorShift_Bottom ~= d.ColorShift_Bottom then Lighting.ColorShift_Bottom = d.ColorShift_Bottom end
	if Lighting.ColorShift_Top ~= d.ColorShift_Top then Lighting.ColorShift_Top = d.ColorShift_Top end
	if Lighting.EnvironmentDiffuseScale ~= d.EnvironmentDiffuseScale then Lighting.EnvironmentDiffuseScale = d.EnvironmentDiffuseScale end
	if Lighting.EnvironmentSpecularScale ~= d.EnvironmentSpecularScale then Lighting.EnvironmentSpecularScale = d.EnvironmentSpecularScale end
	if Lighting.OutdoorAmbient ~= d.OutdoorAmbient then Lighting.OutdoorAmbient = d.OutdoorAmbient end
	if Lighting.GeographicLatitude ~= d.GeographicLatitude then Lighting.GeographicLatitude = d.GeographicLatitude end
	if Lighting.ExposureCompensation ~= d.ExposureCompensation then Lighting.ExposureCompensation = d.ExposureCompensation end
	if Lighting.GlobalShadows ~= d.GlobalShadows then Lighting.GlobalShadows = d.GlobalShadows end
	if Lighting.FogEnd ~= SHADER_FOG_INF then Lighting.FogEnd = SHADER_FOG_INF end
	if Lighting.FogColor ~= SHADER_FOG_COL then Lighting.FogColor = SHADER_FOG_COL end
	if Lighting.FogStart ~= SHADER_FOG_INF then Lighting.FogStart = SHADER_FOG_INF end
	if ccFx then
		if ccFx.Brightness ~= d.CC_Brightness then ccFx.Brightness = d.CC_Brightness end
		if ccFx.Contrast ~= d.CC_Contrast then ccFx.Contrast = d.CC_Contrast end
		if ccFx.Saturation ~= d.CC_Saturation then ccFx.Saturation = d.CC_Saturation end
		if ccFx.TintColor ~= d.CC_Tint then ccFx.TintColor = d.CC_Tint end
		if ccFx.Enabled ~= true then ccFx.Enabled = true end
	end
	if bloomFx then
		if bloomFx.Intensity ~= d.Bloom_Intensity then bloomFx.Intensity = d.Bloom_Intensity end
		if bloomFx.Size ~= d.Bloom_Size then bloomFx.Size = d.Bloom_Size end
		if bloomFx.Threshold ~= d.Bloom_Threshold then bloomFx.Threshold = d.Bloom_Threshold end
		if bloomFx.Enabled ~= true then bloomFx.Enabled = true end
	end
	if blurFx then
		if blurFx.Size ~= d.Blur_Size then blurFx.Size = d.Blur_Size end
		if blurFx.Enabled ~= false then blurFx.Enabled = false end
	end
	if dofFx then
		if dofFx.FarIntensity ~= d.DOF_Far then dofFx.FarIntensity = d.DOF_Far end
		if dofFx.FocusDistance ~= d.DOF_Focus then dofFx.FocusDistance = d.DOF_Focus end
		if dofFx.InFocusRadius ~= d.DOF_Radius then dofFx.InFocusRadius = d.DOF_Radius end
		if dofFx.NearIntensity ~= d.DOF_Near then dofFx.NearIntensity = d.DOF_Near end
		if dofFx.Enabled ~= true then dofFx.Enabled = true end
	end
	if atmoFx then
		if atmoFx.Density ~= d.Atmo_Density then atmoFx.Density = d.Atmo_Density end
		if atmoFx.Offset ~= d.Atmo_Offset then atmoFx.Offset = d.Atmo_Offset end
		if atmoFx.Color ~= d.Atmo_Color then atmoFx.Color = d.Atmo_Color end
		if atmoFx.Decay ~= d.Atmo_Decay then atmoFx.Decay = d.Atmo_Decay end
		if atmoFx.Glare ~= d.Atmo_Glare then atmoFx.Glare = d.Atmo_Glare end
		if atmoFx.Haze ~= d.Atmo_Haze then atmoFx.Haze = d.Atmo_Haze end
	end
	if cloudFx then
		if cloudFx.Cover ~= d.Cloud_Cover then cloudFx.Cover = d.Cloud_Cover end
		if cloudFx.Density ~= d.Cloud_Density then cloudFx.Density = d.Cloud_Density end
		if cloudFx.Color ~= d.Cloud_Color then cloudFx.Color = d.Cloud_Color end
	end
end

local function restore_original()
	if origFx.colorcor and ccFx then
		for p, v in pairs(origFx.colorcor) do ccFx[p] = v end
	elseif madeFx.colorcor and ccFx then
		ccFx:Destroy() ccFx = nil madeFx.colorcor = nil
	end
	if origFx.bloom and bloomFx then
		for p, v in pairs(origFx.bloom) do bloomFx[p] = v end
	elseif madeFx.bloom and bloomFx then
		bloomFx:Destroy() bloomFx = nil madeFx.bloom = nil
	end
	if origFx.blur and blurFx then
		for p, v in pairs(origFx.blur) do blurFx[p] = v end
	elseif madeFx.blur and blurFx then
		blurFx:Destroy() blurFx = nil madeFx.blur = nil
	end
	if origFx.depth and dofFx then
		for p, v in pairs(origFx.depth) do dofFx[p] = v end
	elseif madeFx.depth and dofFx then
		dofFx:Destroy() dofFx = nil madeFx.depth = nil
	end
	if origFx.atmosphere and atmoFx then
		for p, v in pairs(origFx.atmosphere) do atmoFx[p] = v end
	elseif madeFx.atmosphere and atmoFx then
		atmoFx:Destroy() atmoFx = nil madeFx.atmosphere = nil
	end
	if origFx.cloud and cloudFx then
		for p, v in pairs(origFx.cloud) do cloudFx[p] = v end
	elseif madeFx.cloud and cloudFx then
		cloudFx:Destroy() cloudFx = nil madeFx.cloud = nil
	end
end

local shaderConn = nil
local function disable_shader()
	S.shaderOn = false
	if shaderConn then pcall(function() shaderConn:Disconnect() end) shaderConn = nil end
	restore_original()
	Lighting.Ambient = S.ambOn and S.ambColor or O.Ambient
	Lighting.OutdoorAmbient = S.ambOn and S.ambColor or O.OutdoorAmbient
	Lighting.Brightness = S.fbOn and 2 or O.Brightness
	Lighting.FogColor = S.fogOn and S.fogColor or O.FogColor
	Lighting.FogStart = S.fogOn and S.fogStart or O.FogStart
	Lighting.FogEnd = S.fogOn and S.fogEnd or (S.fbOn and 100000 or O.FogEnd)
	Lighting.GlobalShadows = S.fbOn and false or O.GlobalShadows
	Lighting.ClockTime = S.fbOn and 14 or O.ClockTime
	Lighting.ColorShift_Bottom = O.ColorShift_Bottom
	Lighting.ColorShift_Top = O.ColorShift_Top
	Lighting.EnvironmentDiffuseScale = O.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = O.EnvironmentSpecularScale
	Lighting.GeographicLatitude = O.GeographicLatitude
	Lighting.ExposureCompensation = O.ExposureCompensation
end

local function setShader(on)
	S.shaderOn = on
	if on then
		apply_shader(SHADERS[S.shaderType])
		if not shaderConn then
			local accum = 0
			shaderConn = RS.Heartbeat:Connect(function(dt)
				if not S.shaderOn then return end
				local d = SHADERS[S.shaderType]
				accum = accum + dt
				if accum >= 1 then
					accum = 0
					apply_shader(d)
					return
				end
				if Lighting.Ambient ~= d.Ambient
					or Lighting.Brightness ~= d.Brightness
					or Lighting.ClockTime ~= d.ClockTime
					or Lighting.OutdoorAmbient ~= d.OutdoorAmbient
					or Lighting.ExposureCompensation ~= d.ExposureCompensation
					or Lighting.GlobalShadows ~= d.GlobalShadows
					or Lighting.ColorShift_Top ~= d.ColorShift_Top
					or Lighting.FogEnd ~= math.huge then
					apply_shader(d)
				end
			end)
		end
	else
		disable_shader()
	end
end

------------------------------ SKYBOX ------------------------------
local SKYBOXES = {
	["Jungle"] = {
		SkyboxBk = "http://www.roblox.com/asset/?id=214399891",
		SkyboxDn = "http://www.roblox.com/asset/?id=214399887",
		SkyboxFt = "http://www.roblox.com/asset/?id=214399894",
		SkyboxLf = "http://www.roblox.com/asset/?id=214405668",
		SkyboxRt = "http://www.roblox.com/asset/?id=214399899",
		SkyboxUp = "http://www.roblox.com/asset/?id=214399889",
	},
	["Blossom"] = {
		SkyboxBk = "http://www.roblox.com/asset/?id=271042516",
		SkyboxDn = "http://www.roblox.com/asset/?id=271077243",
		SkyboxFt = "http://www.roblox.com/asset/?id=271042556",
		SkyboxLf = "http://www.roblox.com/asset/?id=271042310",
		SkyboxRt = "http://www.roblox.com/asset/?id=271042467",
		SkyboxUp = "http://www.roblox.com/asset/?id=271077958",
	},
	["Red night"] = {
		SkyboxBk = "http://www.roblox.com/Asset/?ID=401664839",
		SkyboxDn = "http://www.roblox.com/Asset/?ID=401664862",
		SkyboxFt = "http://www.roblox.com/Asset/?ID=401664960",
		SkyboxLf = "http://www.roblox.com/Asset/?ID=401664881",
		SkyboxRt = "http://www.roblox.com/Asset/?ID=401664901",
		SkyboxUp = "http://www.roblox.com/Asset/?ID=401664936",
	},
	["Purple default"] = {
		SkyboxBk = "http://www.roblox.com/asset/?id=13694952867",
		SkyboxDn = "http://www.roblox.com/asset/?id=13694968325",
		SkyboxFt = "http://www.roblox.com/asset/?id=13694980654",
		SkyboxLf = "http://www.roblox.com/asset/?id=13694998113",
		SkyboxRt = "http://www.roblox.com/asset/?id=13695002700",
		SkyboxUp = "http://www.roblox.com/asset/?id=13695007103",
	},
	["Foggy"] = {
		SkyboxBk = "rbxassetid://1370717244",
		SkyboxDn = "rbxassetid://1370717336",
		SkyboxFt = "rbxassetid://1370717438",
		SkyboxLf = "rbxassetid://1370717567",
		SkyboxRt = "rbxassetid://1370717698",
		SkyboxUp = "rbxassetid://1370717782",
	},
}
local SKY_ASSETS = { ["Galaxy"] = 15983996673, ["Anime"] = 13107361022, ["Minecraft"] = 2758029221 }
local SKY_LIST = { "Purple", "Red night", "Blossom", "Jungle", "Foggy", "Galaxy", "Anime", "Minecraft" }
local createdSky, originalSky, originalSkyParent = nil, nil, nil

local function detach_original_sky()
	if originalSky then return end
	local existing = Lighting:FindFirstChildOfClass("Sky")
	if existing and existing ~= createdSky then
		originalSky = existing
		originalSkyParent = existing.Parent
		pcall(function() existing.Parent = nil end)
	end
end

local function clear_created_sky()
	if createdSky then
		pcall(function() createdSky:Destroy() end)
		createdSky = nil
	end
end

local function apply_textures(data)
	detach_original_sky()
	clear_created_sky()
	local sky = Instance.new("Sky")
	sky.Name = "WorldSky"
	for k, v in pairs(data) do pcall(function() sky[k] = v end) end
	sky.Parent = Lighting
	createdSky = sky
end

local function apply_sky_asset(id)
	task.spawn(function()
		local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		if not ok or type(objs) ~= "table" then return end
		local found = nil
		for _, o in ipairs(objs) do
			if o:IsA("Sky") then found = o break end
			local s = o:FindFirstChildWhichIsA("Sky", true)
			if s then found = s break end
		end
		if not found or not S.skyOn then return end
		detach_original_sky()
		clear_created_sky()
		found.Name = "WorldSky"
		found.Parent = Lighting
		createdSky = found
	end)
end

local function apply_skybox(name)
	if name == "Purple" then name = "Purple default" end
	if SKYBOXES[name] then
		apply_textures(SKYBOXES[name])
	elseif SKY_ASSETS[name] then
		apply_sky_asset(SKY_ASSETS[name])
	end
end

local function restore_skybox()
	clear_created_sky()
	if originalSky then
		pcall(function() originalSky.Parent = originalSkyParent or Lighting end)
		originalSky = nil
		originalSkyParent = nil
	end
end

local function setSky(on)
	S.skyOn = on
	if on then apply_skybox(S.skyName) else restore_skybox() end
end

------------------------------ AURA ------------------------------
local AURA_IDS = {
	angel = "97658130917593", starlight = "134645216613107",
	heavenly = "139300897520961", ribbon = "132069507632161",
	sakura = "81755778619404", wind = "80694081850877",
	flow = "119913533725648", star = "73754563740680",
}
local AURA_ORDER = { "angel", "starlight", "heavenly", "ribbon", "sakura", "wind", "flow", "star" }
local auraCache, auraParts = {}, {}
local auraConn, auraBtConn, auraHost = nil, nil, nil

local function load_aura(name)
	if auraCache[name] then return auraCache[name] end
	local id = AURA_IDS[name]
	if not id then return nil end
	local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. id)
	if ok and objs and objs[1] then
		auraCache[name] = objs[1]
		return objs[1]
	end
	return nil
end

local function color_aura(model, color)
	local seq = ColorSequence.new(color)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("PointLight") then
			d.Color = color
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
			d.Color = seq
		end
	end
end

local function clear_aura()
	for i = #auraParts, 1, -1 do
		pcall(function() auraParts[i]:Destroy() end)
		auraParts[i] = nil
	end
	local char = LP.Character
	if not char then return end
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam")
					or child:IsA("Trail") or child:IsA("PointLight") then
					local isAura = false
					for an, _ in pairs(AURA_IDS) do
						if child.Name:lower():find(an) or child.Name:find("Aura") or child.Name:find("Effect") then
							isAura = true
							break
						end
					end
					if isAura then pcall(function() child:Destroy() end) end
				end
			end
		end
	end
end

local function apply_aura()
	clear_aura()
	auraHost = nil
	local host = LP.Character
	if not host or not host.Parent then return end
	local src = load_aura(S.auraType)
	if not src then return end
	color_aura(src, S.auraCol)
	local cloned = src:Clone()
	for _, part in ipairs(cloned:GetChildren()) do
		local target = host:FindFirstChild(part.Name)
		if target and target:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				child.Parent = target
				auraParts[#auraParts + 1] = child
			end
		end
	end
	cloned:Destroy()
	auraHost = host
end

local function aura_sync()
	if not S.auraOn then return end
	local host = LP.Character
	if host ~= auraHost then
		apply_aura()
		return
	end
	if not host then return end
	local first = auraParts[1]
	if first and not first.Parent then apply_aura() end
end

local function setAura(on)
	S.auraOn = on
	clear_aura()
	auraHost = nil
	if auraConn then pcall(function() auraConn:Disconnect() end) auraConn = nil end
	if auraBtConn then pcall(function() auraBtConn:Disconnect() end) auraBtConn = nil end
	if on then
		task.spawn(apply_aura)
		auraConn = LP.CharacterAdded:Connect(function()
			task.wait(0.5)
			if S.auraOn then apply_aura() end
		end)
		local accum = 0
		auraBtConn = RS.Heartbeat:Connect(function(dt)
			accum = accum + dt
			if accum < 0.2 then return end
			accum = 0
			aura_sync()
		end)
	end
end

------------------------------ CROSSHAIR (frames, no Drawing needed) ------------------------------
local CH = {
	gap = 4, len = 8, thick = 2, rot = 0,
	col = C(255, 255, 255), out = C(0, 0, 0), hideOrig = false,
}
local chGui, chConn, chCharConn = nil, nil, nil
local chWatchConns, chFrames = {}, {}
local chGunEquipped, chGameGui, chHookConn = false, nil, nil
local chAngle = 0

local function chHasGun()
	local char = LP.Character
	if char and char:FindFirstChild("Gun") then return true end
	return false
end

local function chParent()
	local ok, res = pcall(function() return gethui() end)
	if ok and typeof(res) == "Instance" then return res end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 then return core end
	return LP:FindFirstChildOfClass("PlayerGui")
end

local function chMakeGui()
	if chGui and chGui.Parent then return end
	chGui = Instance.new("ScreenGui")
	chGui.Name = "WorldCrosshair"
	chGui.ResetOnSpawn = false
	chGui.IgnoreGuiInset = true
	chGui.DisplayOrder = 999
	chFrames = {}
	for i = 1, 8 do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BorderSizePixel = 0
		f.Visible = false
		if i % 2 == 1 then
			f.BackgroundColor3 = CH.col
			f.ZIndex = 2
		else
			f.BackgroundColor3 = CH.out
			f.ZIndex = 1
		end
		f.Parent = chGui
		chFrames[i] = f
	end
	chGui.Parent = chParent()
end

local function chSetVisible(v)
	if type(chFrames) ~= "table" then return end
	v = (v and true) or false
	for i = 1, #chFrames do
		local f = chFrames[i]
		if typeof(f) == "Instance" and f:IsA("GuiObject") then
			pcall(function() f.Visible = v end)
		end
	end
end

local function chHideGameGui()
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local topbar = pg:FindFirstChild("GameTopbar")
	if not topbar then return end
	local ch = topbar:FindFirstChild("Crosshair")
	if ch and ch:IsA("GuiObject") then
		chGameGui = ch
		ch.Visible = false
	end
end

local function chShowGameGui()
	if chGameGui and chGameGui.Parent and chGameGui:IsA("GuiObject") then
		pcall(function() chGameGui.Visible = true end)
	end
end

local function chHideCursor(hide)
	pcall(function()
		if hide and CH.hideOrig then
			pcall(function()
				local hook = hookmetamethod(game, "__newindex", function(self, prop, val)
					if prop == "Icon" and CH.hideOrig and checkcaller() == false and self:IsA("Mouse") then
						if val == "rbxassetid://79658449" or val == "" then return end
					end
					return hook(self, prop, val)
				end)
			end)
			local m = LP:GetMouse()
			if m then m.Icon = "" end
			chHideGameGui()
		else
			local m = LP:GetMouse()
			if m then m.Icon = "" end
			if not S.chOn then chShowGameGui() end
		end
	end)
end

local function chUpdate(dt)
	if not S.chOn then return end
	if not (chGui and chGui.Parent) or type(chFrames) ~= "table" or #chFrames == 0 then
		pcall(chMakeGui)
		if type(chFrames) ~= "table" or #chFrames == 0 then return end
	end
	local equipped = chHasGun()
	chGunEquipped = equipped
	if not equipped then
		chSetVisible(false)
		return
	end
	local mp = UIS:GetMouseLocation()
	local cx, cy = mp.X, mp.Y
	if CH.rot > 0 then
		chAngle = (chAngle + dt * CH.rot * 100) % 360
	else
		chAngle = 0
	end
	local rad0 = math.rad(chAngle)
	for i = 1, 4 do
		local a = rad0 + (i - 1) * math.pi / 2
		local ca, sa = math.cos(a), math.sin(a)
		local li, oi = (i - 1) * 2 + 1, (i - 1) * 2 + 2
		local mx, my = cx + ca * (CH.gap + CH.len / 2), cy + sa * (CH.gap + CH.len / 2)
		local deg = math.deg(a)
		local lf = chFrames[li]
		if lf and lf.Parent then
			lf.Size = UDim2.fromOffset(CH.len, CH.thick)
			lf.Position = UDim2.fromOffset(mx, my)
			lf.Rotation = deg
			lf.Visible = true
		end
		local of = chFrames[oi]
		if of and of.Parent then
			local omx, omy = cx + ca * (CH.gap + CH.len / 2), cy + sa * (CH.gap + CH.len / 2)
			of.Size = UDim2.fromOffset(CH.len + 2, CH.thick + 2)
			of.Position = UDim2.fromOffset(omx, omy)
			of.Rotation = deg
			of.Visible = true
		end
	end
end

local function chWatchGun(container)
	if not container then return end
	local c1 = container.ChildAdded:Connect(function(child)
		if child.Name == "Gun" then
			chHideGameGui()
			chHideCursor(true)
		end
	end)
	local c2 = container.ChildRemoved:Connect(function(child)
		if child.Name == "Gun" then
			chHideCursor(false)
		end
	end)
	chWatchConns[#chWatchConns + 1] = c1
	chWatchConns[#chWatchConns + 1] = c2
end

local function setCrosshair(on)
	S.chOn = on
	if on then
		chMakeGui()
		if chConn then return end
		chConn = RS.RenderStepped:Connect(chUpdate)
		if not chHookConn then
			local pg = LP:FindFirstChildOfClass("PlayerGui")
			if pg then
				chHookConn = pg.DescendantAdded:Connect(function(d)
					if d.Name == "Crosshair" and d.Parent and d.Parent.Name == "GameTopbar" then
						if CH.hideOrig and d:IsA("GuiObject") then
							d.Visible = false
							chGameGui = d
						end
					end
				end)
			end
		end
		local char = LP.Character
		if char then chWatchGun(char) end
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then chWatchGun(bp) end
		if chCharConn then pcall(function() chCharConn:Disconnect() end) end
		chCharConn = LP.CharacterAdded:Connect(function(nc)
			task.wait(0.3)
			chWatchGun(nc)
			chWatchGun(LP:FindFirstChildOfClass("Backpack"))
			chHideCursor(chHasGun() and CH.hideOrig)
		end)
		chGunEquipped = chHasGun()
		chHideCursor(chGunEquipped and CH.hideOrig)
	else
		if chConn then pcall(function() chConn:Disconnect() end) chConn = nil end
		if chHookConn then pcall(function() chHookConn:Disconnect() end) chHookConn = nil end
		if chCharConn then pcall(function() chCharConn:Disconnect() end) chCharConn = nil end
		for _, c in ipairs(chWatchConns) do pcall(function() c:Disconnect() end) end
		chWatchConns = {}
		chSetVisible(false)
		chHideCursor(false)
		chShowGameGui()
	end
end

local function applyCrossColors()
	for i = 1, #chFrames do
		local f = chFrames[i]
		if f then
			if i % 2 == 1 then f.BackgroundColor3 = CH.col
			else f.BackgroundColor3 = CH.out end
		end
	end
end

------------------------------ FULLBRIGHT / FOG / TIME / AMBIENT / EXPOSURE ------------------------------
local function setFullbright(on)
	S.fbOn = on
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = C(128, 128, 128)
		if not S.fogOn then Lighting.FogEnd = 100000 end
	else
		Lighting.Brightness = O.Brightness
		Lighting.GlobalShadows = O.GlobalShadows
		Lighting.OutdoorAmbient = S.ambOn and S.ambColor or O.OutdoorAmbient
		Lighting.FogEnd = S.fogOn and S.fogEnd or O.FogEnd
	end
end

local function setFog(on)
	S.fogOn = on
	if on then
		Lighting.FogColor = S.fogColor
		Lighting.FogStart = S.fogStart
		Lighting.FogEnd = S.fogEnd
	else
		Lighting.FogColor = O.FogColor
		Lighting.FogStart = O.FogStart
		Lighting.FogEnd = O.FogEnd
	end
end

local function setTime(on)
	S.timeOn = on
	Lighting.ClockTime = on and S.timeVal or O.ClockTime
end

local function setAmbient(on)
	S.ambOn = on
	if on then
		Lighting.Ambient = S.ambColor
		Lighting.OutdoorAmbient = S.ambColor
	else
		Lighting.Ambient = O.Ambient
		Lighting.OutdoorAmbient = O.OutdoorAmbient
	end
end

local expWatch = true
local function enforce_exp()
	if not S.expOn then return end
	if Lighting.ExposureCompensation ~= S.expVal then
		Lighting.ExposureCompensation = S.expVal
	end
end

local function setExposure(on)
	S.expOn = on
	Lighting.ExposureCompensation = on and S.expVal or O.ExposureCompensation
end

pcall(function()
	Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
		if expWatch then enforce_exp() end
	end)
end)
task.spawn(function()
	while expWatch do
		task.wait(0.25)
		pcall(enforce_exp)
	end
end)

------------------------------ WORLD EFFECTS (Snow / Sakura) ------------------------------
local FX_SOFT = "rbxasset://textures/particles/smoke_main.dds"
local FX_SPAN, FX_TALL = 260, 140
local fxPart, fxEmitter, fxConn, fxPos, fxLook = nil, nil, nil, nil, nil

local function fxStyle(t)
	local e = fxEmitter
	if not e then return end
	e.Texture = FX_SOFT
	e.LightInfluence = 0
	e.LightEmission = 0.4
	e.ZOffset = 0
	e.Drag = 0
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Rate = S.fxRate
	e.Color = ColorSequence.new(S.fxColor)
	if t == "Snow" then
		e.Lifetime = NumberRange.new(4, 6)
		e.Speed = NumberRange.new(6, 12)
		e.Acceleration = Vector3.new(2, -6, 1)
		e.SpreadAngle = Vector2.new(35, 35)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-40, 40)
		e.Squash = NumberSequence.new(0)
		e.Size = NumberSequence.new(0.55)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
	else
		e.Lifetime = NumberRange.new(5, 7)
		e.Speed = NumberRange.new(5, 10)
		e.Acceleration = Vector3.new(4, -5, 2)
		e.SpreadAngle = Vector2.new(40, 40)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-80, 80)
		e.Squash = NumberSequence.new(1.4)
		e.Size = NumberSequence.new(0.5)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.85, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end

local function fxStop()
	if fxConn then pcall(function() fxConn:Disconnect() end) fxConn = nil end
	if fxPart then pcall(function() fxPart:Destroy() end) fxPart = nil end
	fxEmitter = nil
	fxPos, fxLook = nil, nil
end

local function fxEnsure()
	if fxPart and fxPart.Parent then return end
	fxPart = Instance.new("Part")
	fxPart.Name = "WORLD_FX"
	fxPart.Anchored = true
	fxPart.CanCollide = false
	fxPart.CanQuery = false
	fxPart.CanTouch = false
	fxPart.Transparency = 1
	fxPart.Size = Vector3.new(FX_SPAN, FX_TALL, FX_SPAN)
	fxPart.Parent = workspace
	fxEmitter = Instance.new("ParticleEmitter")
	pcall(function()
		fxEmitter.Shape = Enum.ParticleEmitterShape.Box
		fxEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end)
	fxEmitter.Parent = fxPart
	fxStyle(S.fxType)
end

local function fxBurst()
	if not fxEmitter then return end
	fxEmitter:Emit(clamp(math.floor(S.fxRate * 0.16), 30, 140))
end

local function setFx(on)
	S.fxOn = on
	if on then
		fxEnsure()
		if fxConn then return end
		fxPos, fxLook = nil, nil
		fxConn = RS.RenderStepped:Connect(function()
			if not (fxPart and fxPart.Parent) then return end
			local cam = workspace.CurrentCamera
			if not cam then return end
			local cf = cam.CFrame
			local p = cf.Position
			local d = cf.LookVector
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1)
			else flat = flat.Unit end
			if fxPos and fxLook and (p - fxPos).Magnitude < 10 and flat:Dot(fxLook) > 0.95 then return end
			fxPos, fxLook = p, flat
			fxPart.CFrame = CFrame.new(p + flat * (FX_SPAN * 0.22) + Vector3.new(0, FX_TALL * 0.5 - 26, 0))
		end)
		fxBurst()
	else
		fxStop()
	end
end

------------------------------ UNLOAD ------------------------------
local menuGui, floatBtn = nil, nil
local function unloadAll()
	expWatch = false
	setFx(false)
	setCrosshair(false)
	setAura(false)
	setSky(false)
	setShader(false)
	if S.fbOn then setFullbright(false) end
	if S.fogOn then setFog(false) end
	if S.timeOn then setTime(false) end
	if S.ambOn then setAmbient(false) end
	if S.expOn then setExposure(false) end
	Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = O.FogColor, O.FogStart, O.FogEnd
	Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = O.Brightness, O.Ambient, O.OutdoorAmbient
	Lighting.GlobalShadows, Lighting.ClockTime = O.GlobalShadows, O.ClockTime
	Lighting.ColorShift_Bottom, Lighting.ColorShift_Top = O.ColorShift_Bottom, O.ColorShift_Top
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = O.EnvironmentDiffuseScale, O.EnvironmentSpecularScale
	Lighting.GeographicLatitude, Lighting.ExposureCompensation = O.GeographicLatitude, O.ExposureCompensation
	if chGui then pcall(function() chGui:Destroy() end) chGui = nil end
	if menuGui then pcall(function() menuGui:Destroy() end) menuGui = nil end
	if floatBtn then pcall(function() floatBtn:Destroy() end) floatBtn = nil end
end

------------------------------ GUI (shitaro 1:1) ------------------------------
local BG = C(11, 11, 15)
local SIDE = C(14, 14, 19)
local INSET = C(17, 17, 23)
local LINE = C(38, 38, 52)
local ACCENT = C(139, 92, 246)
local TXT = C(235, 235, 240)
local DIM = C(140, 140, 155)
local FAINT = C(90, 90, 105)

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then pcall(function() i[k] = v end) end
	end
	i.Parent = parent
	return i
end

local function guiParent()
	local ok, res = pcall(function() return gethui() end)
	if ok and typeof(res) == "Instance" then return res end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 then return core end
	return LP:FindFirstChildOfClass("PlayerGui")
end

menuGui = mk("ScreenGui", { Name = "WorldMenu", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent())

local main = mk("Frame", {
	Name = "Main", Size = UDim2.fromOffset(500, 372),
	Position = UDim2.new(0.5, -250, 0.5, -186),
	BackgroundColor3 = BG, BorderSizePixel = 0, Active = true,
}, menuGui)
mk("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
mk("UIStroke", { Color = LINE, Thickness = 1 }, main)

-- drag (top strip)
local dragZone = mk("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, main)
do
	local dragging, ds, dp = false, nil, nil
	dragZone.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true ds = inp.Position dp = main.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - ds
			main.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
		end
	end)
end

-- sidebar
local side = mk("Frame", {
	Size = UDim2.new(0, 122, 1, 0), BackgroundColor3 = SIDE, BorderSizePixel = 0,
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, 8) }, side)
mk("Frame", {
	Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0),
	BackgroundColor3 = SIDE, BorderSizePixel = 0,
}, side)
mk("TextLabel", {
	Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(1, 0, 0, 52),
	BackgroundTransparency = 1, Text = "S", Font = Enum.Font.GothamBlack, TextSize = 44,
	TextColor3 = C(240, 240, 245),
	ZIndex = 2,
}, side)

local tabHost = mk("ScrollingFrame", {
	Position = UDim2.new(0, 6, 0, 56), Size = UDim2.new(1, -6, 0, 236),
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
	ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
}, side)
mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, tabHost)

local unloadBtn = mk("TextButton", {
	Position = UDim2.new(0, 6, 0, 296), Size = UDim2.new(1, -12, 0, 22),
	BackgroundColor3 = C(55, 28, 38), BorderSizePixel = 0,
	Text = "unload", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TXT, ZIndex = 2,
}, side)
mk("UICorner", { CornerRadius = UDim.new(0, 5) }, unloadBtn)

-- profile bottom
local prof = mk("Frame", {
	Position = UDim2.new(0, 6, 0, 322), Size = UDim2.new(1, -12, 0, 42),
	BackgroundTransparency = 1, ZIndex = 2,
}, side)
local av = mk("ImageLabel", {
	Position = UDim2.new(0, 2, 0.5, -14), Size = UDim2.new(0, 28, 0, 28),
	BackgroundColor3 = C(40, 40, 55), BorderSizePixel = 0, Image = "",
}, prof)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
local dispName, userName = LP.DisplayName, "@" .. LP.Name
mk("TextLabel", {
	Position = UDim2.new(0, 34, 0, 6), Size = UDim2.new(1, -36, 0, 16),
	BackgroundTransparency = 1, Text = dispName, Font = Enum.Font.GothamBold, TextSize = 12,
	TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, prof)
mk("TextLabel", {
	Position = UDim2.new(0, 34, 0, 23), Size = UDim2.new(1, -36, 0, 13),
	BackgroundTransparency = 1, Text = userName, Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, prof)
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if ok and type(img) == "string" and #img > 0 then
		av.Image = img
	end
end)

-- content
local content = mk("Frame", {
	Position = UDim2.new(0, 122, 0, 0), Size = UDim2.new(1, -122, 1, 0),
	BackgroundTransparency = 1,
}, main)

-- search deco (top right)
mk("TextLabel", {
	Position = UDim2.new(1, -30, 0, 8), Size = UDim2.new(0, 22, 0, 22),
	BackgroundTransparency = 1, Text = "🔍", Font = Enum.Font.Gotham, TextSize = 13,
	TextColor3 = DIM, ZIndex = 5,
}, content)

-- constellation deco (behind controls)
do
	local segs = {
		{ x1 = 0.55, y1 = 0.10, x2 = 0.75, y2 = 0.05 },
		{ x1 = 0.75, y1 = 0.05, x2 = 0.95, y2 = 0.22 },
		{ x1 = 0.55, y1 = 0.10, x2 = 0.62, y2 = 0.35 },
		{ x1 = 0.62, y1 = 0.35, x2 = 0.95, y2 = 0.22 },
		{ x1 = 0.62, y1 = 0.35, x2 = 0.80, y2 = 0.55 },
		{ x1 = 0.95, y1 = 0.22, x2 = 0.80, y2 = 0.55 },
	}
	local cw = 378
	for _, s in ipairs(segs) do
		local x1, y1 = s.x1 * cw, s.y1 * 372
		local x2, y2 = s.x2 * cw, s.y2 * 372
		local mx, my = (x1 + x2) / 2, (y1 + y2) / 2
		local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
		local ang = math.deg(math.atan2(y2 - y1, x2 - x1))
		local ln = mk("Frame", {
			Position = UDim2.fromOffset(mx, my), AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(len, 1), Rotation = ang,
			BackgroundColor3 = C(120, 110, 160), BackgroundTransparency = 0.82,
			BorderSizePixel = 0, Active = false,
		}, content)
	end
end

local tabs, activeTab = {}, nil

local function makePage(name, icon, sub)
	local b = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = SIDE, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", ZIndex = 2,
	}, tabHost)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	mk("TextLabel", {
		Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0, 18, 1, 0),
		BackgroundTransparency = 1, Text = icon, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = DIM,
	}, b)
	mk("TextLabel", {
		Position = UDim2.new(0, 24, 0, 3), Size = UDim2.new(1, -26, 0, 16),
		BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	mk("TextLabel", {
		Position = UDim2.new(0, 24, 0, 19), Size = UDim2.new(1, -26, 0, 12),
		BackgroundTransparency = 1, Text = sub, Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = FAINT, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	local scroll = mk("ScrollingFrame", {
		Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -10, 1, -34),
		BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, content)
	local cols = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, scroll)
	local left = mk("Frame", {
		Size = UDim2.new(0.5, -5, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, cols)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, left)
	local right = mk("Frame", {
		Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 0, 0),
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
	}, cols)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, right)
	local page = { btn = b, scroll = scroll, left = left, right = right, name = name }
	b.MouseButton1Click:Connect(function()
		for _, t in pairs(tabs) do
			local on = t == page
			t.scroll.Visible = on
			t.btn.BackgroundColor3 = on and C(24, 24, 33) or SIDE
		end
		activeTab = page
	end)
	tabs[#tabs + 1] = page
	return page
end

local function Section(page, header, side_)
	CurSec = tostring((page and page.name) or "?") .. "." .. tostring(header)
	local col = (side_ == "right") and page.right or page.left
	local box = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, col)
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = header, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = TXT, TextXAlignment = Enum.TextXAlignment.Left,
	}, box)
	mk("Frame", {
		Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C(55, 55, 72), BorderSizePixel = 0,
	}, box)
	local body = mk("Frame", {
		Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
	}, box)
	mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	local pad = mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1 }, box)
	return body
end

-- config registry (auto flags: tab.section.control)
CurSec = ""
CFGREG = {}
function cfgSan(s)
	s = tostring(s or "")
	s = string.lower(s)
	s = string.gsub(s, "[^%w]+", "_")
	s = string.gsub(s, "^_+", "")
	s = string.gsub(s, "_+$", "")
	if s == "" then s = "x" end
	return s
end
function cfgReg(sec, name, handle)
	local base = cfgSan(sec) .. "." .. cfgSan(name)
	local flag = base
	local i = 2
	while CFGREG[flag] ~= nil do
		flag = base .. "_" .. i
		i = i + 1
	end
	handle.flag = flag
	CFGREG[flag] = handle
end

-- toggle row: [✓] name ......... [...]
MenuKey = Enum.KeyCode.Insert
MenuSnd = { on = false, tone = "Click" }
ShowBinds = true
RowBinds = {}
BindBtns = {}
captureBind = nil
SNDS = {
	Click = "rbxasset://sounds/button.wav",
	Tick = "rbxasset://sounds/electronicpingshort.wav",
	Slash = "rbxasset://sounds/swordslash.wav",
}
local function playSnd()
	if not MenuSnd.on then return end
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = SNDS[MenuSnd.tone] or SNDS.Click
		s.Volume = 0.6
		local par = nil
		pcall(function() par = game:GetService("CoreGui") end)
		s.Parent = par or workspace
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end
do
	local hooked = false
	local function hook()
		if hooked then return end
		hooked = true
		UIS.InputBegan:Connect(function(inp, gpe)
			if gpe then return end
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if captureBind then
				if inp.KeyCode == Enum.KeyCode.Escape then
					captureBind.entry.key = nil
					captureBind.btn.Text = "—"
					captureBind = nil
					return
				end
				local nm = inp.KeyCode.Name
				if nm and nm ~= "Unknown" then
					captureBind.entry.key = inp.KeyCode
					captureBind.btn.Text = nm
					captureBind = nil
					playSnd()
				end
				return
			end
			for _, e in ipairs(RowBinds) do
				if e.key and inp.KeyCode == e.key then
					pcall(e.flip)
				end
			end
		end)
	end
	hook()
end
local function TRow(parent, name, def, cb, hasOpt)
	local mySec = CurSec
	local st = def and true or false
	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
	}, parent)
	local box = mk("TextButton", {
		Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = st and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
	mk("UIStroke", { Color = st and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
	local mark = mk("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = st and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = C(255, 255, 255),
	}, box)
	local lab = mk("TextButton", {
		Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, hasOpt and -70 or -46, 1, 0),
		BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = st and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
	}, row)
	local dots = nil
	if hasOpt then
		dots = mk("TextButton", {
			Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 24, 1, 0),
			BackgroundTransparency = 1, Text = "...", Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = FAINT, AutoButtonColor = false,
		}, row)
	end
	local bindEntry = { key = nil, flip = nil }
	local bindBtn = mk("TextButton", {
		Position = hasOpt and UDim2.new(1, -68, 0, 0) or UDim2.new(1, -44, 0, 0),
		Size = UDim2.new(0, 40, 1, 0),
		BackgroundTransparency = 1, Text = "—", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = FAINT, AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	bindBtn.Visible = ShowBinds
	BindBtns[#BindBtns + 1] = bindBtn
	RowBinds[#RowBinds + 1] = bindEntry
	bindBtn.MouseButton1Click:Connect(function()
		captureBind = { entry = bindEntry, btn = bindBtn }
		bindBtn.Text = "..."
	end)
	local opt = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = INSET, BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y, Visible = false,
	}, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 5) }, opt)
	mk("UIPadding", {
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
	}, opt)
	mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, opt)
	local function refresh()
		box.BackgroundColor3 = st and ACCENT or C(30, 30, 40)
		mark.Text = st and "✓" or ""
		lab.TextColor3 = st and TXT or DIM
	end
	local function flip()
		st = not st
		refresh()
		pcall(cb, st)
		playSnd()
	end
	bindEntry.flip = flip
	cfgReg(mySec, name, {
		type = "toggle",
		get = function() return st and true or false end,
		set = function(v)
			v = (v and true) or false
			if v ~= st then flip() end
		end,
		bindGet = function() return bindEntry.key and bindEntry.key.Name or nil end,
		bindSet = function(kn)
			if type(kn) == "string" and kn ~= "" then
				local ok, kc = pcall(function() return Enum.KeyCode[kn] end)
				if ok and kc then
					bindEntry.key = kc
					bindBtn.Text = kn
					return
				end
			end
			bindEntry.key = nil
			bindBtn.Text = "—"
		end,
	})
	box.MouseButton1Click:Connect(flip)
	lab.MouseButton1Click:Connect(flip)
	if dots then
		dots.MouseButton1Click:Connect(function() opt.Visible = not opt.Visible end)
	end
	refresh()
	return opt
end

-- sub dropdown: name ..... value ▾ (cycles)
local function TDrop(parent, name, values, def, cb)
	local idx = 1
	for i, v in ipairs(values) do
		if v == def then idx = i break end
	end
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local b = mk("TextButton", {
		Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0),
		BackgroundTransparency = 1, Text = values[idx] .. "  ▾",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right, AutoButtonColor = false,
	}, row)
	b.MouseButton1Click:Connect(function()
		idx = idx % #values + 1
		b.Text = values[idx] .. "  ▾"
		pcall(cb, values[idx])
		playSnd()
	end)
	cfgReg(CurSec, name, {
		type = "drop",
		get = function() return values[idx] end,
		set = function(v)
			for i, x in ipairs(values) do
				if x == v then
					idx = i
					b.Text = v .. "  ▾"
					pcall(cb, v)
					return
				end
			end
		end,
	})
end

-- sub slider: name [value] + bar
local function TSlider(parent, name, min, max, def, dec, cb, noReg)
	dec = dec or 0
	local val = def
	local f = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(1, -44, 0, 16), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	local vlab = mk("TextLabel", {
		Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 0, 16),
		BackgroundTransparency = 1, Text = tostring(def),
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, f)
	local bar = mk("TextButton", {
		Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = C(45, 45, 60), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, f)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = mk("Frame", {
		Size = UDim2.new((def - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = ACCENT, BorderSizePixel = 0,
	}, bar)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local function fmt(v)
		if dec <= 0 then return tostring(math.floor(v + 0.5)) end
		local m = 10 ^ dec
		return tostring(math.floor(v * m + 0.5) / m)
	end
	local function apply(v)
		val = clamp(v, min, max)
		if dec <= 0 then val = math.floor(val + 0.5)
		else
			local m = 10 ^ dec
			val = math.floor(val * m + 0.5) / m
		end
		fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
		vlab.Text = fmt(val)
		pcall(cb, val)
	end
	local dragging = false
	bar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			apply(min + (inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max - min))
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			apply(min + (inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (max - min))
		end
	end)
	if not noReg then
		cfgReg(CurSec, name, {
			type = "slider",
			get = function() return val end,
			set = function(v) apply(tonumber(v) or val) end,
		})
	end
end

-- sub color: name + preview, click toggles RGB
local function TColor(parent, name, def, cb)
	local col = def
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local prev = mk("TextButton", {
		Position = UDim2.new(1, -32, 0.5, -8), Size = UDim2.new(0, 32, 0, 16),
		BackgroundColor3 = col, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, prev)
	mk("UIStroke", { Color = C(85, 85, 105), Thickness = 1 }, prev)
	local r, g, bb = math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)
	local host = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y, Visible = false,
	}, parent)
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, host)
	local function push()
		col = C(clamp(r, 0, 255), clamp(g, 0, 255), clamp(bb, 0, 255))
		prev.BackgroundColor3 = col
		pcall(cb, col)
	end
	TSlider(host, "R", 0, 255, r, 0, function(v) r = v push() end, true)
	TSlider(host, "G", 0, 255, g, 0, function(v) g = v push() end, true)
	TSlider(host, "B", 0, 255, bb, 0, function(v) bb = v push() end, true)
	prev.MouseButton1Click:Connect(function() host.Visible = not host.Visible end)
	cfgReg(CurSec, name, {
		type = "color",
		get = function() return { r = r, g = g, b = bb } end,
		set = function(v)
			if type(v) ~= "table" then return end
			r = clamp(math.floor((tonumber(v.r) or r) + 0.5), 0, 255)
			g = clamp(math.floor((tonumber(v.g) or g) + 0.5), 0, 255)
			bb = clamp(math.floor((tonumber(v.b) or bb) + 0.5), 0, 255)
			push()
		end,
	})
end

------------------------------ BUILD: TABS + WORLD ------------------------------
save_original_effects()
unloadBtn.MouseButton1Click:Connect(unloadAll)

pGame = makePage("game", "▶", "game.func")
pVis = makePage("visuals", "◉", "player.visuals")
pWorld = makePage("world", "⊕", "world.visuals")
pPlayer = makePage("player", "●", "local.player")
pAnim = makePage("animations", "♫", "custom.animations")
pEmote = makePage("emotes", "☺", "emote.library")
pTarget = makePage("target", "⌖", "target.list")
pMisc = makePage("misc", "⚙", "misc.other")

-- select world by default (only wired tab for now)
pWorld.btn.BackgroundColor3 = C(24, 24, 33)
pGame.btn.BackgroundColor3 = SIDE
for _, t in pairs(tabs) do t.scroll.Visible = false end
pWorld.scroll.Visible = true
activeTab = pWorld

do
	local sec = Section(pWorld, "aura", "left")
	local opt = TRow(sec, "aura", false, setAura, true)
	TDrop(opt, "type", AURA_ORDER, S.auraType, function(v)
		S.auraType = v
		if S.auraOn then task.spawn(apply_aura) end
	end)
	TColor(opt, "color", S.auraCol, function(c)
		S.auraCol = c
		for _, m in pairs(auraCache) do color_aura(m, c) end
		if S.auraOn then task.spawn(apply_aura) end
	end)
end

do
	local sec = Section(pWorld, "skybox", "right")
	local opt = TRow(sec, "skybox", false, setSky, true)
	TDrop(opt, "preset", SKY_LIST, "Jungle", function(v)
		S.skyName = v
		if S.skyOn then apply_skybox(v) end
	end)
end

do
	local sec = Section(pWorld, "shaders", "left")
	local opt = TRow(sec, "shaders", false, setShader, true)
	TDrop(opt, "preset", { "morning", "midday", "evening", "night" }, S.shaderType, function(v)
		S.shaderType = v
		if S.shaderOn then apply_shader(SHADERS[v]) end
	end)
end

do
	local sec = Section(pWorld, "crosshair", "left")
	local opt = TRow(sec, "crosshair", false, setCrosshair, true)
	TRow(opt, "hide original", false, function(v)
		CH.hideOrig = v
		if S.chOn then chHideCursor(chHasGun() and v) else chHideGameGui() end
		if not v then chShowGameGui() end
	end, false)
	TSlider(opt, "gap", 0, 20, CH.gap, 0, function(v) CH.gap = v end)
	TSlider(opt, "line", 2, 30, CH.len, 0, function(v) CH.len = v end)
	TSlider(opt, "thickness", 1, 5, CH.thick, 0, function(v) CH.thick = v end)
	TSlider(opt, "rotation", 0, 10, CH.rot, 0, function(v) CH.rot = v end)
	TColor(opt, "line color", CH.col, function(c) CH.col = c applyCrossColors() end)
	TColor(opt, "outline color", CH.out, function(c) CH.out = c applyCrossColors() end)
end

do
	local sec = Section(pWorld, "fullbright", "left")
	TRow(sec, "fullbright", false, setFullbright, false)
end

do
	local sec = Section(pWorld, "custom fog", "right")
	local opt = TRow(sec, "custom fog", false, setFog, true)
	TColor(opt, "color", S.fogColor, function(c)
		S.fogColor = c
		if S.fogOn then Lighting.FogColor = c end
	end)
	TSlider(opt, "start", 0, 1000, S.fogStart, 0, function(v)
		S.fogStart = v
		if S.fogOn then Lighting.FogStart = v end
	end)
	TSlider(opt, "end", 0, 1000, S.fogEnd, 0, function(v)
		S.fogEnd = v
		if S.fogOn then Lighting.FogEnd = v end
	end)
end

do
	local sec = Section(pWorld, "time changer", "right")
	local opt = TRow(sec, "time changer", false, setTime, true)
	TSlider(opt, "time", 0, 24, S.timeVal, 0, function(v)
		S.timeVal = v
		if S.timeOn then Lighting.ClockTime = v end
	end)
end

do
	local sec = Section(pWorld, "world effects", "right")
	local opt = TRow(sec, "world effects", false, setFx, true)
	TDrop(opt, "preset", { "Snow", "Sakura" }, S.fxType, function(v)
		S.fxType = v
		if S.fxOn then fxStyle(v) fxBurst() end
	end)
	TColor(opt, "color", S.fxColor, function(c)
		S.fxColor = c
		if fxEmitter then fxEmitter.Color = ColorSequence.new(c) end
	end)
	TSlider(opt, "range", 20, 900, S.fxRate, 0, function(v)
		S.fxRate = v
		if fxEmitter then fxStyle(S.fxType) fxBurst() end
	end)
end

do
	local sec = Section(pWorld, "ambient", "right")
	local opt = TRow(sec, "ambient", false, setAmbient, true)
	TColor(opt, "color", S.ambColor, function(c)
		S.ambColor = c
		if S.ambOn then
			Lighting.Ambient = c
			Lighting.OutdoorAmbient = c
		end
	end)
end

do
	local sec = Section(pWorld, "exposure", "right")
	local opt = TRow(sec, "exposure", false, setExposure, true)
	TSlider(opt, "range", -5, 5, S.expVal, 2, function(v)
		S.expVal = v
		if S.expOn then Lighting.ExposureCompensation = v end
	end)
end

-- show / hide
local shown = true
local function setShown(v)
	shown = v
	main.Visible = v
end

UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == MenuKey then
		setShown(not shown)
	end
end)

-- float button (mobile / mouse fallback)
floatBtn = mk("TextButton", {
	Name = "WorldFloat", Size = UDim2.new(0, 44, 0, 44),
	Position = UDim2.new(0, 12, 0.5, -22),
	BackgroundColor3 = C(17, 17, 24), BorderSizePixel = 0,
	Text = "S", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = TXT,
}, menuGui)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, floatBtn)
floatBtn.MouseButton1Click:Connect(function() setShown(not shown) end)
do
	local dragging, ds, dp = false, nil, nil
	floatBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true ds = inp.Position dp = floatBtn.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - ds
			floatBtn.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
		end
	end)
end

print("[world] loaded - Insert to hide/show")

------------------------------ LOCAL ENGINE ------------------------------
local HASDRAW = typeof(Drawing) == "table"
if not HASDRAW then
	print("[world] warning: Drawing API missing - crosshair/esp/graph/hat need executor with Drawing")
end

function initLocal()
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local stats = game:GetService("Stats")
	local tween = game:GetService("TweenService")
	local debris = game:GetService("Debris")
	local lp = players.LocalPlayer
	local ws = workspace

	local bt_on, sc_on, tc_on = false, false, false
	local bt_col = Color3.fromRGB(255, 60, 60)
	local sc_col = Color3.fromRGB(0, 200, 255)
	local tc_col = Color3.fromRGB(255, 200, 0)
	local sc_type, tc_type = "ForceField", "ForceField"
	local sc_flat, tc_flat = {}, {}
	local sc_surfs, tc_surfs = {}, {}
	local tc_roots = {}
	local sc_chrom, tc_chrom = {}, {}
	local chrom_view, chrom_world, chrom_conn
	local CHROM_SCALE, CHROM_ALPHA = 1.012, 0.025
	local bt_model = nil
	local BT_CAP = 256
	local bt_hist = table.create(BT_CAP)
	for i = 1, BT_CAP do bt_hist[i] = { 0, CFrame.identity } end
	local bt_first = 1
	local bt_count = 0
	local bt_ping = 0.15
	local bt_ping_at = 0
	local bt_pairs = {}
	local sc_cache, tc_cache = {}, {}
	local sc_surf = {}
	local tc_surf = {}
	local sc_parts = {}
	local sc_char = nil
	local sc_valid = false
	local sc_conns = {}
	local tc_parts = {}
	local tc_char = nil
	local tc_valid = false
	local tc_conns = {}
	local lc_on = false
	local lc_col = Color3.new(1, 1, 1)
	local lc_tr = 1
	local lc_dur = 0.82
	local lc_con = nil
	local ch_on = false
	local ch_col = Color3.fromRGB(170, 85, 255)

	local function bt_read_ping()
		return stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
	end

	local function bt_destroy()
		if bt_model then
			if _G.BACKTRACK_CLONES then _G.BACKTRACK_CLONES[bt_model] = nil end
			pcall(function() bt_model:Destroy() end)
			bt_model = nil
		end
		bt_pairs = {}
		bt_first = 1
		bt_count = 0
	end

	local function bt_build()
		bt_destroy()
		local char = lp.Character
		if not char then return end
		local rhrp = char:FindFirstChild("HumanoidRootPart")
		if not rhrp then return end
		char.Archivable = true
		local ok, m = pcall(function() return char:Clone() end)
		char.Archivable = false
		if not ok or not m then return end
		_G.BACKTRACK_CLONES = _G.BACKTRACK_CLONES or {}
		local rparts = {}
		for _, o in char:GetDescendants() do
			if o:IsA("BasePart") then rparts[#rparts + 1] = o end
		end
		local ci = 0
		for _, o in m:GetDescendants() do
			if o:IsA("Script") or o:IsA("LocalScript") then
				pcall(function() o:Destroy() end)
			elseif o:IsA("Decal") or o:IsA("Texture") or o:IsA("SurfaceAppearance") then
				pcall(function() o:Destroy() end)
			elseif o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
				pcall(function() o:Destroy() end)
			elseif o:IsA("BasePart") then
				o.Anchored = true
				o.CanCollide = false
				o.CanQuery = false
				o.Massless = true
				o.CastShadow = false
				if o.Name == "HumanoidRootPart" then
					o.Transparency = 1
				else
					o.Material = Enum.Material.ForceField
					o.Color = bt_col
					o.Transparency = 0
				end
				ci = ci + 1
				bt_pairs[#bt_pairs + 1] = {o, rparts[ci]}
			end
		end
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum:Destroy() end) end
		m.Parent = ws
		bt_model = m
		_G.BACKTRACK_CLONES[m] = true
	end

	local function bt_update()
		local char = lp.Character
		local rhrp = char and char:FindFirstChild("HumanoidRootPart")
		if not rhrp then return end
		if getgenv().FAKE_POS_ACTIVE then
			if bt_model and bt_model.Parent then bt_model.Parent = nil end
			return
		end
		if not bt_model then
			bt_build()
			if not bt_model then return end
		end
		if not bt_model.Parent then bt_model.Parent = ws end
		local now = os.clock()
		local base_cf = rhrp.CFrame
		if bt_count < BT_CAP then
			bt_count = bt_count + 1
		else
			bt_first = bt_first % BT_CAP + 1
		end
		local slot = bt_hist[(bt_first + bt_count - 2) % BT_CAP + 1]
		slot[1] = now
		slot[2] = base_cf
		if now - bt_ping_at >= 0.2 then
			bt_ping_at = now
			local ok, value = pcall(bt_read_ping)
			bt_ping = math.clamp((ok and value) or 0.15, 0.05, 0.6)
		end
		local ping = bt_ping
		local target = now - ping
		local cf = base_cf
		for k = bt_count, 1, -1 do
			local s = bt_hist[(bt_first + k - 2) % BT_CAP + 1]
			if s[1] <= target then
				cf = s[2]
				break
			end
		end
		while bt_count > 0 and bt_hist[bt_first][1] < now - 1 do
			bt_first = bt_first % BT_CAP + 1
			bt_count = bt_count - 1
		end
		local baseInv = rhrp.CFrame:Inverse()
		for i = 1, #bt_pairs do
			local cp, rp = bt_pairs[i][1], bt_pairs[i][2]
			if cp and cp.Parent and rp and rp.Parent then
				cp.CFrame = cf * (baseInv * rp.CFrame)
			end
		end
	end

	local function chrom_ensure()
		if chrom_world and chrom_world.Parent then return end
		local host = Instance.new("ScreenGui")
		host.Name = tostring(math.random(1e6, 9e6))
		host.ResetOnSpawn = false
		host.IgnoreGuiInset = true
		host.DisplayOrder = 100
		pcall(function() host.Parent = gethui and gethui() or game:GetService("CoreGui") end)
		chrom_view = Instance.new("ViewportFrame")
		chrom_view.Size = UDim2.fromScale(1, 1)
		chrom_view.BackgroundTransparency = 1
		chrom_view.BorderSizePixel = 0
		chrom_view.Ambient = Color3.new(1, 1, 1)
		chrom_view.LightColor = Color3.new(1, 1, 1)
		chrom_view.LightDirection = Vector3.new(-1, -1, -1)
		chrom_view.CurrentCamera = ws.CurrentCamera
		chrom_view.Parent = host
		local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
		if sky then pcall(function() sky:Clone().Parent = chrom_view end) end
		chrom_world = Instance.new("WorldModel")
		chrom_world.Parent = chrom_view
	end

	local CHAMS_BODY = {
		Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
		LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
		RightUpperArm = true, RightLowerArm = true, RightHand = true,
		LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
		RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
		["Left Arm"] = true, ["Right Arm"] = true,
		["Left Leg"] = true, ["Right Leg"] = true,
	}

	local function chams_deformable(p)
		if p:FindFirstChildWhichIsA("WrapLayer") then return true end
		if CHAMS_BODY[p.Name] then return false end
		if p:FindFirstChildWhichIsA("Bone") then return true end
		local ok, skinned = pcall(function() return p.HasSkinnedMesh end)
		return ok and skinned == true
	end

	local function chams_shell(source, scale)
		local archivable = source.Archivable
		if not archivable then
			if not pcall(function() source.Archivable = true end) then return nil end
		end
		local ok, clone = pcall(function() return source:Clone() end)
		if not archivable then
			pcall(function() source.Archivable = archivable end)
		end
		if not ok or not clone then return nil end
		for _, child in clone:GetChildren() do
			if not child:IsA("DataModelMesh") then child:Destroy() end
		end
		local mesh = clone:FindFirstChildWhichIsA("DataModelMesh")
		if mesh then
			pcall(function() mesh.Scale = mesh.Scale * scale end)
			pcall(function() mesh.TextureId = "" end)
		else
			clone.Size = clone.Size * scale
		end
		pcall(function() clone.TextureID = "" end)
		pcall(function() clone.MaterialVariant = "" end)
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		clone.CastShadow = false
		clone.LocalTransparencyModifier = 0
		return clone
	end

	local function flat_clear(state)
		if state.model then state.model:Destroy() end
		if state.occ then state.occ:Destroy() end
		if state.los then
			for i = 1, #state.los do state.los[i]:Destroy() end
		end
		state.model, state.occ, state.los, state.count, state.key = nil, nil, nil, nil, nil
	end

	local function flat_apply(state, parts, roots, col)
		local key = roots[1]
		if state.key ~= key or state.count ~= #parts or not state.model or not state.model.Parent then
			flat_clear(state)
			local model = Instance.new("Model")
			model.Name = "\0"
			for i = 1, #parts do
				local source = parts[i]
				local clone = not chams_deformable(source) and chams_shell(source, 0.99) or nil
				if clone then
					clone.Anchored = false
					clone.CFrame = source.CFrame
					clone.Parent = model
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = clone
					weld.Part1 = source
					weld.Parent = clone
				end
			end
			model.Parent = ws
			local occ = Instance.new("Highlight")
			occ.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			occ.OutlineTransparency = 1
			occ.Adornee = model
			occ.Parent = model
			local los = {}
			for i = 1, #roots do
				local hl = Instance.new("Highlight")
				hl.DepthMode = Enum.HighlightDepthMode.Occluded
				hl.OutlineTransparency = 1
				hl.Adornee = roots[i]
				hl.Parent = model
				los[i] = hl
			end
			state.model, state.occ, state.los = model, occ, los
			state.count, state.key = #parts, key
		end
		state.occ.FillColor = col
		state.occ.FillTransparency = 0
		for i = 1, #state.los do
			state.los[i].FillColor = col
			state.los[i].FillTransparency = 0
		end
	end

	local function chrom_clear(state)
		if state.model then state.model:Destroy() end
		state.model, state.entries, state.count, state.key, state.col = nil, nil, nil, nil, nil
	end

	local function chrom_apply(state, parts, key, col)
		if state.key ~= key or state.count ~= #parts or not state.model or not state.model.Parent then
			chrom_clear(state)
			chrom_ensure()
			local model = Instance.new("Model")
			model.Name = "\0"
			local entries = {}
			for i = 1, #parts do
				local source = parts[i]
				local clone = not chams_deformable(source) and chams_shell(source, CHROM_SCALE) or nil
				if clone then
					clone.Anchored = true
					clone.Material = Enum.Material.Foil
					clone.Reflectance = 0.12
					clone.Transparency = CHROM_ALPHA
					clone.Color = col
					clone.CFrame = source.CFrame
					clone.Parent = model
					entries[#entries + 1] = { source, clone }
				end
			end
			model.Parent = chrom_world
			state.model, state.entries = model, entries
			state.count, state.key, state.col = #parts, key, col
		elseif state.col ~= col then
			state.col = col
			local entries = state.entries
			if entries then
				for i = 1, #entries do
					entries[i][2].Color = col
				end
			end
		end
	end

	local function chrom_sync(state)
		local entries = state.entries
		if not entries then return end
		for i = 1, #entries do
			local source, clone = entries[i][1], entries[i][2]
			if source.Parent then
				clone.CFrame = source.CFrame
				local hidden = math.max(source.Transparency, source.LocalTransparencyModifier) >= 1
				local target_trans = hidden and 1 or CHROM_ALPHA
				if clone.Transparency ~= target_trans then
					clone.Transparency = target_trans
				end
			elseif clone.Transparency ~= 1 then
				clone.Transparency = 1
			end
		end
	end

	local function sc_restore()
		for part, d in pairs(sc_cache) do
			if part and part.Parent then
				part.Material = d[1]
				part.Color = d[2]
			end
		end
		sc_cache = {}
		for sa, par in pairs(sc_surf) do
			if sa then pcall(function() sa.Parent = par end) end
		end
		sc_surf = {}
		sc_valid = false
	end

	local function sc_detach(p)
		p.Parent = nil
	end

	local function sc_parts_for(char)
		if sc_char ~= char then
			sc_char = char
			sc_valid = false
			for i = 1, #sc_conns do
				pcall(function() sc_conns[i]:Disconnect() end)
			end
			table.clear(sc_conns)
			local function dirty()
				sc_valid = false
			end
			sc_conns[1] = char.DescendantAdded:Connect(dirty)
			sc_conns[2] = char.DescendantRemoving:Connect(dirty)
		end
		if not sc_valid then
			table.clear(sc_parts)
			table.clear(sc_surfs)
			local n, s = 0, 0
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					n = n + 1
					sc_parts[n] = p
				elseif p:IsA("SurfaceAppearance") then
					s = s + 1
					sc_surfs[s] = p
				end
			end
			sc_valid = true
		end
		return sc_parts
	end

	local function surfs_detach(list, store)
		for i = 1, #list do
			local sa = list[i]
			if sa.Parent and not store[sa] then
				store[sa] = sa.Parent
				pcall(sc_detach, sa)
			end
		end
	end

	local function sc_apply()
		local char = lp.Character
		if not char then return end
		local parts = sc_parts_for(char)
		if sc_type == "Flat" then
			chrom_clear(sc_chrom)
			if next(sc_cache) or next(sc_surf) then sc_restore() end
			flat_apply(sc_flat, parts, { char }, sc_col)
		elseif sc_type == "Chromatic" then
			flat_clear(sc_flat)
			if next(sc_cache) or next(sc_surf) then sc_restore() end
			chrom_apply(sc_chrom, parts, char, sc_col)
		else
			flat_clear(sc_flat)
			chrom_clear(sc_chrom)
			surfs_detach(sc_surfs, sc_surf)
			for i = 1, #parts do
				local p = parts[i]
				if p.Parent then
					if not sc_cache[p] then sc_cache[p] = {p.Material, p.Color} end
					p.Material = Enum.Material.ForceField
					p.Color = sc_col
				end
			end
		end
	end

	local function tc_restore()
		for part, d in pairs(tc_cache) do
			if part and part.Parent then
				part.Material = d[1]
				part.Color = d[2]
			end
		end
		tc_cache = {}
		for sa, par in pairs(tc_surf) do
			if sa then pcall(function() sa.Parent = par end) end
		end
		tc_surf = {}
		tc_valid = false
	end

	local function tc_parts_for(char)
		if tc_char ~= char then
			tc_char = char
			tc_valid = false
			for i = 1, #tc_conns do
				pcall(function() tc_conns[i]:Disconnect() end)
			end
			table.clear(tc_conns)
			local function dirty()
				tc_valid = false
			end
			tc_conns[1] = char.DescendantAdded:Connect(dirty)
			tc_conns[2] = char.DescendantRemoving:Connect(dirty)
		end
		if not tc_valid then
			table.clear(tc_parts)
			table.clear(tc_surfs)
			table.clear(tc_roots)
			local n, s, r = 0, 0, 0
			for _, t in char:GetChildren() do
				if t:IsA("Tool") then
					r = r + 1
					tc_roots[r] = t
					for _, p in t:GetDescendants() do
						if p:IsA("BasePart") then
							n = n + 1
							tc_parts[n] = p
						elseif p:IsA("SurfaceAppearance") then
							s = s + 1
							tc_surfs[s] = p
						end
					end
				end
			end
			tc_valid = true
		end
		return tc_parts
	end

	local function tc_apply()
		local char = lp.Character
		if not char then return end
		local parts = tc_parts_for(char)
		if #parts == 0 then
			flat_clear(tc_flat)
			chrom_clear(tc_chrom)
			if next(tc_cache) or next(tc_surf) then tc_restore() end
			return
		end
		if tc_type == "Flat" then
			chrom_clear(tc_chrom)
			if next(tc_cache) or next(tc_surf) then tc_restore() end
			flat_apply(tc_flat, parts, tc_roots, tc_col)
		elseif tc_type == "Chromatic" then
			flat_clear(tc_flat)
			if next(tc_cache) or next(tc_surf) then tc_restore() end
			chrom_apply(tc_chrom, parts, tc_roots[1], tc_col)
		else
			flat_clear(tc_flat)
			chrom_clear(tc_chrom)
			surfs_detach(tc_surfs, tc_surf)
			for i = 1, #parts do
				local p = parts[i]
				if p.Parent then
					if not tc_cache[p] then tc_cache[p] = {p.Material, p.Color} end
					p.Material = Enum.Material.ForceField
					p.Color = tc_col
				end
			end
		end
	end

	local function lc_hit(char, root)
		local prm = RaycastParams.new()
		prm.FilterType = Enum.RaycastFilterType.Exclude
		prm.FilterDescendantsInstances = {char}
		prm.IgnoreWater = true
		local sum, nor, cnt = Vector3.zero, Vector3.zero, 0
		for _, name in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}) do
			local foot = char:FindFirstChild(name)
			if foot and foot:IsA("BasePart") then
				local hit = ws:Raycast(foot.Position + Vector3.new(0, 0.35, 0), Vector3.new(0, -7, 0), prm)
				if hit then
					sum = sum + hit.Position
					nor = nor + hit.Normal
					cnt = cnt + 1
				end
			end
		end
		if cnt > 0 then return sum/cnt, nor.Unit end
		local hit = ws:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -16, 0), prm)
		if hit then return hit.Position, hit.Normal end
	end

	local function lc_make(p, n)
		local ref = math.abs(n.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis
		local right = n:Cross(ref).Unit
		local front = right:Cross(n).Unit
		local part = Instance.new("Part")
		part.Name = "LandingCircle"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.new(0.3, 0.01, 0.3)
		part.CFrame = CFrame.fromMatrix(p + n*0.012, right, n, front)
		part.Parent = ws
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.AlwaysOnTop = true
		sg.LightInfluence = 0
		sg.ZOffset = 4
		sg.CanvasSize = Vector2.new(1024, 1024)
		sg.Parent = part
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = "rbxassetid://7185003058"
		img.ImageColor3 = lc_col
		img.ImageTransparency = 1 - lc_tr
		img.ScaleType = Enum.ScaleType.Stretch
		img.Parent = sg
		local info = TweenInfo.new(lc_dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween:Create(part, info, {Size = Vector3.new(6.4, 0.01, 6.4)}):Play()
		tween:Create(img, info, {ImageTransparency = 1}):Play()
		debris:AddItem(part, lc_dur + 0.2)
	end

	local function lc_bind()
		if lc_con then pcall(function() lc_con:Disconnect() end) lc_con = nil end
		if not lc_on then return end
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		local air = false
		lc_con = hum.StateChanged:Connect(function(_, state)
			if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
				air = true
				return
			end
			if state == Enum.HumanoidStateType.Landed and air and lc_on then
				air = false
				local p, n = lc_hit(char, root)
				if p and n then lc_make(p, n) end
			end
		end)
	end

	local mg_on = false
	local mg_color = Color3.fromRGB(242, 242, 242)
	local mg_width = 280
	local mg_height = 72
	local mg_offset = 180
	local mg_thickness = 1
	local mg_span = 2.8
	local mg_step = 1 / 45
	local mg_accum = 0
	local mg_smooth = 0
	local mg_history = {}
	local mg_lines = {}
	local mg_shadows = {}
	local mg_labels = {}
	local mg_current = nil
	local mg_conn = nil

	local function mg_remove(obj)
		if obj then pcall(function() obj:Remove() end) end
	end

	local function mg_speed()
		local char = lp.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return 0 end
		local velocity = root.AssemblyLinearVelocity
		return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end

	local function mg_reference()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return math.max(1, hum and hum.WalkSpeed or 16)
	end

	local function mg_new_line(color, thickness, zindex, transparency)
		local line = Drawing.new("Line")
		line.Color = color
		line.Thickness = thickness
		line.Transparency = transparency
		line.ZIndex = zindex
		line.Visible = false
		return line
	end

	local function mg_new_text()
		local text = Drawing.new("Text")
		text.Center = true
		text.Outline = true
		text.Color = mg_color
		text.Size = 12
		text.ZIndex = 904
		text.Visible = false
		return text
	end

	local function mg_sync_pool(needed)
		while #mg_lines < needed do
			mg_shadows[#mg_shadows + 1] = mg_new_line(Color3.new(0, 0, 0), mg_thickness + 2, 901, 0.45)
			mg_lines[#mg_lines + 1] = mg_new_line(mg_color, mg_thickness, 902, 1)
		end
		while #mg_lines > needed do
			mg_remove(table.remove(mg_lines))
			mg_remove(table.remove(mg_shadows))
		end
	end

	local function mg_create()
		if mg_current then return end
		mg_current = mg_new_text()
		mg_current.Center = false
		for i = 1, 6 do
			mg_labels[i] = mg_new_text()
		end
	end

	local function mg_hide()
		if mg_current then mg_current.Visible = false end
		for i = 1, #mg_lines do
			mg_lines[i].Visible = false
			mg_shadows[i].Visible = false
		end
		for i = 1, #mg_labels do
			mg_labels[i].Visible = false
		end
	end

	local function mg_clear()
		if mg_conn then
			pcall(function() mg_conn:Disconnect() end)
			mg_conn = nil
		end
		mg_remove(mg_current)
		mg_current = nil
		for i = 1, #mg_lines do
			mg_remove(mg_lines[i])
			mg_remove(mg_shadows[i])
		end
		for i = 1, #mg_labels do
			mg_remove(mg_labels[i])
		end
		table.clear(mg_lines)
		table.clear(mg_shadows)
		table.clear(mg_labels)
		table.clear(mg_history)
		mg_accum = 0
	end

	local function mg_reset_history()
		table.clear(mg_history)
		local now = os.clock()
		local speed = mg_speed()
		mg_smooth = speed
		local count = math.ceil(mg_span / mg_step)
		for i = 0, count do
			mg_history[#mg_history + 1] = {
				t = now - mg_span + i * mg_step,
				v = speed
			}
		end
		mg_sync_pool(#mg_history)
	end

	local function mg_apply_style()
		if mg_current then mg_current.Color = mg_color end
		for i = 1, #mg_lines do
			mg_lines[i].Color = mg_color
			mg_lines[i].Thickness = mg_thickness
			mg_shadows[i].Thickness = mg_thickness + 2
		end
		for i = 1, #mg_labels do
			mg_labels[i].Color = mg_color
		end
	end

	local function mg_y(value, center, height, reference)
		local normalized = math.clamp(value / reference - 1, -1, 1)
		return center - normalized * height * 0.44
	end

	local function mg_render(now)
		local camera = ws.CurrentCamera
		if not mg_on or not camera or #mg_history < 2 then
			mg_hide()
			return
		end
		local viewport = camera.ViewportSize
		local width = math.min(mg_width, math.max(120, viewport.X - 48))
		local height = math.min(mg_height, math.max(36, viewport.Y - 32))
		local left = math.floor(viewport.X * 0.5 - width * 0.5)
		local center = math.clamp(math.floor(viewport.Y * 0.5 + mg_offset), height * 0.5 + 8, viewport.Y - height * 0.5 - 8)
		local reference = mg_reference()
		local start_time = now - mg_span
		local count = #mg_history
		mg_sync_pool(count)
		for i = 1, count - 1 do
			local a = mg_history[i]
			local b = mg_history[i + 1]
			local ap = math.clamp((a.t - start_time) / mg_span, 0, 1)
			local bp = math.clamp((b.t - start_time) / mg_span, 0, 1)
			local fade = math.clamp(math.min((ap + bp) * 6, (2 - ap - bp) * 5), 0, 1)
			local from = Vector2.new(left + ap * width, mg_y(a.v, center, height, reference))
			local to = Vector2.new(left + bp * width, mg_y(b.v, center, height, reference))
			local line = mg_lines[i]
			local shadow = mg_shadows[i]
			line.From, line.To = from, to
			line.Transparency = fade
			line.Visible = fade > 0.02
			shadow.From, shadow.To = from, to
			shadow.Transparency = fade * 0.42
			shadow.Visible = fade > 0.02
		end
		local last = mg_history[count]
		local lpct = math.clamp((last.t - start_time) / mg_span, 0, 1)
		local from = Vector2.new(left + lpct * width, mg_y(last.v, center, height, reference))
		local to = Vector2.new(left + width, mg_y(mg_smooth, center, height, reference))
		local tail = mg_lines[count]
		local tail_shadow = mg_shadows[count]
		tail.From, tail.To = from, to
		tail.Transparency = 0.72
		tail.Visible = true
		tail_shadow.From, tail_shadow.To = from, to
		tail_shadow.Transparency = 0.3
		tail_shadow.Visible = true
		for i = count + 1, #mg_lines do
			mg_lines[i].Visible = false
			mg_shadows[i].Visible = false
		end
		mg_current.Text = tostring(math.floor(mg_smooth + 0.5))
		mg_current.Position = Vector2.new(left + width + 5, to.Y - 7)
		mg_current.Color = mg_color
		mg_current.Visible = true
		while #mg_labels < 12 do
			mg_labels[#mg_labels + 1] = mg_new_text()
		end
		local threshold = math.max(0.8, reference * 0.08)
		local min_label_gap = 0.42
		for i = 5, count - 4 do
			local point = mg_history[i]
			if not point.checked then
				point.checked = true
				local before = point.v - mg_history[i - 4].v
				local after = mg_history[i + 4].v - point.v
				if math.abs(before) >= threshold and (before * after <= 0 or math.abs(after) < threshold * 0.35) then
					local nearby = nil
					for j = i - 1, 1, -1 do
						local previous = mg_history[j]
						if point.t - previous.t > min_label_gap then break end
						if previous.label ~= nil then
							nearby = previous
							break
						end
					end
					local score = math.abs(before) - math.abs(after)
					if not nearby then
						point.label = math.floor(point.v + 0.5)
						point.label_score = score
					elseif score > (nearby.label_score or -math.huge) then
						nearby.label = nil
						nearby.label_score = nil
						point.label = math.floor(point.v + 0.5)
						point.label_score = score
					end
				end
			end
		end
		for i = 1, #mg_labels do
			mg_labels[i].Visible = false
		end
		local placed = {}
		local label_count = 0
		for i = count, 1, -1 do
			local point = mg_history[i]
			if point.label ~= nil and label_count < #mg_labels then
				local pct = (point.t - start_time) / mg_span
				if pct > 0.04 and pct < 0.82 then
					local value = tostring(point.label)
					local x = left + pct * width
					local y = mg_y(point.v, center, height, reference) - 15
					local half_width = math.max(8, #value * 3.5 + 2)
					local blocked = false
					for j = 1, #placed do
						local other = placed[j]
						if x + half_width + 5 > other.x1 and x - half_width - 5 < other.x2 and y + 13 > other.y1 and y - 3 < other.y2 then
							blocked = true
							break
						end
					end
					if not blocked then
						label_count = label_count + 1
						local text = mg_labels[label_count]
						text.Text = value
						text.Position = Vector2.new(x, y)
						text.Color = mg_color
						text.Visible = true
						placed[#placed + 1] = {
							x1 = x - half_width,
							x2 = x + half_width,
							y1 = y - 3,
							y2 = y + 13
						}
					end
				end
			end
		end
	end

	local function mg_start()
		mg_clear()
		mg_create()
		mg_reset_history()
		mg_apply_style()
		mg_conn = run.RenderStepped:Connect(function(dt)
			if not mg_on then
				mg_hide()
				return
			end
			local raw = mg_speed()
			mg_smooth = mg_smooth + (raw - mg_smooth) * (1 - math.exp(-dt * 18))
			mg_accum = mg_accum + dt
			local now = os.clock()
			if mg_accum >= mg_step then
				mg_accum = mg_accum % mg_step
				mg_history[#mg_history + 1] = { t = now, v = mg_smooth }
				local cutoff = now - mg_span
				while #mg_history > 2 and mg_history[2].t < cutoff do
					table.remove(mg_history, 1)
				end
			end
			mg_render(now)
		end)
	end

	local CH_RADIUS, CH_HEIGHT, CH_DROP = 1.55, 0.82, 0.02
	local CH_SEGMENTS = 48
	local CH_TAU = math.pi * 2
	local CH_ALPHA = 0.72
	local CH_MAX_ROWS = 220

	local ch = {
		rows = {},
		px = table.create(CH_SEGMENTS + 1),
		py = table.create(CH_SEGMENTS + 1),
		cos = table.create(CH_SEGMENTS),
		sin = table.create(CH_SEGMENTS),
		ord = table.create(CH_SEGMENTS + 1),
		stack = table.create(CH_SEGMENTS + 2),
		shown = {},
		cpos = {},
		csize = {},
		ccol = {},
		white = Color3.new(1, 1, 1),
		black = Color3.new(0, 0, 0),
		eps = 0.75,
	}

	for i = 1, CH_SEGMENTS do
		local angle = (i - 1) / CH_SEGMENTS * CH_TAU
		ch.cos[i] = math.cos(angle) * CH_RADIUS
		ch.sin[i] = math.sin(angle) * CH_RADIUS
	end

	ch.order = function(i, j)
		local px, py = ch.px, ch.py
		local ax, bx = px[i], px[j]
		return ax == bx and py[i] < py[j] or ax < bx
	end

	ch.hull = function(n)
		local px, py, ord, st = ch.px, ch.py, ch.ord, ch.stack
		for i = 1, n do ord[i] = i end
		table.sort(ord, ch.order)
		local m = 0
		for k = 1, n do
			local i = ord[k]
			local x, y = px[i], py[i]
			while m >= 2 do
				local o, a = st[m - 1], st[m]
				local ox, oy = px[o], py[o]
				if (px[a] - ox) * (y - oy) - (py[a] - oy) * (x - ox) > 0 then break end
				m = m - 1
			end
			m = m + 1
			st[m] = i
		end
		local lower = m
		for k = n - 1, 1, -1 do
			local i = ord[k]
			local x, y = px[i], py[i]
			while m > lower do
				local o, a = st[m - 1], st[m]
				local ox, oy = px[o], py[o]
				if (px[a] - ox) * (y - oy) - (py[a] - oy) * (x - ox) > 0 then break end
				m = m - 1
			end
			m = m + 1
			st[m] = i
		end
		return m - 1
	end

	ch.visible = function(state)
		local rows, shown = ch.rows, ch.shown
		for i = 1, #rows do
			if shown[i] ~= state then
				rows[i].Visible = state
				shown[i] = state
			end
		end
	end

	ch.clear = function()
		local rows = ch.rows
		for i = 1, #rows do
			pcall(function() rows[i]:Remove() end)
		end
		table.clear(rows)
		table.clear(ch.shown)
		table.clear(ch.cpos)
		table.clear(ch.csize)
		table.clear(ch.ccol)
		ch.head, ch.pos, ch.cf = nil, nil, nil
		ch.fov, ch.vx, ch.vy, ch.col = nil, nil, nil, nil
	end

	ch.build = function()
		ch.clear()
	end

	ch.row = function(index)
		local rows = ch.rows
		local row = rows[index]
		if row then return row end
		row = Drawing.new("Square")
		row.Filled = true
		row.Thickness = 0
		row.Transparency = CH_ALPHA
		row.Visible = false
		row.ZIndex = 1
		rows[index] = row
		ch.shown[index] = false
		return row
	end

	ch.update = function(camera)
		local char = lp.Character
		local head = char and char:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") or not camera then
			ch.visible(false)
			return
		end
		local headPos = head.Position
		local camCF = camera.CFrame
		local fov = camera.FieldOfView
		local view = camera.ViewportSize
		local viewX, viewY = view.X, view.Y
		if ch.head == head and ch.pos == headPos and ch.cf == camCF
			and ch.fov == fov and ch.vx == viewX and ch.vy == viewY and ch.col == ch_col then
			return
		end
		ch.head, ch.pos, ch.cf = head, headPos, camCF
		ch.fov, ch.vx, ch.vy, ch.col = fov, viewX, viewY, ch_col
		local px, py, cosT, sinT = ch.px, ch.py, ch.cos, ch.sin
		local baseY = headPos.Y + head.Size.Y * 0.5 - CH_DROP
		local center = Vector3.new(headPos.X, baseY, headPos.Z)
		local apex = camera:WorldToViewportPoint(center + Vector3.new(0, CH_HEIGHT, 0))
		if apex.Z <= 0 then
			ch.visible(false)
			return
		end
		local probe = camera:WorldToViewportPoint(center + Vector3.new(cosT[1], 0, sinT[1]))
		if probe.Z <= 0 then
			ch.visible(false)
			return
		end
		px[1], py[1] = apex.X, apex.Y
		px[2], py[2] = probe.X, probe.Y
		local camPos = camCF.Position
		local rv, uv, lv = camCF.RightVector, camCF.UpVector, camCF.LookVector
		local ox, oy, oz = center.X - camPos.X, center.Y - camPos.Y, center.Z - camPos.Z
		local baseR = ox * rv.X + oy * rv.Y + oz * rv.Z
		local baseU = ox * uv.X + oy * uv.Y + oz * uv.Z
		local baseD = ox * lv.X + oy * lv.Y + oz * lv.Z
		local rvx, rvz, uvx, uvz, lvx, lvz = rv.X, rv.Z, uv.X, uv.Z, lv.X, lv.Z
		local scale = viewY * 0.5 / math.tan(math.rad(fov * 0.5))
		local midX, midY = viewX * 0.5, viewY * 0.5
		local eps = ch.eps
		local exact = false
		local dep = baseD + CH_HEIGHT * lv.Y
		if dep > 0 then
			local inv = scale / dep
			if math.abs(midX + (baseR + CH_HEIGHT * rv.Y) * inv - apex.X) <= eps
				and math.abs(midY - (baseU + CH_HEIGHT * uv.Y) * inv - apex.Y) <= eps then
				local c, s = cosT[1], sinT[1]
				dep = baseD + c * lvx + s * lvz
				if dep > 0 then
					inv = scale / dep
					if math.abs(midX + (baseR + c * rvx + s * rvz) * inv - probe.X) <= eps
						and math.abs(midY - (baseU + c * uvx + s * uvz) * inv - probe.Y) <= eps then
						exact = true
					end
				end
			end
		end
		if exact then
			for i = 2, CH_SEGMENTS do
				local c, s = cosT[i], sinT[i]
				local d = baseD + c * lvx + s * lvz
				if d <= 0 then
					ch.visible(false)
					return
				end
				local inv = scale / d
				px[i + 1] = midX + (baseR + c * rvx + s * rvz) * inv
				py[i + 1] = midY - (baseU + c * uvx + s * uvz) * inv
			end
		else
			for i = 2, CH_SEGMENTS do
				local point = camera:WorldToViewportPoint(center + Vector3.new(cosT[i], 0, sinT[i]))
				if point.Z <= 0 then
					ch.visible(false)
					return
				end
				px[i + 1] = point.X
				py[i + 1] = point.Y
			end
		end
		local hn = ch.hull(CH_SEGMENTS + 1)
		if hn < 3 then
			ch.visible(false)
			return
		end
		local st = ch.stack
		local minY, maxY = math.huge, -math.huge
		for i = 1, hn do
			local y = py[st[i]]
			if y < minY then minY = y end
			if y > maxY then maxY = y end
		end
		local firstY = math.max(0, math.floor(minY))
		local lastY = math.min(viewY, math.ceil(maxY))
		if lastY - firstY < 2 then
			ch.visible(false)
			return
		end
		local step = math.max(1, math.ceil((lastY - firstY) / CH_MAX_ROWS))
		local span = math.max(1, maxY - minY)
		local rows, shown = ch.rows, ch.shown
		local cpos, csize, ccol = ch.cpos, ch.csize, ch.ccol
		local white, black = ch.white, ch.black
		local used = 0
		for y0 = firstY, lastY - 1, step do
			local height = math.min(step, lastY - y0)
			local y = y0 + height * 0.5
			local left, right = math.huge, -math.huge
			local ax, ay = px[st[hn]], py[st[hn]]
			for i = 1, hn do
				local ix = st[i]
				local bx, by = px[ix], py[ix]
				if (ay <= y and by > y) or (by <= y and ay > y) then
					local x = ax + (y - ay) * (bx - ax) / (by - ay)
					if x < left then left = x end
					if x > right then right = x end
				end
				ax, ay = bx, by
			end
			local width = right - left
			if width >= 2.5 then
				used = used + 1
				local row = ch.row(used)
				local t = (y - minY) / span
				local light = 1 - t * 1.35
				local dark = (t - 0.58) / 0.42
				if light < 0 then light = 0 end
				if dark < 0 then dark = 0 end
				local color = ch_col:Lerp(white, light * 0.26):Lerp(black, dark * 0.1)
				local pos = Vector2.new(left, y0)
				local size = Vector2.new(width, height)
				if cpos[used] ~= pos then
					row.Position = pos
					cpos[used] = pos
				end
				if csize[used] ~= size then
					row.Size = size
					csize[used] = size
				end
				if ccol[used] ~= color then
					row.Color = color
					ccol[used] = color
				end
				if not shown[used] then
					row.Visible = true
					shown[used] = true
				end
			end
		end
		for i = used + 1, #rows do
			if shown[i] then
				rows[i].Visible = false
				shown[i] = false
			end
		end
	end

	local vis_conn = run.Heartbeat:Connect(function()
		if bt_on then bt_update() end
		if sc_on then sc_apply() end
		if tc_on then tc_apply() end
	end)

	chrom_conn = run.RenderStepped:Connect(function()
		local cam = ws.CurrentCamera
		if ch_on then ch.update(cam) end
		if not chrom_world then return end
		if chrom_view.CurrentCamera ~= cam then chrom_view.CurrentCamera = cam end
		if sc_on and sc_type == "Chromatic" then chrom_sync(sc_chrom) end
		if tc_on and tc_type == "Chromatic" then chrom_sync(tc_chrom) end
	end)

	local char_conn = lp.CharacterAdded:Connect(function()
		task.wait(0.4)
		if bt_on then bt_build() end
		if lc_on then lc_bind() end
		if mg_on then mg_reset_history() end
	end)

	local function local_unload()
		bt_on, sc_on, tc_on, lc_on, mg_on, ch_on = false, false, false, false, false, false
		mg_clear()
		pcall(ch.clear)
		if vis_conn then
			pcall(function() vis_conn:Disconnect() end)
			vis_conn = nil
		end
		if char_conn then
			pcall(function() char_conn:Disconnect() end)
			char_conn = nil
		end
		if lc_con then
			pcall(function() lc_con:Disconnect() end)
			lc_con = nil
		end
		for i = 1, #sc_conns do
			pcall(function() sc_conns[i]:Disconnect() end)
		end
		table.clear(sc_conns)
		for i = 1, #tc_conns do
			pcall(function() tc_conns[i]:Disconnect() end)
		end
		table.clear(tc_conns)
		sc_char, tc_char = nil, nil
		sc_valid, tc_valid = false, false
		if chrom_conn then
			pcall(function() chrom_conn:Disconnect() end)
			chrom_conn = nil
		end
		pcall(function() flat_clear(sc_flat) end)
		pcall(function() flat_clear(tc_flat) end)
		pcall(function() chrom_clear(sc_chrom) end)
		pcall(function() chrom_clear(tc_chrom) end)
		if chrom_view then
			pcall(function() chrom_view.Parent:Destroy() end)
			chrom_view, chrom_world = nil, nil
		end
		pcall(sc_restore)
		pcall(tc_restore)
		pcall(bt_destroy)
	end

	-- public setters for GUI chunk
	getgenv().LX = {}
	local LX = getgenv().LX
	function LX.setChina(on)
		ch_on = on
		if on then
			if HASDRAW then ch.build() end
		else
			ch.clear()
		end
	end
	function LX.setChinaCol(c) ch_col = c end
	function LX.getChinaCol() return ch_col end
	function LX.setBt(on)
		bt_on = on
		if on then
			if not bt_model then bt_build() end
		else
			bt_destroy()
		end
	end
	function LX.setBtCol(c)
		bt_col = c
		if bt_model then
			for _, p in bt_model:GetDescendants() do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = c end
			end
		end
	end
	function LX.getBtCol() return bt_col end
	function LX.setSc(on)
		sc_on = on
		if not on then
			flat_clear(sc_flat)
			chrom_clear(sc_chrom)
			sc_restore()
		end
	end
	function LX.setScType(v) sc_type = v end
	function LX.setScCol(c) sc_col = c end
	function LX.getScCol() return sc_col end
	function LX.setTc(on)
		tc_on = on
		if not on then
			flat_clear(tc_flat)
			chrom_clear(tc_chrom)
			tc_restore()
		end
	end
	function LX.setTcType(v) tc_type = v end
	function LX.setTcCol(c) tc_col = c end
	function LX.getTcCol() return tc_col end
	function LX.setLc(on)
		lc_on = on
		if on then
			lc_bind()
		elseif lc_con then
			lc_con:Disconnect()
			lc_con = nil
		end
	end
	function LX.setLcCol(c) lc_col = c end
	function LX.getLcCol() return lc_col end
	function LX.setLcTr(v) lc_tr = v end
	function LX.setLcDur(v) lc_dur = v end
	function LX.setMg(on)
		mg_on = on
		if on then
			if HASDRAW then mg_start() end
		else
			mg_clear()
		end
	end
	function LX.setMgCol(c)
		mg_color = c
		mg_apply_style()
	end
	function LX.getMgCol() return mg_color end
	function LX.setMgW(v) mg_width = v end
	function LX.setMgH(v) mg_height = v end
	function LX.setMgY(v) mg_offset = v end
	function LX.unload() local_unload() end
	-- shared chams helpers for ESP material chams
	LX.flat_apply = flat_apply
	LX.flat_clear = flat_clear
	LX.chrom_apply = chrom_apply
	LX.chrom_clear = chrom_clear
	LX.chrom_sync = chrom_sync
	LX.chrom_ensure = chrom_ensure
	LX.deformable = chams_deformable
	LX.shell = chams_shell
end
do
print("[world] init initLocal...")
local ok, err = pcall(initLocal)
print("[world] init initLocal " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end
------------------------------ BUILD: LOCAL ------------------------------
do
	local LX = getgenv().LX
	local function needDraw()
		if not HASDRAW then
			print("[world] Drawing API missing - this needs executor with Drawing")
			return false
		end
		return true
	end

	do
		local sec = Section(pPlayer, "china hat", "left")
		local opt = TRow(sec, "china hat", false, function(v)
			if v and not needDraw() then return end
			LX.setChina(v)
		end, true)
		TColor(opt, "color", LX.getChinaCol(), function(c) LX.setChinaCol(c) end)
	end

	do
		local sec = Section(pPlayer, "backtrack", "right")
		local opt = TRow(sec, "backtrack", false, function(v) LX.setBt(v) end, true)
		TColor(opt, "color", LX.getBtCol(), function(c) LX.setBtCol(c) end)
	end

	do
		local sec = Section(pPlayer, "self chams", "left")
		local opt = TRow(sec, "self chams", false, function(v) LX.setSc(v) end, true)
		TDrop(opt, "preset", { "ForceField", "Flat", "Chromatic" }, "ForceField", function(v) LX.setScType(v) end)
		TColor(opt, "color", LX.getScCol(), function(c) LX.setScCol(c) end)
	end

	do
		local sec = Section(pPlayer, "tool chams", "left")
		local opt = TRow(sec, "tool chams", false, function(v) LX.setTc(v) end, true)
		TDrop(opt, "preset", { "ForceField", "Flat", "Chromatic" }, "ForceField", function(v) LX.setTcType(v) end)
		TColor(opt, "color", LX.getTcCol(), function(c) LX.setTcCol(c) end)
	end

	do
		local sec = Section(pPlayer, "landing circle", "right")
		local opt = TRow(sec, "landing circle", false, function(v) LX.setLc(v) end, true)
		TColor(opt, "color", LX.getLcCol(), function(c) LX.setLcCol(c) end)
		TSlider(opt, "transp", 0, 1, 1, 2, function(v) LX.setLcTr(v) end)
		TSlider(opt, "duration", 0.1, 3, 0.82, 2, function(v) LX.setLcDur(v) end)
	end

	do
		local sec = Section(pPlayer, "mov graph", "right")
		local opt = TRow(sec, "mov graph", false, function(v)
			if v and not needDraw() then return end
			LX.setMg(v)
		end, true)
		TColor(opt, "color", LX.getMgCol(), function(c) LX.setMgCol(c) end)
		TSlider(opt, "width", 180, 420, 280, 0, function(v) LX.setMgW(v) end)
		TSlider(opt, "height", 40, 120, 72, 0, function(v) LX.setMgH(v) end)
		TSlider(opt, "y", -200, 400, 180, 0, function(v) LX.setMgY(v) end)
	end

	unloadBtn.MouseButton1Click:Connect(function() LX.unload() end)
end
------------------------------ ESP ENGINE (native) ------------------------------
function initESP()
	local ePlayers = game:GetService("Players")
	local eRS = game:GetService("RunService")
	local eRep = game:GetService("ReplicatedStorage")
	local eLP = ePlayers.LocalPlayer

	local E = {
		on = false, allowlocal = false,
		box = { on = false, col = { Color3.new(1, 0, 0), 1 }, type = "Static",
			grd = false, g1 = Color3.new(1, 0, 0), g2 = Color3.new(0, 0, 1),
			fill = false, fcol = { Color3.new(1, 0, 0), 0.5 },
			fgrd = false, fg1 = Color3.new(1, 0, 0), fg2 = Color3.new(0, 0, 1) },
		name = { on = false, col = { Color3.new(1, 1, 1), 1 },
			grd = false, g1 = Color3.new(1, 1, 1), g2 = Color3.new(1, 0, 0) },
		avatar = { on = false },
		arrows = { on = false, mur = { Color3.fromRGB(255, 60, 60), 1 },
			inno = { Color3.new(1, 1, 1), 1 }, shf = { Color3.fromRGB(0, 153, 255), 1 },
			size = 42, dis = 260 },
		dist = { on = false, col = { Color3.new(1, 1, 1), 1 },
			grd = false, g1 = Color3.new(1, 1, 1), g2 = Color3.new(1, 0, 0) },
		skel = { on = false, col = { Color3.new(1, 1, 1), 1 } },
		chams = { on = false,
			murF = { Color3.new(1, 0, 0), 0.5 }, murO = { Color3.new(1, 0, 0), 0 },
			innoF = { Color3.new(1, 1, 1), 0.5 }, innoO = { Color3.new(1, 1, 1), 0 },
			shfF = { Color3.fromRGB(0, 153, 255), 0.5 }, shfO = { Color3.fromRGB(0, 153, 255), 0 } },
		matchams = { on = false, type = "ForceField",
			mur = Color3.new(1, 0, 0), inno = Color3.new(1, 1, 1), shf = Color3.fromRGB(0, 153, 255),
			visMur = { Color3.new(1, 0, 0), 0 }, occMur = { Color3.new(0, 0, 1), 0 },
			visInno = { Color3.new(1, 1, 1), 0 }, occInno = { Color3.fromRGB(77, 77, 77), 0 },
			visShf = { Color3.fromRGB(0, 153, 255), 0 }, occShf = { Color3.new(0, 0, 1), 0 } },
		flags = { on = false, mur = { Color3.new(1, 0, 0), 1 },
			murGrd = false, murG1 = Color3.new(1, 0, 0), murG2 = Color3.fromRGB(255, 128, 0),
			shf = { Color3.fromRGB(0, 153, 255), 1 },
			shfGrd = false, shfG1 = Color3.fromRGB(0, 153, 255), shfG2 = Color3.fromRGB(0, 255, 255) },
		gun = { on = false, text = false, textCol = Color3.new(1, 1, 1),
			textGrd = false, g1 = Color3.new(1, 1, 1), g2 = Color3.new(1, 0, 0),
			hl = false, hlCol = Color3.new(1, 1, 1) },
	}
	getgenv().EXS = E
	local updateChams

	-- Drawing helpers (nil-safe)
	local function D(kind, props)
		if not HASDRAW then return nil end
		local ok, o = pcall(Drawing.new, kind)
		if not ok or not o then return nil end
		if props then
			for k, v in pairs(props) do
				pcall(function() o[k] = v end)
			end
		end
		return o
	end
	local function DSET(o, k, v)
		if o then pcall(function() o[k] = v end) end
	end
	local function DSHOW(o, v)
		if o then pcall(function() o.Visible = v and true or false end) end
	end
	local function DREM(o)
		if o then pcall(function() o:Remove() end) end
	end
	local function hlParent()
		local ok, res = pcall(function() return gethui() end)
		if ok and typeof(res) == "Instance" then return res end
		local ok2, core = pcall(function() return game:GetService("CoreGui") end)
		if ok2 then return core end
		return eLP:FindFirstChildOfClass("PlayerGui")
	end
	local function HL(props)
		local ok, o = pcall(Instance.new, "Highlight")
		if not ok then return nil end
		for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
		o.Parent = hlParent()
		return o
	end

	-- roles (MM2)
	local roundMod = nil
	local roles = {}
	local function getRound()
		local ok, m = pcall(function()
			return require(eRep:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
		end)
		if ok and type(m) == "table" then roundMod = m end
		return roundMod
	end
	local function refreshRoles()
		roles = {}
		local m = getRound()
		local data = m and m.PlayerData
		if type(data) ~= "table" then return end
		for name, d in pairs(data) do
			if type(d) == "table" then
				local r = d.Role
				if r == "Hero" then r = "Sheriff" end
				roles[name] = { role = r, dead = d.Dead and true or false }
			end
		end
	end
	local function hasGun(char, plr)
		if char and char:FindFirstChild("Gun") then return true end
		local bp = plr:FindFirstChildOfClass("Backpack")
		if bp and bp:FindFirstChild("Gun") then return true end
		return false
	end
	local function roleOf(plr, char)
		local r = roles[plr.Name]
		local role = (r and r.role) or "Innocent"
		local dead = r and r.dead or false
		if role ~= "Murderer" and hasGun(char, plr) then role = "Sheriff" end
		return role, dead
	end
	local function roleCol(role)
		if role == "Murderer" then return Color3.fromRGB(255, 60, 60) end
		if role == "Sheriff" then return Color3.fromRGB(0, 153, 255) end
		return Color3.new(1, 1, 1)
	end

	-- per-player entries
	local entries = {}
	local function newEntry(plr)
		local e = { plr = plr, char = nil, thumb = nil,
			boxOut = D("Square", { Thickness = 2, Filled = false, Transparency = 1, Color = Color3.new(0, 0, 0), Visible = false, ZIndex = 2 }),
			boxMain = D("Square", { Thickness = 1, Filled = false, Transparency = 1, Visible = false, ZIndex = 3 }),
			boxFill = D("Square", { Thickness = 1, Filled = true, Visible = false, ZIndex = 1 }),
			grad = {}, corners = {}, cornersO = {},
			nameT = D("Text", { Size = 13, Center = true, Outline = true, Visible = false, ZIndex = 5 }),
			nameG = {},
			distT = D("Text", { Size = 13, Center = true, Outline = true, Visible = false, ZIndex = 5 }),
			distG = {},
			flagT = D("Text", { Size = 12, Center = false, Outline = true, Visible = false, ZIndex = 5 }),
			flagG = {},
			skel = {}, skelO = {},
			triO = D("Triangle", { Thickness = 1, Filled = true, Visible = false, ZIndex = 6, Color = Color3.new(0, 0, 0), Transparency = 1 }),
			tri = D("Triangle", { Thickness = 1, Filled = true, Visible = false, ZIndex = 7 }),
			hlGlow = nil, hlVis = nil, hlOcc = nil,
			chrom = {}, paint = {}, paintChar = nil,
			avImg = nil,
		}
		entries[plr] = e
		return e
	end
	local function gradPool(e, key, n, size)
		local pool = e[key]
		while #pool < n do
			pool[#pool + 1] = D("Text", { Size = size or 13, Center = false, Outline = true, Visible = false, ZIndex = 5 })
		end
		return pool
	end
	local function hidePool(pool)
		for i = 1, #pool do DSHOW(pool[i], false) end
	end
	local function gradText(e, key, str, cx, y, size, c1, c2)
		local n = #str
		if n == 0 then hidePool(e[key]) return end
		local pool = gradPool(e, key, n, size)
		local widths = {}
		local total = 0
		for i = 1, n do
			local o = pool[i]
			local ch = string.sub(str, i, i)
			if o then
				DSET(o, "Text", ch)
				local wb = 6
				pcall(function() wb = o.TextBounds.X end)
				widths[i] = wb
				total = total + wb
			else
				widths[i] = 6
				total = total + 6
			end
		end
		local x = cx - total * 0.5
		for i = 1, n do
			local o = pool[i]
			if o then
				DSET(o, "Color", c1:Lerp(c2, n > 1 and (i - 1) / (n - 1) or 0))
				DSET(o, "Position", Vector2.new(x, y))
				DSHOW(o, true)
			end
			x = x + widths[i]
		end
		for i = n + 1, #pool do DSHOW(pool[i], false) end
	end
	local function plainText(o, str, x, y, col, tr)
		if not o then return end
		DSET(o, "Text", str)
		DSET(o, "Position", Vector2.new(x, y))
		DSET(o, "Color", col)
		DSET(o, "Transparency", tr == nil and 1 or tr)
		DSHOW(o, true)
	end
	local function hideEntry(e)
		DSHOW(e.boxOut, false) DSHOW(e.boxMain, false) DSHOW(e.boxFill, false)
		hidePool(e.grad) hidePool(e.corners) hidePool(e.cornersO)
		DSHOW(e.nameT, false) hidePool(e.nameG)
		DSHOW(e.distT, false) hidePool(e.distG)
		DSHOW(e.flagT, false) hidePool(e.flagG)
		hidePool(e.skel) hidePool(e.skelO)
		DSHOW(e.tri, false) DSHOW(e.triO, false)
		if e.avImg then pcall(function() e.avImg.Visible = false end) end
	end

	-- avatar overlay gui
	local avGui = nil
	local function avParent()
		return hlParent()
	end
	local function avGet(e)
		if e.avImg and e.avImg.Parent then return e.avImg end
		if not avGui or not avGui.Parent then
			avGui = Instance.new("ScreenGui")
			avGui.Name = "EspAv"
			avGui.ResetOnSpawn = false
			avGui.IgnoreGuiInset = true
			avGui.DisplayOrder = 500
			avGui.Parent = avParent()
		end
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.BorderSizePixel = 0
		img.Size = UDim2.fromOffset(18, 18)
		img.Visible = false
		img.Parent = avGui
		e.avImg = img
		if not e.thumb then
			task.spawn(function()
				local ok, url = pcall(function()
					return ePlayers:GetUserThumbnailAsync(e.plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok and type(url) == "string" then e.thumb = url end
			end)
		end
		return img
	end

	local SKEL_R15 = {
		{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
	}
	local SKEL_R6 = {
		{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
		{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
	}

	local function skelLine(e, i, a, b, col, tr)
		local l = e.skel[i]
		if not l then
			l = D("Line", { Thickness = 1, Visible = false, ZIndex = 4 })
			e.skel[i] = l
		end
		local o = e.skelO[i]
		if not o then
			o = D("Line", { Thickness = 3, Visible = false, ZIndex = 3, Color = Color3.new(0, 0, 0), Transparency = 0.6 })
			e.skelO[i] = o
		end
		if o then DSET(o, "From", a) DSET(o, "To", b) DSHOW(o, true) end
		if l then
			DSET(l, "From", a) DSET(l, "To", b)
			DSET(l, "Color", col) DSET(l, "Transparency", tr)
			DSHOW(l, true)
		end
	end

	local function cornerLine(e, i, a, b, col, tr)
		local o = e.cornersO[i]
		if not o then
			o = D("Line", { Thickness = 3, Visible = false, ZIndex = 2, Color = Color3.new(0, 0, 0), Transparency = 1 })
			e.cornersO[i] = o
		end
		local l = e.corners[i]
		if not l then
			l = D("Line", { Thickness = 1, Visible = false, ZIndex = 3 })
			e.corners[i] = l
		end
		if o then DSET(o, "From", a) DSET(o, "To", b) DSHOW(o, true) end
		if l then
			DSET(l, "From", a) DSET(l, "To", b)
			DSET(l, "Color", col) DSET(l, "Transparency", tr)
			DSHOW(l, true)
		end
	end

	local function boxGradRow(e, i, x, y, w, col)
		local r = e.grad[i]
		if not r then
			r = D("Square", { Thickness = 1, Filled = true, Visible = false, ZIndex = 3 })
			e.grad[i] = r
		end
		if r then
			DSET(r, "Position", Vector2.new(x, y))
			DSET(r, "Size", Vector2.new(w, 3))
			DSET(r, "Color", col)
			DSET(r, "Transparency", 1)
			DSHOW(r, true)
		end
	end

	local function updatePlayer(e, cam, vp)
		local plr = e.plr
		if plr == eLP and not E.allowlocal then hideEntry(e) return end
		local char = plr.Character
		if not char or not char.Parent then hideEntry(e) return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then hideEntry(e) return end
		e.char = char
		local role, dead = roleOf(plr, char)
		if dead then hideEntry(e) return end

		local head = char:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then hideEntry(e) return end
		local top3 = head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.25, 0)
		local bot3 = nil
		for _, fn in ipairs({ "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" }) do
			local f = char:FindFirstChild(fn)
			if f and f:IsA("BasePart") then
				local y = f.Position.Y - f.Size.Y * 0.5
				if not bot3 or y < bot3.Y then bot3 = Vector3.new(f.Position.X, y, f.Position.Z) end
			end
		end
		if not bot3 then bot3 = hrp.Position - Vector3.new(0, 3, 0) end
		local t2 = cam:WorldToViewportPoint(top3)
		local b2 = cam:WorldToViewportPoint(bot3)
		if t2.Z <= 0 or b2.Z <= 0 then hideEntry(e) return end
		local vsx, vsy = vp.X, vp.Y
		local function cl(v, a, b)
			if v ~= v then return a end
			if v < a then return a end
			if v > b then return b end
			return v
		end
		local tx = cl(t2.X, -500, vsx + 500)
		local ty = cl(t2.Y, -500, vsy + 500)
		local bx = cl(b2.X, -500, vsx + 500)
		local by = cl(b2.Y, -500, vsy + 500)
		local h = math.abs(by - ty)
		if h < 4 or h > vsy * 3 then hideEntry(e) return end
		local w = h * 0.62
		local cx = (tx + bx) * 0.5
		local x0, y0 = cx - w / 2, ty
		local dist = (cam.CFrame.Position - hrp.Position).Magnitude

		-- BOX
		local B = E.box
		if E.on and B.on then
			local col, tr = B.col[1], B.col[2]
			if B.fill then
				if B.fgrd then
					DSHOW(e.boxFill, false)
					local rows = math.max(1, math.floor(h / 3))
					for i = 1, rows do
						local fcol = B.fg1:Lerp(B.fg2, (i - 1) / math.max(1, rows - 1))
						boxGradRow(e, 1000 + i, x0, y0 + (i - 1) * 3, w, fcol)
						local rr = e.grad[1000 + i]
						if rr then DSET(rr, "Transparency", 1 - (B.fcol[2] or 0.5)) end
					end
					for i = rows + 1, 200 do
						local rr = e.grad[1000 + i]
						if not rr then break end
						DSHOW(rr, false)
					end
				else
					for i = 1, 200 do
						local rr = e.grad[1000 + i]
						if not rr then break end
						DSHOW(rr, false)
					end
					DSET(e.boxFill, "Position", Vector2.new(x0, y0))
					DSET(e.boxFill, "Size", Vector2.new(w, h))
					DSET(e.boxFill, "Color", B.fcol[1])
					DSET(e.boxFill, "Transparency", B.fcol[2])
					DSHOW(e.boxFill, true)
				end
			else
				DSHOW(e.boxFill, false)
				for i = 1, 200 do
					local rr = e.grad[1000 + i]
					if not rr then break end
					DSHOW(rr, false)
				end
			end
			if B.grd then
				DSHOW(e.boxMain, false) DSHOW(e.boxOut, false)
				hidePool(e.corners) hidePool(e.cornersO)
				local rows = math.max(1, math.floor(h / 3))
				for i = 1, rows do
					boxGradRow(e, i, x0, y0 + (i - 1) * 3, w, B.g1:Lerp(B.g2, (i - 1) / math.max(1, rows - 1)))
				end
				for i = rows + 1, #e.grad do
					if i < 1000 then DSHOW(e.grad[i], false) end
				end
			else
				for i = 1, #e.grad do
					if i < 1000 then DSHOW(e.grad[i], false) end
				end
				if B.type == "Corners" then
					DSHOW(e.boxMain, false) DSHOW(e.boxOut, false)
					local L = math.min(w, h) * 0.28
					local pts = {
						{ Vector2.new(x0, y0), Vector2.new(x0 + L, y0), Vector2.new(x0, y0 + L) },
						{ Vector2.new(x0 + w, y0), Vector2.new(x0 + w - L, y0), Vector2.new(x0 + w, y0 + L) },
						{ Vector2.new(x0, y0 + h), Vector2.new(x0 + L, y0 + h), Vector2.new(x0, y0 + h - L) },
						{ Vector2.new(x0 + w, y0 + h), Vector2.new(x0 + w - L, y0 + h), Vector2.new(x0 + w, y0 + h - L) },
					}
					local li = 0
					for c = 1, 4 do
						local p0, p1, p2 = pts[c][1], pts[c][2], pts[c][3]
						li = li + 1 cornerLine(e, li, p0, p1, col, tr)
						li = li + 1 cornerLine(e, li, p0, p2, col, tr)
					end
					for i = li + 1, #e.corners do DSHOW(e.corners[i], false) DSHOW(e.cornersO[i], false) end
				else
					hidePool(e.corners) hidePool(e.cornersO)
					DSET(e.boxOut, "Position", Vector2.new(x0 - 1, y0 - 1))
					DSET(e.boxOut, "Size", Vector2.new(w + 2, h + 2))
					DSHOW(e.boxOut, true)
					DSET(e.boxMain, "Position", Vector2.new(x0, y0))
					DSET(e.boxMain, "Size", Vector2.new(w, h))
					DSET(e.boxMain, "Color", col)
					DSET(e.boxMain, "Transparency", tr)
					DSHOW(e.boxMain, true)
				end
			end
		else
			DSHOW(e.boxOut, false) DSHOW(e.boxMain, false) DSHOW(e.boxFill, false)
			hidePool(e.grad) hidePool(e.corners) hidePool(e.cornersO)
		end

		-- NAME (+avatar)
		local N = E.name
		if E.on and N.on then
			local ny = y0 - 16
			if N.grd then
				DSHOW(e.nameT, false)
				gradText(e, "nameG", plr.DisplayName, cx, ny, 13, N.g1, N.g2)
			else
				hidePool(e.nameG)
				plainText(e.nameT, plr.DisplayName, cx, ny, N.col[1], N.col[2])
			end

		else
			DSHOW(e.nameT, false) hidePool(e.nameG)
		end

		-- AVATAR
		if E.on and E.avatar.on then
			local img = avGet(e)
			if img then
				if e.thumb then img.Image = e.thumb end
				img.Position = UDim2.fromOffset(math.floor(x0 - 22), math.floor(y0 - 9))
				img.Visible = true
			end
		elseif e.avImg then
			pcall(function() e.avImg.Visible = false end)
		end

		-- DISTANCE
		local Dd = E.dist
		if E.on and Dd.on then
			local s = tostring(math.floor(dist + 0.5)) .. "m"
			if Dd.grd then
				DSHOW(e.distT, false)
				gradText(e, "distG", s, cx, y0 + h + 2, 13, Dd.g1, Dd.g2)
			else
				hidePool(e.distG)
				plainText(e.distT, s, cx, y0 + h + 2, Dd.col[1], Dd.col[2])
			end
		else
			DSHOW(e.distT, false) hidePool(e.distG)
		end

		-- SKELETON
		local Sk = E.skel
		if E.on and Sk.on then
			local rig = hum.RigType == Enum.HumanoidRigType.R15 and SKEL_R15 or SKEL_R6
			local si = 0
			for _, pr in ipairs(rig) do
				local a = char:FindFirstChild(pr[1])
				local b = char:FindFirstChild(pr[2])
				if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
					local pa = cam:WorldToViewportPoint(a.Position)
					local pb = cam:WorldToViewportPoint(b.Position)
					if pa.Z > 0 and pb.Z > 0 then
						si = si + 1
						skelLine(e, si, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), Sk.col[1], Sk.col[2])
					end
				end
			end
			for i = si + 1, #e.skel do DSHOW(e.skel[i], false) DSHOW(e.skelO[i], false) end
		else
			hidePool(e.skel) hidePool(e.skelO)
		end

		-- FLAGS (murder / sheriff)
		local F = E.flags
		if E.on and F.on and (role == "Murderer" or role == "Sheriff") then
			local isMur = role == "Murderer"
			local txt = isMur and "MURDERER" or "SHERIFF"
			local fx = x0 - 4
			if isMur then
				if F.murGrd then
					DSHOW(e.flagT, false)
					gradText(e, "flagG", txt, fx - 30, y0, 12, F.murG1, F.murG2)
				else
					hidePool(e.flagG)
					DSET(e.flagT, "Text", txt)
					local wpx = 60
					pcall(function() wpx = e.flagT.TextBounds.X end)
					DSET(e.flagT, "Position", Vector2.new(fx - wpx, y0))
					DSET(e.flagT, "Color", F.mur[1])
					DSET(e.flagT, "Transparency", F.mur[2])
					DSHOW(e.flagT, true)
				end
			else
				if F.shfGrd then
					DSHOW(e.flagT, false)
					gradText(e, "flagG", txt, fx - 30, y0, 12, F.shfG1, F.shfG2)
				else
					hidePool(e.flagG)
					DSET(e.flagT, "Text", txt)
					local wpx = 60
					pcall(function() wpx = e.flagT.TextBounds.X end)
					DSET(e.flagT, "Position", Vector2.new(fx - wpx, y0))
					DSET(e.flagT, "Color", F.shf[1])
					DSET(e.flagT, "Transparency", F.shf[2])
					DSHOW(e.flagT, true)
				end
			end
		else
			DSHOW(e.flagT, false) hidePool(e.flagG)
		end

		-- ARROWS
		local A = E.arrows
		local sp = Vector2.new(cx, y0 + h / 2)
		local onscreen = sp.X > -50 and sp.X < vp.X + 50 and sp.Y > -50 and sp.Y < vp.Y + 50
		if E.on and A.on and not onscreen then
			local acol = role == "Murderer" and A.mur[1] or (role == "Sheriff" and A.shf[1] or A.inno[1])
			local ctr = Vector2.new(vp.X / 2, vp.Y / 2)
			local d = sp - ctr
			local m = d.Magnitude
			if m < 1 then m = 1 end
			local dir = d / m
			local c = ctr + dir * A.dis
			local ang = math.atan2(dir.Y, dir.X)
			local sz = A.size
			local tip = c + dir * (sz * 0.5)
			local base = c - dir * (sz * 0.5)
			local px, py = -dir.Y, dir.X
			local b1 = base + Vector2.new(px, py) * (sz * 0.42)
			local b2 = base - Vector2.new(px, py) * (sz * 0.42)
			DSET(e.triO, "PointA", tip) DSET(e.triO, "PointB", b1) DSET(e.triO, "PointC", b2)
			DSHOW(e.triO, true)
			DSET(e.tri, "PointA", tip) DSET(e.tri, "PointB", b1) DSET(e.tri, "PointC", b2)
			DSET(e.tri, "Color", acol) DSET(e.tri, "Transparency", 1)
			DSHOW(e.tri, true)
		else
			DSHOW(e.tri, false) DSHOW(e.triO, false)
		end

		updateChams(e, char, role)
	end

	-- paint (ForceField) helpers per char
	local function paintClear(e)
		e.paintCol = nil
		for part, d in pairs(e.paint) do
			if part and part.Parent then
				part.Material = d[1]
				part.Color = d[2]
			end
		end
		e.paint = {}
		e.paintChar = nil
	end
	local function paintApply(e, char, col)
		if e.paintChar ~= char then paintClear(e) e.paintChar = char end
		if e.paintCol == col and next(e.paint) ~= nil then return end
		e.paintCol = col
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				if not e.paint[p] then e.paint[p] = { p.Material, p.Color } end
				if p.Parent then
					if p.Material ~= Enum.Material.ForceField then p.Material = Enum.Material.ForceField end
					if p.Color ~= col then p.Color = col end
				end
			end
		end
	end
	local function matParts(char)
		local out = {}
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				out[#out + 1] = p
			end
		end
		return out
	end
	local function hlSet(e, key, depth, col, tr, adornee)
		local o = e[key]
		if not o or not o.Parent then
			if o then pcall(function() o:Destroy() end) end
			o = HL({ DepthMode = depth, OutlineTransparency = 1 })
			e[key] = o
		end
		if o then
			DSET(o, "Adornee", adornee)
			DSET(o, "FillColor", col)
			DSET(o, "FillTransparency", tr)
			DSET(o, "Enabled", true)
		end
		return o
	end
	local function hlOff(e, key)
		local o = e[key]
		if o then DSET(o, "Enabled", false) end
	end

	updateChams = function(e, char, role)
		local LX = getgenv().LX
		-- GLOW
		local G = E.chams
		if E.on and G.on then
			local f, o
			if role == "Murderer" then f, o = G.murF, G.murO
			elseif role == "Sheriff" then f, o = G.shfF, G.shfO
			else f, o = G.innoF, G.innoO end
			local h = e.hlGlow
			if not h or not h.Parent then
				if h then pcall(function() h:Destroy() end) end
				h = HL({ DepthMode = Enum.HighlightDepthMode.Occluded })
				e.hlGlow = h
			end
			if h then
				DSET(h, "Adornee", char)
				DSET(h, "FillColor", f[1]) DSET(h, "FillTransparency", f[2])
				DSET(h, "OutlineColor", o[1]) DSET(h, "OutlineTransparency", o[2])
				DSET(h, "Enabled", true)
			end
		elseif e.hlGlow then
			DSET(e.hlGlow, "Enabled", false)
		end
		-- MATERIAL
		local M = E.matchams
		if E.on and M.on then
			local base, vis, occ
			if role == "Murderer" then base, vis, occ = M.mur, M.visMur, M.occMur
			elseif role == "Sheriff" then base, vis, occ = M.shf, M.visShf, M.occShf
			else base, vis, occ = M.inno, M.visInno, M.occInno end
			if M.type == "ForceField" then
				if e.hlVis then DSET(e.hlVis, "Enabled", false) end
				if e.hlOcc then DSET(e.hlOcc, "Enabled", false) end
				if e.chrom then LX.chrom_clear(e.chrom) end
				paintApply(e, char, base)
			elseif M.type == "Flat" then
				paintClear(e)
				if e.chrom then LX.chrom_clear(e.chrom) end
				hlSet(e, "hlOcc", Enum.HighlightDepthMode.AlwaysOnTop, occ[1], occ[2], char)
				hlSet(e, "hlVis", Enum.HighlightDepthMode.Occluded, vis[1], vis[2], char)
			else
				paintClear(e)
				hlOff(e, "hlVis") hlOff(e, "hlOcc")
				if not e.chrom then e.chrom = {} end
				LX.chrom_apply(e.chrom, matParts(char), char, base)
				LX.chrom_sync(e.chrom)
			end
		else
			paintClear(e)
			hlOff(e, "hlVis") hlOff(e, "hlOcc")
			if e.hlGlow then DSET(e.hlGlow, "Enabled", false) end
			if e.chrom and LX then LX.chrom_clear(e.chrom) end
		end
	end

	-- GUN ESP (port)
	local G = E.gun
	local gun_cache = {}
	local gun_parts = {}
	local gun_scan_acc = 0
	local gun_candidates = {}
	local gun_render_conn, gun_added_conn, gun_removing_conn = nil, nil, nil
	local function gun_grad(p)
		return G.g1:Lerp(G.g2, math.sin(p * 3.1416 + os.clock() * 2) * 0.5 + 0.5)
	end
	local function in_character(obj)
		local node = obj.Parent
		while node and node ~= workspace do
			if node:IsA("Model") and ePlayers:GetPlayerFromCharacter(node) then
				return true
			end
			node = node.Parent
		end
		return false
	end
	local function render_part(obj)
		if obj:IsA("BasePart") then return obj end
		if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true) end
		return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	local function gun_candidate_added(obj)
		if obj.Name ~= "GunDrop" then return end
		if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool") then
			gun_candidates[obj] = true
		end
	end
	local function gun_candidate_removing(obj)
		if obj.Name ~= "GunDrop" then return end
		gun_candidates[obj] = nil
	end
	local function seed_gun_candidates()
		table.clear(gun_candidates)
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj.Name == "GunDrop" and (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool")) then
				gun_candidates[obj] = true
			end
		end
	end
	local function collect_guns()
		local list = {}
		for obj in pairs(gun_candidates) do
			if obj.Name == "GunDrop" and obj.Parent and not in_character(obj) then
				local part = render_part(obj)
				if part then
					local adorn = (obj:IsA("BasePart") or obj:IsA("Model")) and obj or part
					list[#list + 1] = { obj = obj, part = part, adorn = adorn }
				end
			end
		end
		return list
	end
	local function clear_gun(obj)
		local en = gun_cache[obj]
		if en then
			if en.hl then pcall(function() en.hl:Destroy() end) end
			if en.txt then DREM(en.txt) end
			if en.gtxt then
				for i = 1, #en.gtxt do DREM(en.gtxt[i]) end
			end
			gun_cache[obj] = nil
		end
	end
	local function clear_guns()
		for obj in pairs(gun_cache) do clear_gun(obj) end
		gun_parts = {}
	end
	local function gun_render(dt)
		if not G.on then
			if next(gun_cache) then clear_guns() end
			return
		end
		gun_scan_acc = gun_scan_acc + dt
		if gun_scan_acc >= 0.25 then
			gun_scan_acc = 0
			gun_parts = collect_guns()
			local set = {}
			for _, entry in ipairs(gun_parts) do set[entry.obj] = true end
			for obj in pairs(gun_cache) do
				if not set[obj] then clear_gun(obj) end
			end
		end
		local cam = workspace.CurrentCamera
		for _, entry in ipairs(gun_parts) do
			local obj = entry.obj
			local part = entry.part
			if obj.Parent and part and part.Parent then
				local en = gun_cache[obj]
				if not en then en = {} gun_cache[obj] = en end
				if G.hl then
					if not en.hl or not en.hl.Parent then
						if en.hl then pcall(function() en.hl:Destroy() end) end
						en.hl = HL({ FillTransparency = 1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
					end
					if en.hl then
						DSET(en.hl, "Adornee", entry.adorn)
						DSET(en.hl, "OutlineColor", G.hlCol)
						DSET(en.hl, "OutlineTransparency", 0)
						DSET(en.hl, "Enabled", true)
					end
				elseif en.hl then
					DSET(en.hl, "Enabled", false)
				end
				if G.text then
					local sp = cam:WorldToViewportPoint(part.Position)
					if G.textGrd then
						if en.txt then DSHOW(en.txt, false) end
						if sp.Z > 0 then
							local pool = en.gtxt
							if not pool then pool = {} en.gtxt = pool end
							local chars = { "G", "u", "n" }
							local widths = {}
							local total = 0
							for i = 1, 3 do
								local o = pool[i]
								if not o then
									o = D("Text", { Center = false, Outline = true, Size = 13 })
									pool[i] = o
								end
								if o then
									DSET(o, "Text", chars[i])
									local wb = 7
									pcall(function() wb = o.TextBounds.X end)
									widths[i] = wb
									total = total + wb
								end
							end
							local x = sp.X - total * 0.5
							for i = 1, 3 do
								local o = pool[i]
								if o then
									DSET(o, "Color", gun_grad((i - 1) / 2))
									DSET(o, "Position", Vector2.new(x, sp.Y))
									DSHOW(o, true)
								end
								x = x + (widths[i] or 7)
							end
						elseif en.gtxt then
							for i = 1, #en.gtxt do DSHOW(en.gtxt[i], false) end
						end
					else
						if en.gtxt then
							for i = 1, #en.gtxt do DSHOW(en.gtxt[i], false) end
						end
						if not en.txt then
							en.txt = D("Text", { Center = true, Outline = true, Size = 13 })
						end
						if sp.Z > 0 then
							DSET(en.txt, "Position", Vector2.new(sp.X, sp.Y))
							DSET(en.txt, "Text", "Gun")
							DSET(en.txt, "Color", G.textCol)
							DSHOW(en.txt, true)
						else
							DSHOW(en.txt, false)
						end
					end
				else
					if en.txt then DSHOW(en.txt, false) end
					if en.gtxt then
						for i = 1, #en.gtxt do DSHOW(en.gtxt[i], false) end
					end
				end
			else
				clear_gun(obj)
			end
		end
	end
	local function gun_start()
		if gun_render_conn then return end
		seed_gun_candidates()
		gun_scan_acc = 0.25
		gun_added_conn = workspace.DescendantAdded:Connect(gun_candidate_added)
		gun_removing_conn = workspace.DescendantRemoving:Connect(gun_candidate_removing)
		gun_render_conn = eRS.RenderStepped:Connect(gun_render)
	end
	local function gun_stop()
		if gun_render_conn then pcall(function() gun_render_conn:Disconnect() end) gun_render_conn = nil end
		if gun_added_conn then pcall(function() gun_added_conn:Disconnect() end) gun_added_conn = nil end
		if gun_removing_conn then pcall(function() gun_removing_conn:Disconnect() end) gun_removing_conn = nil end
		table.clear(gun_candidates)
	end

	-- master loop
	local esp_conn, scan_acc, role_acc = nil, 0, 0
	local function esp_start()
		if esp_conn then return end
		refreshRoles()
		esp_conn = eRS.RenderStepped:Connect(function(dt)
			if not E.on then return end
			role_acc = role_acc + dt
			if role_acc >= 1 then role_acc = 0 pcall(refreshRoles) end
			scan_acc = scan_acc + dt
			if scan_acc >= 0.5 then
				scan_acc = 0
				for _, plr in ipairs(ePlayers:GetPlayers()) do
					if not entries[plr] then newEntry(plr) end
				end
				for plr in pairs(entries) do
					if not plr.Parent then
						hideEntry(entries[plr])
						paintClear(entries[plr])
						entries[plr] = nil
					end
				end
			end
			local cam = workspace.CurrentCamera
			if not cam then return end
			local vp = cam.ViewportSize
			for _, plr in ipairs(ePlayers:GetPlayers()) do
				local en = entries[plr]
				if en then
					local ok, err = pcall(updatePlayer, en, cam, vp)
					if not ok then hideEntry(en) end
				end
			end
		end)
	end
	local function esp_stop()
		if esp_conn then pcall(function() esp_conn:Disconnect() end) esp_conn = nil end
		for _, en in pairs(entries) do
			hideEntry(en)
			paintClear(en)
			if en.chrom and getgenv().LX then getgenv().LX.chrom_clear(en.chrom) end
			if en.hlGlow then pcall(function() en.hlGlow:Destroy() end) en.hlGlow = nil end
			if en.hlVis then pcall(function() en.hlVis:Destroy() end) en.hlVis = nil end
			if en.hlOcc then pcall(function() en.hlOcc:Destroy() end) en.hlOcc = nil end
			if en.avImg then pcall(function() en.avImg:Destroy() end) en.avImg = nil end
		end
		if avGui then pcall(function() avGui:Destroy() end) avGui = nil end
	end
	ePlayers.PlayerRemoving:Connect(function(plr)
		local en = entries[plr]
		if en then
			hideEntry(en)
			paintClear(en)
			entries[plr] = nil
		end
	end)

	local function esp_unload()
		E.on = false
		G.on = false
		esp_stop()
		gun_stop()
		clear_guns()
	end

	local function clearLocal()
		local en = entries[eLP]
		if en then
			hideEntry(en)
			paintClear(en)
			hlOff(en, "hlVis") hlOff(en, "hlOcc")
			if en.hlGlow then DSET(en.hlGlow, "Enabled", false) end
			if en.chrom and getgenv().LX then getgenv().LX.chrom_clear(en.chrom) end
		end
	end
	getgenv().EX = { E = E, start = esp_start, stop = esp_stop, unload = esp_unload,
		gunStart = gun_start, gunStop = gun_stop, gunClear = clear_guns, clearLocal = clearLocal }
end
do
print("[world] init initESP...")
local ok, err = pcall(initESP)
print("[world] init initESP " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end
------------------------------ ESP GUI helpers + BUILD: ESP ------------------------------
local function TColorT(parent, name, def, trDef, cb)
	local col, tr = def, trDef or 1
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local prev = mk("TextButton", {
		Position = UDim2.new(1, -32, 0.5, -8), Size = UDim2.new(0, 32, 0, 16),
		BackgroundColor3 = col, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, prev)
	mk("UIStroke", { Color = C(85, 85, 105), Thickness = 1 }, prev)
	local r, g, bb = math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)
	local host = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y, Visible = false,
	}, parent)
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, host)
	local function push()
		col = C(clamp(r, 0, 255), clamp(g, 0, 255), clamp(bb, 0, 255))
		prev.BackgroundColor3 = col
		pcall(cb, col, tr)
	end
	TSlider(host, "R", 0, 255, r, 0, function(v) r = v push() end, true)
	TSlider(host, "G", 0, 255, g, 0, function(v) g = v push() end, true)
	TSlider(host, "B", 0, 255, bb, 0, function(v) bb = v push() end, true)
	TSlider(host, "transp", 0, 1, tr, 2, function(v) tr = v push() end, true)
	prev.MouseButton1Click:Connect(function() host.Visible = not host.Visible end)
	cfgReg(CurSec, name, {
		type = "colort",
		get = function() return { r = r, g = g, b = bb, t = tr } end,
		set = function(v)
			if type(v) ~= "table" then return end
			r = clamp(math.floor((tonumber(v.r) or r) + 0.5), 0, 255)
			g = clamp(math.floor((tonumber(v.g) or g) + 0.5), 0, 255)
			bb = clamp(math.floor((tonumber(v.b) or bb) + 0.5), 0, 255)
			tr = tonumber(v.t) or tr
			push()
		end,
	})
end

do
	local EX = getgenv().EX
	local E = EX.E

	do
		local sec = Section(pVis, "global", "left")
		TRow(sec, "global", false, function(v)
			E.on = v
			if v then EX.start() else EX.stop() end
		end, false)
	end

	do
		local sec = Section(pVis, "box", "left")
		local opt = TRow(sec, "box", false, function(v) E.box.on = v end, true)
		TColorT(opt, "color", E.box.col[1], E.box.col[2], function(c, t) E.box.col = { c, t } end)
		TDrop(opt, "preset", { "Static", "Corners" }, E.box.type, function(v) E.box.type = v end)
		TRow(opt, "gradient", false, function(v) E.box.grd = v end, false)
		TColor(opt, "gradient 1", E.box.g1, function(c) E.box.g1 = c end)
		TColor(opt, "gradient 2", E.box.g2, function(c) E.box.g2 = c end)
		TRow(opt, "fill", false, function(v) E.box.fill = v end, false)
		TColorT(opt, "fill", E.box.fcol[1], E.box.fcol[2], function(c, t) E.box.fcol = { c, t } end)
		TRow(opt, "fill gradient", false, function(v) E.box.fgrd = v end, false)
		TColor(opt, "fill gradient 1", E.box.fg1, function(c) E.box.fg1 = c end)
		TColor(opt, "fill gradient 2", E.box.fg2, function(c) E.box.fg2 = c end)
	end

	do
		local sec = Section(pVis, "name", "left")
		local opt = TRow(sec, "name", false, function(v) E.name.on = v end, true)
		TColorT(opt, "color", E.name.col[1], E.name.col[2], function(c, t) E.name.col = { c, t } end)
		TRow(opt, "gradient", false, function(v) E.name.grd = v end, false)
		TColor(opt, "gradient 1", E.name.g1, function(c) E.name.g1 = c end)
		TColor(opt, "gradient 2", E.name.g2, function(c) E.name.g2 = c end)
	end

	do
		local sec = Section(pVis, "avatar", "left")
		TRow(sec, "avatar", false, function(v) E.avatar.on = v end, false)
	end

	do
		local sec = Section(pVis, "arrows", "left")
		local opt = TRow(sec, "arrows", false, function(v) E.arrows.on = v end, true)
		TColor(opt, "murder", E.arrows.mur[1], function(c) E.arrows.mur = { c, 1 } end)
		TColor(opt, "innocent", E.arrows.inno[1], function(c) E.arrows.inno = { c, 1 } end)
		TColor(opt, "sheriff", E.arrows.shf[1], function(c) E.arrows.shf = { c, 1 } end)
		TSlider(opt, "size", 16, 96, E.arrows.size, 0, function(v) E.arrows.size = v end)
		TSlider(opt, "distance", 40, 520, E.arrows.dis, 0, function(v) E.arrows.dis = v end)
	end

	do
		local sec = Section(pVis, "distance", "left")
		local opt = TRow(sec, "distance", false, function(v) E.dist.on = v end, true)
		TColorT(opt, "color", E.dist.col[1], E.dist.col[2], function(c, t) E.dist.col = { c, t } end)
		TRow(opt, "gradient", false, function(v) E.dist.grd = v end, false)
		TColor(opt, "gradient 1", E.dist.g1, function(c) E.dist.g1 = c end)
		TColor(opt, "gradient 2", E.dist.g2, function(c) E.dist.g2 = c end)
	end

	do
		local sec = Section(pVis, "skeleton", "left")
		local opt = TRow(sec, "skeleton", false, function(v) E.skel.on = v end, true)
		TColorT(opt, "color", E.skel.col[1], E.skel.col[2], function(c, t) E.skel.col = { c, t } end)
	end

	do
		local sec = Section(pVis, "glow chams", "right")
		local opt = TRow(sec, "glow chams", false, function(v) E.chams.on = v end, true)
		TColorT(opt, "murder fill", E.chams.murF[1], E.chams.murF[2], function(c, t) E.chams.murF = { c, t } end)
		TColorT(opt, "murder outline", E.chams.murO[1], E.chams.murO[2], function(c, t) E.chams.murO = { c, t } end)
		TColorT(opt, "innocent fill", E.chams.innoF[1], E.chams.innoF[2], function(c, t) E.chams.innoF = { c, t } end)
		TColorT(opt, "innocent outline", E.chams.innoO[1], E.chams.innoO[2], function(c, t) E.chams.innoO = { c, t } end)
		TColorT(opt, "sheriff fill", E.chams.shfF[1], E.chams.shfF[2], function(c, t) E.chams.shfF = { c, t } end)
		TColorT(opt, "sheriff outline", E.chams.shfO[1], E.chams.shfO[2], function(c, t) E.chams.shfO = { c, t } end)
	end

	do
		local sec = Section(pVis, "material chams", "right")
		local opt = TRow(sec, "material chams", false, function(v) E.matchams.on = v end, true)
		TDrop(opt, "preset", { "ForceField", "Flat", "Chromatic" }, E.matchams.type, function(v) E.matchams.type = v end)
		TColor(opt, "murder", E.matchams.mur, function(c) E.matchams.mur = c end)
		TColor(opt, "innocent", E.matchams.inno, function(c) E.matchams.inno = c end)
		TColor(opt, "sheriff", E.matchams.shf, function(c) E.matchams.shf = c end)
		TColorT(opt, "murder visible", E.matchams.visMur[1], E.matchams.visMur[2], function(c, t) E.matchams.visMur = { c, t } end)
		TColorT(opt, "murder occluded", E.matchams.occMur[1], E.matchams.occMur[2], function(c, t) E.matchams.occMur = { c, t } end)
		TColorT(opt, "innocent visible", E.matchams.visInno[1], E.matchams.visInno[2], function(c, t) E.matchams.visInno = { c, t } end)
		TColorT(opt, "innocent occluded", E.matchams.occInno[1], E.matchams.occInno[2], function(c, t) E.matchams.occInno = { c, t } end)
		TColorT(opt, "sheriff visible", E.matchams.visShf[1], E.matchams.visShf[2], function(c, t) E.matchams.visShf = { c, t } end)
		TColorT(opt, "sheriff occluded", E.matchams.occShf[1], E.matchams.occShf[2], function(c, t) E.matchams.occShf = { c, t } end)
	end

	do
		local sec = Section(pVis, "flags", "right")
		local opt = TRow(sec, "flags", false, function(v) E.flags.on = v end, true)
		TColorT(opt, "murder", E.flags.mur[1], E.flags.mur[2], function(c, t) E.flags.mur = { c, t } end)
		TRow(opt, "murder gradient", false, function(v) E.flags.murGrd = v end, false)
		TColor(opt, "murder gradient 1", E.flags.murG1, function(c) E.flags.murG1 = c end)
		TColor(opt, "murder gradient 2", E.flags.murG2, function(c) E.flags.murG2 = c end)
		TColorT(opt, "sheriff", E.flags.shf[1], E.flags.shf[2], function(c, t) E.flags.shf = { c, t } end)
		TRow(opt, "sheriff gradient", false, function(v) E.flags.shfGrd = v end, false)
		TColor(opt, "sheriff gradient 1", E.flags.shfG1, function(c) E.flags.shfG1 = c end)
		TColor(opt, "sheriff gradient 2", E.flags.shfG2, function(c) E.flags.shfG2 = c end)
	end

	do
		local sec = Section(pVis, "gun", "right")
		local opt = TRow(sec, "gun", false, function(v)
			E.gun.on = v
			if v then EX.gunStart() else EX.gunStop() EX.gunClear() end
		end, true)
		TRow(opt, "text", false, function(v) E.gun.text = v end, false)
		TColor(opt, "text", E.gun.textCol, function(c) E.gun.textCol = c end)
		TRow(opt, "text gradient", false, function(v) E.gun.textGrd = v end, false)
		TColor(opt, "gradient color 1", E.gun.g1, function(c) E.gun.g1 = c end)
		TColor(opt, "gradient color 2", E.gun.g2, function(c) E.gun.g2 = c end)
		TRow(opt, "highlight", false, function(v) E.gun.hl = v end, false)
		TColor(opt, "highlight", E.gun.hlCol, function(c) E.gun.hlCol = c end)
	end

	do
		local sec = Section(pVis, "allow local", "right")
		TRow(sec, "allow local", false, function(v)
			E.allowlocal = v
			if not v then EX.clearLocal() end
		end, false)
	end

	unloadBtn.MouseButton1Click:Connect(function() EX.unload() end)
end
------------------------------ FX ENGINE (kill effects + tracer) ------------------------------
	local function initFx()
	local players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local ws = workspace
	local lp = players.LocalPlayer
	local tween = game:GetService("TweenService")

	-- parameterized death-fx unit (murder-only or players-except-murderer)
	local function makeDeathFx(murderOnly)
		local st = {
			on = false, clone = false, cloneCol = Color3.fromRGB(255, 0, 0), cloneDur = 3,
			part = false, partCol = Color3.fromRGB(255, 0, 0),
			emit = false, emitCol = Color3.fromRGB(255, 100, 100), emitDur = 1.2,
		}
		local clones, deathConns, roleMap = {}, {}, {}
		local addConn, pollThread = nil, nil
		local roleRemote = nil
		local active, activeCount = {}, 0

		local function removeFx(record)
			for i = 1, activeCount do
				if active[i] == record then
					active[i] = active[activeCount]
					active[activeCount] = nil
					activeCount = activeCount - 1
					break
				end
			end
			if record.part and record.part.Parent then record.part:Destroy() end
		end

		local function spawnBalls(char, tint, duration, channel)
			if not char or not char.Parent then return end
			if activeCount >= 3 then
				removeFx(active[1])
			end
			duration = math.max(duration, 0.2)
			local parts = {}
			for _, s in ipairs(char:GetChildren()) do
				if s:IsA("BasePart") and s.Name ~= "HumanoidRootPart" and #parts < 15 then
					parts[#parts + 1] = s
				end
			end
			if #parts == 0 then return end
			local root = Instance.new("Folder")
			root.Name = "\0"
			root.Parent = ws
			local record = { part = root, balls = {}, channel = channel }
			activeCount = activeCount + 1
			active[activeCount] = record
			local random = math.random
			local pi2 = math.pi * 2
			local golden = math.pi * (3 - math.sqrt(5))
			local function surfPos(source, radius, index, count, seed)
				local size = source.Size
				local pad = radius * 0.92
				if source.Name == "Head" then
					local y = 1 - 2 * ((index - 0.5) / count)
					local ang = index * golden + seed
					local rad = math.sqrt(math.max(0, 1 - y * y))
					local dir = Vector3.new(rad * math.cos(ang), y, rad * math.sin(ang))
					local half = size * 0.5
					return source.CFrame:PointToWorldSpace(Vector3.new(
						dir.X * (half.X + pad), dir.Y * (half.Y + pad), dir.Z * (half.Z + pad)))
				end
				local ax = size.Y * size.Z
				local ay = size.X * size.Z
				local az = size.X * size.Y
				local pick = random() * (ax + ay + az)
				local pos
				if pick < ax then
					local side = random() < 0.5 and -1 or 1
					pos = Vector3.new(side * (size.X * 0.5 + pad), (random() - 0.5) * size.Y, (random() - 0.5) * size.Z)
				elseif pick < ax + ay then
					local side = random() < 0.5 and -1 or 1
					pos = Vector3.new((random() - 0.5) * size.X, side * (size.Y * 0.5 + pad), (random() - 0.5) * size.Z)
				else
					local side = random() < 0.5 and -1 or 1
					pos = Vector3.new((random() - 0.5) * size.X, (random() - 0.5) * size.Y, side * (size.Z * 0.5 + pad))
				end
				return source.CFrame:PointToWorldSpace(pos)
			end
			local minY, maxY = math.huge, -math.huge
			for _, s in ipairs(parts) do
				local hy = s.Size.Y * 0.5
				minY = math.min(minY, s.Position.Y - hy)
				maxY = math.max(maxY, s.Position.Y + hy)
			end
			local phases, groups = 8, {}
			for i = 1, phases do groups[i] = {} end
			local seed = random() * pi2
			local height = math.max(maxY - minY, 0.01)
			local created = 0
			for _, s in ipairs(parts) do
				local size = s.Size
				local surf = 2 * (size.X * size.Y + size.X * size.Z + size.Y * size.Z)
				local count = s.Name == "Head" and 24 or math.clamp(math.floor(surf * 0.65 + 0.5), 7, 12)
				count = math.min(count, 140 - created)
				for index = 1, count do
					local dia = s.Name == "Head" and (0.115 + random() * 0.045) or (0.13 + random() * 0.06)
					local tsize = Vector3.new(dia, dia, dia)
					local pos = surfPos(s, dia * 0.5, index, count, seed)
					local ball = Instance.new("Part")
					ball.Name = "\0"
					ball.Shape = Enum.PartType.Ball
					ball.Material = Enum.Material.Neon
					ball.Color = tint
					ball.Size = Vector3.new(0.015, 0.015, 0.015)
					ball.Position = pos
					ball.Anchored = true
					ball.CanCollide = false
					ball.CanQuery = false
					ball.CanTouch = false
					ball.CastShadow = false
					ball.Massless = true
					ball.Transparency = 1
					ball.Parent = root
					record.balls[#record.balls + 1] = ball
					created = created + 1
					local vert = math.clamp((pos.Y - minY) / height, 0, 1)
					local ph = math.clamp(math.floor(vert * (phases - 1) + 1.5) + random(-1, 1), 1, phases)
					groups[ph][#groups[ph] + 1] = { ball = ball, size = tsize }
				end
				if created >= 140 then break end
			end
			local revealW = math.min(0.34, duration * 0.26)
			local revealT = math.min(0.2, duration * 0.18)
			local fadeB = math.max(revealW + revealT + 0.06, duration * 0.42)
			local fadeW = math.min(0.28, duration * 0.18)
			local fadeT = math.max(duration - fadeB - fadeW, 0.1)
			for ph = 1, phases do
				local alpha = (ph - 1) / (phases - 1)
				local group = groups[ph]
				task.delay(revealW * alpha, function()
					if not root.Parent then return end
					for _, item in ipairs(group) do
						if item.ball.Parent then
							tween:Create(item.ball, TweenInfo.new(revealT, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = item.size, Transparency = 0.05 }):Play()
						end
					end
				end)
				task.delay(fadeB + fadeW * alpha, function()
					if not root.Parent then return end
					for _, item in ipairs(group) do
						if item.ball.Parent then
							tween:Create(item.ball, TweenInfo.new(fadeT, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = item.size * 0.58, Transparency = 1 }):Play()
						end
					end
				end)
			end
			task.delay(duration + 0.12, function()
				removeFx(record)
			end)
		end

		local function fadeClone(clone)
			task.delay(st.cloneDur, function()
				if not clone.Parent then return end
				for _, d in ipairs(clone:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
						pcall(function()
							tween:Create(d, TweenInfo.new(1.5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
						end)
					end
				end
				task.delay(1.6, function()
					for i = #clones, 1, -1 do
						if clones[i] == clone then table.remove(clones, i) end
					end
					if clone.Parent then clone:Destroy() end
				end)
			end)
		end

		local function makeClone(char)
			local ok, clone = pcall(function() return char:Clone() end)
			if not ok or not clone then return end
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					if d.Name == "HumanoidRootPart" then
						d.Transparency = 1
					else
						d.Material = Enum.Material.ForceField
						d.Color = st.cloneCol
					end
				elseif d:IsA("Humanoid") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Sound") then
					pcall(function() d:Destroy() end)
				elseif d:IsA("SurfaceAppearance") then
					pcall(function() d:Destroy() end)
				elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
					or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") or d:IsA("Highlight") then
					pcall(function() d:Destroy() end)
				end
			end
			clone.Name = "\0"
			clone.Parent = ws
			clones[#clones + 1] = clone
			fadeClone(clone)
		end

		local function onDeath(char)
			if st.clone then makeClone(char) end
			if st.part then spawnBalls(char, st.partCol, 1.2, "particle") end
			if st.emit then spawnBalls(char, st.emitCol, st.emitDur, "emitter") end
		end

		local function hookPlayer(pl)
			local function onChar(char)
				local hum = char:WaitForChild("Humanoid", 5)
				if not hum then return end
				deathConns[#deathConns + 1] = hum.Died:Connect(function()
					if not st.on then return end
					local r = roleMap[pl.Name]
					if murderOnly then
						if r == "Murderer" then onDeath(char) end
					elseif r ~= "Murderer" then
						onDeath(char)
					end
				end)
			end
			if pl.Character then task.spawn(onChar, pl.Character) end
			deathConns[#deathConns + 1] = pl.CharacterAdded:Connect(onChar)
		end

		local function stop()
			for _, c in ipairs(deathConns) do pcall(function() c:Disconnect() end) end
			deathConns = {}
			for i = 1, activeCount do
				local r = active[i]
				if r then pcall(function() r.part:Destroy() end) end
				active[i] = nil
			end
			activeCount = 0
			if addConn then pcall(function() addConn:Disconnect() end) addConn = nil end
			for _, cl in ipairs(clones) do pcall(function() cl:Destroy() end) end
			clones = {}
			if pollThread then pcall(function() task.cancel(pollThread) end) pollThread = nil end
			roleMap = {}
		end

		local function start()
			stop()
			pollThread = task.spawn(function()
				while st.on do
					pcall(function()
						local f = roleRemote
						if not f or not f.Parent then
							f = rs:FindFirstChild("GetPlayerData", true)
							roleRemote = f
						end
						local data = f and f:InvokeServer()
						if type(data) == "table" then
							local m = {}
							for name, d in pairs(data) do
								if type(d) == "table" and d.Role then m[name] = d.Role end
							end
							roleMap = m
						end
					end)
					task.wait(1)
				end
			end)
			for _, pl in ipairs(players:GetPlayers()) do
				if pl ~= lp then hookPlayer(pl) end
			end
			addConn = players.PlayerAdded:Connect(function(pl)
				if pl ~= lp then hookPlayer(pl) end
			end)
		end

		local function recolorClones()
			for _, cl in ipairs(clones) do
				for _, d in ipairs(cl:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Color = st.cloneCol end
				end
			end
		end

		local function recolorEmit()
			for i = 1, activeCount do
				local fx = active[i]
				if fx and fx.channel == "emitter" then
					for _, ball in ipairs(fx.balls) do
						if ball.Parent then ball.Color = st.emitCol end
					end
				end
			end
		end

		return { st = st, start = start, stop = stop, recolorClones = recolorClones, recolorEmit = recolorEmit }
	end

	local FXM = makeDeathFx(true)
	local FXP = makeDeathFx(false)
	getgenv().FXM = FXM
	getgenv().FXP = FXP
end
do
print("[world] init initFx...")
local ok, err = pcall(initFx)
print("[world] init initFx " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ FX TRACER ------------------------------
function initFxTracer()
	local rs = game:GetService("ReplicatedStorage")
	local tween_service = game:GetService("TweenService")
	local debris = game:GetService("Debris")
	local lp = game.Players.LocalPlayer

	getgenv().SHERIFF_TRACER_ENABLED = false
	getgenv().SHERIFF_TRACER_COLOR = Color3.fromRGB(133, 220, 255)
	getgenv().SHERIFF_TRACER_DURATION = 1

	local tracer_on = false
	local gun_fired_conn = nil
	local gun_fired_remote = nil
	local round_client = nil

	local fade_tween = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local function get_round_client()
		local ok, module = pcall(function()
			return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
		end)
		if ok then round_client = module end
		return round_client
	end

	local function is_local_sheriff()
		local char = lp.Character
		if char and char:FindFirstChild("Gun") then return true end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp and bp:FindFirstChild("Gun") then return true end
		local round = get_round_client()
		if not round then return false end
		local data = round.PlayerData
		local d = data and data[lp.Name]
		return d ~= nil and (d.Role == "Sheriff" or d.Role == "Hero")
	end

	local function make_point(position, lifetime)
		local part = Instance.new("Part")
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Size = Vector3.new(1, 1, 1)
		part.CFrame = CFrame.new(position)
		Instance.new("Attachment", part)
		debris:AddItem(part, lifetime)
		part.Parent = workspace
		return part
	end

	local function to_position(value)
		if typeof(value) == "Vector3" then
			return value
		elseif typeof(value) == "CFrame" then
			return value.Position
		elseif typeof(value) == "Instance" then
			if value:IsA("Attachment") then
				return value.WorldPosition
			elseif value:IsA("BasePart") then
				return value.Position
			end
		end
	end

	local function create_tracer(start_value, end_value)
		local start_position = to_position(start_value)
		local end_position = to_position(end_value)
		if not start_position or not end_position then return end

		local duration = getgenv().SHERIFF_TRACER_DURATION or 1
		local start_part = make_point(start_position, duration + 0.5)
		local end_part = make_point(end_position, duration + 0.5)

		local beam = Instance.new("Beam")
		beam.FaceCamera = true
		beam.TextureSpeed = 1.5
		beam.TextureLength = 2
		beam.Width0 = 0.25
		beam.Width1 = 0.25
		beam.LightEmission = 3
		beam.LightInfluence = 0
		beam.Brightness = 2.5
		beam.Texture = "rbxassetid://12781800668"
		beam.Color = ColorSequence.new(getgenv().SHERIFF_TRACER_COLOR)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.1) })
		beam.Attachment0 = start_part.Attachment
		beam.Attachment1 = end_part.Attachment
		beam.Parent = start_part

		task.delay(duration, function()
			if beam.Parent then
				tween_service:Create(beam, fade_tween, { Width0 = 0, Width1 = 0 }):Play()
			end
		end)
	end

	local function on_gun_fired(gun, start_value, end_value)
		if not tracer_on then return end
		local char = lp.Character
		if not char then return end
		if not (typeof(gun) == "Instance" and gun:IsDescendantOf(char)) then return end
		if not is_local_sheriff() then return end
		create_tracer(start_value, end_value)
	end

	local function connect_gun_fired()
		local ok, remote = pcall(function()
			return rs:WaitForChild("ClientServices"):WaitForChild("WeaponService"):WaitForChild("GunFired")
		end)
		if not ok or not remote then return end
		if gun_fired_conn and gun_fired_remote == remote and gun_fired_conn.Connected then return end
		if gun_fired_conn then pcall(function() gun_fired_conn:Disconnect() end) gun_fired_conn = nil end
		gun_fired_remote = remote
		gun_fired_conn = remote.OnClientEvent:Connect(function(gun, start_value, end_value)
			task.spawn(on_gun_fired, gun, start_value, end_value)
		end)
	end
	local tracer_run = false
	local function tracer_start()
		tracer_on = true
		tracer_run = true
		connect_gun_fired()
		task.spawn(function()
			while tracer_run do
				pcall(connect_gun_fired)
				task.wait(1)
			end
		end)
	end
	local function tracer_stop()
		tracer_on = false
		tracer_run = false
		if gun_fired_conn then pcall(function() gun_fired_conn:Disconnect() end) gun_fired_conn = nil end
	end
	getgenv().SHERIFF_TRACER_ENABLED = false
	getgenv().SHERIFF_TRACER_COLOR = Color3.fromRGB(133, 220, 255)
	getgenv().SHERIFF_TRACER_DURATION = 1
	getgenv().FXT = { start = tracer_start, stop = tracer_stop }
end
do
print("[world] init initFxTracer...")
local ok, err = pcall(initFxTracer)
print("[world] init initFxTracer " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ MISC FAKE ------------------------------
function initFake()
	local function CreateIndicator(_)
		return { Set = function() end, SetRender = function() end, SetText = function() end, Remove = function() end }
	end
	local run_service = game:GetService("RunService")
	local players_service = game:GetService("Players")
	local local_player = players_service.LocalPlayer

	local render_stepped = run_service.RenderStepped
	local render_stepped_wait = render_stepped.Wait
	local vector3_new = Vector3.new
	local cframe_new = CFrame.new
	local vector3_zero = Vector3.zero
	local cframe_angles = CFrame.Angles
	local math_random = math.random
	local rad = math.rad
	local clock = os.clock
	local floor = math.floor
	local spawn = task.spawn
	local wait = task.wait

	local function round(num, decimals)
		local mult = 10^(decimals or 0)
		return floor(num * mult + 0.5 - (num < 0 and 1 or 0)) / mult
	end

	local local_server_position = cframe_new()
	local local_client_position = cframe_new()
	local local_parts = {}
	local local_fps = 200
	local anti_aim = {}
	local vehicle = nil
	local purchasing = nil
	local stomping = false
	local fake_pos_active = false

	getgenv().FAKE_POS_ACTIVE = false
	getgenv().FAKE_POS_MULTI_AXIS = {X = true, Y = true, Z = true}
	getgenv().FAKE_POS_RANGE_X = 9e9
	getgenv().FAKE_POS_RANGE_Y = 9e9
	getgenv().FAKE_POS_RANGE_Z = 9e9

	local function remove(tbl, index)
		local length = #tbl
		for i = index, length - 1 do
			tbl[i] = tbl[i + 1]
		end
		tbl[length] = nil
	end

	local hrp_protected = {}
	local part_protected = {}
	local humanoid_protected = {}
	local hooked_metatables = {}

	local function apply_hrp_fix(hrp)
		if hrp_protected[hrp] then return end
		hrp_protected[hrp] = true
		local old = getrawmetatable(hrp)
		if not old then return end
		local old_index = old.__index
		local old_newindex = old.__newindex

		hooked_metatables[hrp] = {mt = old, target = hrp}

		local new = {
			__index = newcclosure(function(self, index)
				if not checkcaller() and self and index == "CFrame" and (#anti_aim ~= 0 or purchasing) and not vehicle then
					return local_client_position
				end
				return old_index(self, index)
			end),
			__newindex = newcclosure(function(self, index, value)
				if not checkcaller() and self then
					if index == "Anchored" then
						return
					end
					if (index == "CFrame" or index == "Position") and (#anti_aim ~= 0 or purchasing) then
						return
					end
				end
				return old_newindex(self, index, value)
			end)
		}

		for k, v in old do
			if not new[k] then
				new[k] = v
			end
		end

		setrawmetatable(hrp, new)
	end

	local function protect_part(part)
		if part_protected[part] then return end
		part_protected[part] = true
		local old_mt = getrawmetatable(part)
		if not old_mt then return end
		local old_newindex = old_mt.__newindex
		if not old_newindex then return end

		hooked_metatables[part] = {mt = old_mt, target = part}

		local new_mt = {}
		for k, v in old_mt do new_mt[k] = v end

		new_mt.__newindex = newcclosure(function(self, index, value)
			if not checkcaller() and self then
				if index == "Anchored" or index == "CanCollide" then
					return
				end
			end
			return old_newindex(self, index, value)
		end)

		setrawmetatable(part, new_mt)
	end

	local function protect_humanoid(humanoid)
		if humanoid_protected[humanoid] then return end
		humanoid_protected[humanoid] = true
		local old_mt = getrawmetatable(humanoid)
		if not old_mt then return end
		local old_newindex = old_mt.__newindex
		if not old_newindex then return end

		hooked_metatables[humanoid] = {mt = old_mt, target = humanoid}

		local new_mt = {}
		for k, v in old_mt do new_mt[k] = v end

		new_mt.__newindex = newcclosure(function(self, index, value)
			if not checkcaller() and self and fake_pos_active then
				if index == "Health" and type(value) == "number" and value <= 0 then
					return
				end
			end
			return old_newindex(self, index, value)
		end)

		setrawmetatable(humanoid, new_mt)
	end

	local update_server_position = function(hrp)
		local_server_position = hrp.CFrame
	end

	local fake_position_sitting = false
	local local_fake_position = nil
	local orig_display_pos = nil
	local fake_position_sender_rate_old
	pcall(function()
		fake_position_sender_rate_old = getfflag("S2PhysicsSenderRate")
	end)
	local fake_position_refresh_connection = nil
	local fake_position_refresh_connection2 = nil
	local fake_position_refresh_connection3 = nil

	local fallen_height_old = nil

	local marker_enabled = true
	local marker_color = Color3.fromRGB(193, 247, 255)

	local b64set = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local function b64dec(data)
		data = data:gsub("[^" .. b64set .. "=]", "")
		return (data:gsub(".", function(x)
			if x == "=" then return "" end
			local r, f = "", b64set:find(x) - 1
			for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then return "" end
			local c = 0
			for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
			return string.char(c)
		end))
	end

	local marker_data = b64dec("iVBORw0KGgoAAAANSUhEUgAAAB0AAAAdCAMAAABhTZc9AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAPUExURQAAAP///wwMDP39/QAAAJn0DigAAAAFdFJOU/////8A+7YOUwAAAAlwSFlzAABLlgAAS5YBPIKNxAAAABh0RVh0U29mdHdhcmUAUGFpbnQuTkVUIDUuMS4y+7wDtgAAALZlWElmSUkqAAgAAAAFABoBBQABAAAASgAAABsBBQABAAAAUgAAACgBAwABAAAAAgAAADEBAgAQAAAAWgAAAGmHBAABAAAAagAAAAAAAAD7fwcA6AMAAPt/BwDoAwAAUGFpbnQuTkVUIDUuMS4yAAMAAJAHAAQAAAAwMjMwAaADAAEAAAABAAAABaAEAAEAAACUAAAAAAAAAAIAAQACAAQAAABSOTgAAgAHAAQAAAAwMTAwAAAAAFgdiCkiK10LAAAAZ0lEQVQ4T+XT0QqAMAgF0Gv5/9/cdJrXPYweopeEoe5MGKOgHMDSR/aAiPSNyBaGnT9S4Oi3pnqOtuEqE5kfaiHxG8pYTJoHrMzdzFu1h0qt57oLH58a/YhFfUU/4s967tT/Iv4mVS+LEAmXjonxPAAAAABJRU5ErkJggg==")

	local marker_bad_prop = {}
	local function marker_set(obj, prop, value)
		if marker_bad_prop[prop] then return end
		if not pcall(function() obj[prop] = value end) then
			marker_bad_prop[prop] = true
		end
	end

	local marker_glow = Drawing.new("Image")
	marker_set(marker_glow, "Data", marker_data)
	marker_set(marker_glow, "Color", marker_color)
	marker_set(marker_glow, "Transparency", 0.35)
	marker_set(marker_glow, "ZIndex", 1)
	marker_set(marker_glow, "Visible", false)

	local marker_icon = Drawing.new("Image")
	marker_set(marker_icon, "Data", marker_data)
	marker_set(marker_icon, "Color", marker_color)
	marker_set(marker_icon, "Transparency", 1)
	marker_set(marker_icon, "ZIndex", 2)
	marker_set(marker_icon, "Visible", false)

	local function hide_marker()
		marker_set(marker_glow, "Visible", false)
		marker_set(marker_icon, "Visible", false)
	end

	local function draw_marker(cx, cy)
		local gs = 46
		marker_set(marker_glow, "Size", Vector2.new(gs, gs))
		marker_set(marker_glow, "Position", Vector2.new(cx - gs / 2, cy - gs / 2))
		marker_set(marker_glow, "Color", marker_color)
		marker_set(marker_glow, "Visible", true)
		local isz = 30
		marker_set(marker_icon, "Size", Vector2.new(isz, isz))
		marker_set(marker_icon, "Position", Vector2.new(cx - isz / 2, cy - isz / 2))
		marker_set(marker_icon, "Color", marker_color)
		marker_set(marker_icon, "Visible", true)
	end

	local function set_world_limits(disable)
		if disable then
			pcall(function() fallen_height_old = gethiddenproperty(workspace, "FallenPartsDestroyHeight") end)
			pcall(function() sethiddenproperty(workspace, "FallenPartsDestroyHeight", -9e9) end)
		else
			pcall(function() sethiddenproperty(workspace, "FallenPartsDestroyHeight", fallen_height_old or -500) end)
		end
	end

	local ltm_parts = {}
	local ltm_char = nil
	local ltm_valid = false
	local ltm_conns = {}

	local function ltm_parts_for(character)
		if ltm_char ~= character then
			ltm_char = character
			ltm_valid = false
			for i = 1, #ltm_conns do
				pcall(function() ltm_conns[i]:Disconnect() end)
			end
			table.clear(ltm_conns)
			if character then
				local function dirty(d)
					if d:IsA("BasePart") then ltm_valid = false end
				end
				ltm_conns[1] = character.DescendantAdded:Connect(dirty)
				ltm_conns[2] = character.DescendantRemoving:Connect(dirty)
			end
		end
		if not ltm_valid then
			table.clear(ltm_parts)
			local n = 0
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					n = n + 1
					ltm_parts[n] = part
				end
			end
			ltm_valid = true
		end
		return ltm_parts
	end

	local function set_local_body_transparency(value)
		local character = local_player.Character
		if not character then return end
		local parts = ltm_parts_for(character)
		local target = value and 0.6 or 0
		for i = 1, #parts do
			local part = parts[i]
			if part.Parent then
				part.LocalTransparencyModifier = target
			end
		end
	end

	local do_refresh_fake_position = function()
		if local_server_position then
			local_fake_position = local_server_position.p
		end
	end

	local pending_teleport = nil
	local tp_settle_until = 0

	local do_fake_position = function(dt, hrp)
		pcall(function() setfflag("S2PhysicsSenderRate", tostring(round(local_fps, 1))) end)
		if fake_position_sitting then
			local_fake_position = nil
			return
		end
		if dt > 0.45 then
			return
		end
		if hrp then
			pcall(function() sethiddenproperty(hrp, "NetworkIsSleeping", false) end)
			pcall(function()
				if hrp.AssemblyLinearVelocity.Magnitude < 1 then
					hrp.AssemblyLinearVelocity = vector3_new(0, 0.1, 0)
				end
			end)
		end

		local axes = getgenv().FAKE_POS_MULTI_AXIS
		local rx = getgenv().FAKE_POS_RANGE_X
		local ry = getgenv().FAKE_POS_RANGE_Y
		local rz = getgenv().FAKE_POS_RANGE_Z
		local base = local_client_position and local_client_position.p or vector3_zero
		local x = axes.X and ((math.random() * 2 - 1) * rx) or base.X
		local y = axes.Y and (-(math.random()) * ry) or base.Y
		local z = axes.Z and ((math.random() * 2 - 1) * rz) or base.Z

		if pending_teleport then
			pcall(function()
				hrp.CFrame = pending_teleport
				hrp.AssemblyLinearVelocity = vector3_zero
				hrp.AssemblyAngularVelocity = vector3_zero
			end)
			local_client_position = pending_teleport
			pending_teleport = nil
		end

		local old = hrp.CFrame
		local fake_cf = cframe_new(vector3_new(x, y, z)) * cframe_angles(rad(math_random(1,359)), rad(math_random(1,359)), rad(math_random(1,359)))
		orig_display_pos = fake_cf.Position
		hrp.CFrame = fake_cf
		render_stepped_wait(render_stepped)
		hrp.CFrame = old
	end

	getgenv().SHITARO_TELEPORT = function(cf)
		if typeof(cf) == "Vector3" then cf = cframe_new(cf) end
		if typeof(cf) ~= "CFrame" then return false end
		local hrp = local_parts["HumanoidRootPart"]
		if not hrp then return false end
		if fake_pos_active then
			cf = cframe_new(cf.Position)
			tp_settle_until = clock() + 0.35
			pending_teleport = cf
		else
			pcall(function() hrp.CFrame = cf end)
			local_client_position = cf
		end
		return true
	end

	local function fake_position_stop_sitting(character)
		local humanoid = local_parts["Humanoid"]
		if not humanoid then return end
		fake_position_sitting = humanoid.Sit

		if fake_position_refresh_connection3 then
			pcall(function() fake_position_refresh_connection3:Disconnect() end)
			fake_position_refresh_connection3 = nil
		end

		fake_position_refresh_connection3 = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
			fake_position_sitting = humanoid.Sit
			if not fake_position_sitting then
				spawn(do_refresh_fake_position)
			else
				local_fake_position = local_client_position and local_client_position.p
			end
		end)
	end

	local function fake_position_enable(value)
		local_fake_position = nil
		pending_teleport = nil
		fake_pos_active = value
		getgenv().FAKE_POS_ACTIVE = value

		for i = 1, #anti_aim do
			if anti_aim[i] == do_fake_position then
				remove(anti_aim, i)
				break
			end
		end

		if fake_position_refresh_connection then
			pcall(function() fake_position_refresh_connection:Disconnect() end)
			fake_position_refresh_connection = nil
		end
		if fake_position_refresh_connection2 then
			pcall(function() fake_position_refresh_connection2:Disconnect() end)
			fake_position_refresh_connection2 = nil
		end
		if fake_position_refresh_connection3 then
			pcall(function() fake_position_refresh_connection3:Disconnect() end)
			fake_position_refresh_connection3 = nil
		end

		set_local_body_transparency(value)

		if value then
			set_world_limits(true)
			anti_aim[#anti_aim+1] = do_fake_position

			local hrp = local_parts["HumanoidRootPart"]
			if hrp then
				pcall(function()
					sethiddenproperty(hrp, "NetworkIsSleeping", false)
					hrp.AssemblyLinearVelocity = vector3_new(0, 0.1, 0)
				end)
			end

			fake_position_refresh_connection = local_player.CharacterAdded:Connect(function()
				task.wait(0.5)
				spawn(do_refresh_fake_position)
				if local_parts["Humanoid"] then
					fake_position_stop_sitting(local_player.Character)
				end
				if fake_pos_active then
					set_local_body_transparency(true)
				end
			end)

			if local_player.Character then
				fake_position_stop_sitting(local_player.Character)
			end

			spawn(do_refresh_fake_position)
		else
			set_world_limits(false)
			pcall(function() setfflag("S2PhysicsSenderRate", fake_position_sender_rate_old or "15") end)
			pcall(function() setfpscap(0) end)
			local hrp = local_parts["HumanoidRootPart"]
			if hrp and local_client_position then
				pcall(function()
					sethiddenproperty(hrp, "NetworkIsSleeping", false)
					hrp.CFrame = local_client_position
					hrp.AssemblyLinearVelocity = vector3_new(0, 0.1, 0)
				end)
			end
			orig_display_pos = nil
			hide_marker()
		end
	end

	local function init_character(character)
		if not character then return end
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			local_parts["HumanoidRootPart"] = hrp
			local humanoid = character:WaitForChild("Humanoid", 5)
			local_parts["Humanoid"] = humanoid
			apply_hrp_fix(hrp)
			if humanoid then
				protect_humanoid(humanoid)
			end

			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					protect_part(part)
				end
			end
			character.DescendantAdded:Connect(function(part)
				if part:IsA("BasePart") then
					protect_part(part)
				elseif part:IsA("Humanoid") then
					protect_humanoid(part)
				end
			end)

			if fake_pos_active then
				set_local_body_transparency(true)
			end
		end
	end

	init_character(local_player.Character)
	local char_added_conn = local_player.CharacterAdded:Connect(init_character)

	local last_fps = clock()
	local heartbeat_conn = run_service.Heartbeat:Connect(function(dt)
		local_fps = 1/(clock() - last_fps)
		last_fps = clock()

		local hrp = vehicle or local_parts["HumanoidRootPart"]

		if hrp then
			local_client_position = hrp.CFrame
		end

		if hrp and clock() < tp_settle_until then
			pcall(function()
				hrp.AssemblyLinearVelocity = vector3_zero
				hrp.AssemblyAngularVelocity = vector3_zero
			end)
		end

		for i = 1, #anti_aim do
			local func = anti_aim[i]
			if func then
				spawn(func, dt, hrp)
			end
		end

		if hrp then
			local_server_position = hrp.CFrame
		end
	end)

	local transparency_conn = run_service.RenderStepped:Connect(function()
		
		if fake_pos_active then
			set_local_body_transparency(true)
			if marker_enabled and orig_display_pos then
				local cam = workspace.CurrentCamera
				local pos = cam:WorldToViewportPoint(orig_display_pos)
				if pos.Z > 0 then
					draw_marker(pos.X, pos.Y)
				else
					hide_marker()
				end
			else
				hide_marker()
			end
		else
			hide_marker()
		end
	end)

	local function read_part_position(p)
		return p.Position
	end

	run_service:BindToRenderStep("shitaro_fakepos_cam", Enum.RenderPriority.Camera.Value - 1, function()
		if not fake_pos_active then return end
		if not (local_parts and local_parts["HumanoidRootPart"]) then return end
		local hrp = local_parts["HumanoidRootPart"]
		if not hrp or not local_client_position then return end
		local ok, pos = pcall(read_part_position, hrp)
		if ok and (pos - local_client_position.p).Magnitude > 500 then
			pcall(function() hrp.CFrame = local_client_position end)
		end
	end)

	getgenv().FAKE_POS_UNLOAD = function()
		if fake_pos_active then
			fake_position_enable(false)
		end
		if heartbeat_conn then
			pcall(function() heartbeat_conn:Disconnect() end)
			heartbeat_conn = nil
		end
		if transparency_conn then
			pcall(function() transparency_conn:Disconnect() end)
			transparency_conn = nil
		end
		pcall(function() run_service:UnbindFromRenderStep("shitaro_fakepos_cam") end)
		if char_added_conn then
			pcall(function() char_added_conn:Disconnect() end)
			char_added_conn = nil
		end
		set_world_limits(false)
		set_local_body_transparency(false)
		for i = 1, #ltm_conns do
			pcall(function() ltm_conns[i]:Disconnect() end)
		end
		table.clear(ltm_conns)
		ltm_char = nil
		ltm_valid = false
		orig_display_pos = nil
		pcall(function() marker_glow:Remove() end)
		pcall(function() marker_icon:Remove() end)
		for target, data in pairs(hooked_metatables) do
			pcall(function()
				setrawmetatable(target, data.mt)
			end)
		end
		hooked_metatables = {}
		hrp_protected = {}
		part_protected = {}
		humanoid_protected = {}
		anti_aim = {}
		pcall(function()
			setfflag("S2PhysicsSenderRate", fake_position_sender_rate_old or "15")
		end)
		pcall(function() setfpscap(0) end)
	end
	local fakeposs = CreateIndicator({
		Name = "FAKE",
		Icon = "heart",
		Color = "Green",
	})
	local velocity_desync_type = "low"
	local velocity_desync_rotate = false

	local do_velocity_desync = function(dt, hrp)
		if hrp and not stomping and not purchasing and (getgenv().FLING_ACTIVE or 0) == 0 then
			pcall(function() setfflag("S2PhysicsSenderRate", tostring(round(local_fps, 1))) end)
			pcall(function() sethiddenproperty(hrp, "NetworkIsSleeping", false) end)
			local old_lin = hrp.AssemblyLinearVelocity
			local old_ang = hrp.AssemblyAngularVelocity
			local vel = velocity_desync_type == "y high" and vector3_new(0, 16384, 0)
				or velocity_desync_type == "limit" and vector3_new(
					math_random(-9223372036854775808, 9223372036854775807),
					math_random(-9223372036854775808, 9223372036854775807),
					math_random(-9223372036854775808, 9223372036854775807)
				)
				or velocity_desync_type == "low" and vector3_new(
					math_random(1,2) == 1 and -300 or 300,
					math_random(1,2) == 1 and -300 or 300,
					math_random(1,2) == 1 and -300 or 300
				)
				or velocity_desync_type == "high" and vector3_new(
					math_random(1,2) == 1 and -16384 or 16384,
					math_random(1,2) == 1 and -14384 or 16384,
					math_random(1,2) == 1 and -16384 or 16384
				)
				or velocity_desync_type == "zero" and vector3_zero
				or vector3_zero

			getgenv().VELOCITY_DESYNC_UNTIL = clock() + 0.35
			hrp.AssemblyLinearVelocity = vel
			if velocity_desync_rotate then
				hrp.AssemblyAngularVelocity = vel
			end

			render_stepped_wait(render_stepped)
			hrp.AssemblyLinearVelocity = old_lin
			hrp.AssemblyAngularVelocity = old_ang
			getgenv().VELOCITY_DESYNC_UNTIL = clock() + 0.05
		end
	end

	local function velocity_desync_enable(value)
		for i = 1, #anti_aim do
			if anti_aim[i] == do_velocity_desync then
				remove(anti_aim, i)
				break
			end
		end
		if value then
			anti_aim[#anti_aim+1] = do_velocity_desync
		else
			pcall(function() setfflag("S2PhysicsSenderRate", fake_position_sender_rate_old or "15") end)
		end
	end
	getgenv().MXF = {
		fake = fake_position_enable,
		vel = velocity_desync_enable,
		setVelType = function(v) velocity_desync_type = v end,
		setMarker = function(v) marker_enabled = v if not v then hide_marker() end end,
		setMarkerCol = function(c) marker_color = c end,
		unload = getgenv().FAKE_POS_UNLOAD,
	}
end
do
print("[world] init initFake...")
local ok, err = pcall(initFake)
print("[world] init initFake " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ MISC ENGINE ------------------------------
function initMisc()
	local function CreateIndicator(_)
		return { Set = function() end, SetRender = function() end, SetText = function() end, Remove = function() end }
	end
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local uis = game:GetService("UserInputService")
	local vu = game:GetService("VirtualUser")
	local cs = game:GetService("CollectionService")
	local rs = game:GetService("ReplicatedStorage")
	local ws = workspace
	local lp = players.LocalPlayer

	local function get_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local anti_master, afk_set, fling_set, void_set, coin_set, fade_set, trap_set = false, false, false, false, false, false, false
	local anti_afk, anti_fling, anti_void, anti_trap = false, false, false, false
	local coin_on = false
	local fade_on = false
	local void_original = ws.FallenPartsDestroyHeight
	local noclip_on, fly_on = false, false
	local inf_jump_on, wallhop_on = false, false
	local fly_speed = 60
	local fly_gravity = ws.Gravity
	local fly_up_on, fly_down_on = true, true
	local fly_up_kc, fly_down_kc = Enum.KeyCode.Space, Enum.KeyCode.LeftControl
	local noclip_cache = {}
	local fling_cache = {}
	local last_coin_backup = nil

	local function kill_container(d)
		pcall(function()
			d.Archivable = true
			last_coin_backup = { clone = d:Clone(), parent = d.Parent }
			d:Destroy()
		end)
	end

	local function wipe_coins()
		for _, v in ipairs(cs:GetTagged("CoinVisual")) do
			pcall(function() v:Destroy() end)
		end
		for _, d in ipairs(ws:GetDescendants()) do
			if d.Name == "CoinContainer" then
				kill_container(d)
			end
		end
	end

	local function restore_coins()
		if last_coin_backup and last_coin_backup.clone then
			pcall(function()
				last_coin_backup.clone.Parent = last_coin_backup.parent or ws
			end)
			last_coin_backup = nil
		end
	end

	local player_gui = lp:FindFirstChildOfClass("PlayerGui")
	local fade_cache = {}
	local fade_conns = {}

	local FADE_GUI_NAMES = { CameraFade = true, SpawnFade = true, Fade = true, DeathFade = true }
	local fade_desc_conn = nil

	local function fade_gui()
		if player_gui and player_gui.Parent then return player_gui end
		player_gui = lp:FindFirstChildOfClass("PlayerGui")
		return player_gui
	end

	local function fade_hide(frame)
		if not frame or not frame.Parent or not frame:IsA("GuiObject") then return end
		if fade_cache[frame] == nil then fade_cache[frame] = frame.Visible end
		if frame.Visible then pcall(function() frame.Visible = false end) end
		if not fade_conns[frame] then
			fade_conns[frame] = frame:GetPropertyChangedSignal("Visible"):Connect(function()
				if fade_on and frame.Visible then
					pcall(function() frame.Visible = false end)
				end
			end)
		end
	end

	local function fade_match(inst)
		if not inst:IsA("GuiObject") then return false end
		local parent = inst.Parent
		if not parent then return false end
		if (inst.Name == "Fade" or inst.Name == "Frame") and parent:IsA("ScreenGui") and FADE_GUI_NAMES[parent.Name] then
			return true
		end
		if inst.Name == "Fade" and parent.Name == "Game" then
			return true
		end
		return false
	end

	local function fade_targets()
		local list = {}
		local gui = fade_gui()
		if not gui then return list end
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("ScreenGui") and FADE_GUI_NAMES[child.Name] then
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("GuiObject") and (sub.Name == "Fade" or sub.Name == "Frame") then
						list[#list + 1] = sub
					end
				end
			end
		end
		local main = gui:FindFirstChild("MainGUI")
		local gg = main and main:FindFirstChild("Game")
		local gf = gg and gg:FindFirstChild("Fade")
		if gf and gf:IsA("GuiObject") then list[#list + 1] = gf end
		return list
	end

	local function fade_watch()
		if fade_desc_conn then return end
		local gui = fade_gui()
		if not gui then return end
		fade_desc_conn = gui.DescendantAdded:Connect(function(d)
			if not fade_on then return end
			if not fade_match(d) then return end
			task.defer(function()
				if fade_on and d.Parent then pcall(fade_hide, d) end
			end)
		end)
	end

	local function fade_apply()
		fade_watch()
		for _, frame in ipairs(fade_targets()) do
			pcall(fade_hide, frame)
		end
	end

	local function fade_restore()
		for _, conn in pairs(fade_conns) do
			pcall(function() conn:Disconnect() end)
		end
		fade_conns = {}
		for frame, v in pairs(fade_cache) do
			if frame and frame.Parent then
				pcall(function()
					frame.BackgroundTransparency = 1
					frame.Visible = v
				end)
			end
		end
		fade_cache = {}
	end

	local FLING_MAX_VEL = 700
	local FLING_MAX_ANG = 90
	local FLING_SNAP_DIST = 60
	local FLING_HOLD = 0.25
	local FLING_SAFE_VEL = 250

	local fling_reg = {}
	local fling_conns = {}
	local fling_attached = false
	local fling_safe_cf = nil
	local fling_hold_until = 0

	local fling_active_since = 0

	local function fling_busy()
		if fly_on then return true end
		if os.clock() < (getgenv().VELOCITY_DESYNC_UNTIL or 0) then return true end
		if (getgenv().FLING_ACTIVE or 0) > 0 then
			local now = os.clock()
			if fling_active_since == 0 then fling_active_since = now end
			if now - fling_active_since < 20 then return true end
			getgenv().FLING_ACTIVE = 0
			fling_active_since = 0
			return false
		end
		fling_active_since = 0
		return false
	end

	local function fling_kill_part(p)
		if fling_cache[p] == nil then fling_cache[p] = p.CanCollide end
		if p.CanCollide then p.CanCollide = false end
	end

	local function fling_unregister(model)
		local entry = fling_reg[model]
		if not entry then return end
		fling_reg[model] = nil
		for i = 1, #entry.conns do
			pcall(function() entry.conns[i]:Disconnect() end)
		end
		for p in pairs(entry.parts) do
			local v = fling_cache[p]
			fling_cache[p] = nil
			if v ~= nil and p.Parent then
				pcall(function() p.CanCollide = v end)
			end
		end
		table.clear(entry.parts)
	end

	local function fling_register(model)
		if not anti_fling or not model then return end
		if fling_reg[model] or model == lp.Character then return end
		local entry = { parts = {}, conns = {} }
		fling_reg[model] = entry
		local function add(d)
			if d:IsA("BasePart") and not entry.parts[d] then
				entry.parts[d] = true
				if anti_fling then pcall(fling_kill_part, d) end
			end
		end
		for _, d in model:GetDescendants() do
			pcall(add, d)
		end
		local function push(c) entry.conns[#entry.conns + 1] = c end
		push(model.DescendantAdded:Connect(function(d)
			if anti_fling then pcall(add, d) end
		end))
		push(model.DescendantRemoving:Connect(function(d)
			if entry.parts[d] then
				entry.parts[d] = nil
				fling_cache[d] = nil
			end
		end))
		push(model.AncestryChanged:Connect(function(_, parent)
			if not parent then fling_unregister(model) end
		end))
	end

	local function fling_is_body(m)
		return m ~= lp.Character
			and m:IsA("Model")
			and m:FindFirstChildOfClass("Humanoid") ~= nil
	end

	local function fling_scan()
		for _, pl in players:GetPlayers() do
			if pl ~= lp and pl.Character then fling_register(pl.Character) end
		end
		for _, m in ws:GetChildren() do
			if fling_is_body(m) then fling_register(m) end
		end
	end

	local function fling_sweep()
		for model, entry in pairs(fling_reg) do
			if not model.Parent or model == lp.Character then
				fling_unregister(model)
			else
				for p in pairs(entry.parts) do
					if p.Parent then
						if p.CanCollide then
							if fling_cache[p] == nil then fling_cache[p] = true end
							p.CanCollide = false
						end
					else
						entry.parts[p] = nil
						fling_cache[p] = nil
					end
				end
			end
		end
	end

	local function fling_guard(full)
		local hrp = get_hrp()
		if not hrp or not hrp.Parent then
			fling_safe_cf = nil
			return
		end
		if fling_busy() then
			fling_safe_cf = nil
			return
		end
		local lin = hrp.AssemblyLinearVelocity
		local ang = hrp.AssemblyAngularVelocity
		local spike = lin.Magnitude > FLING_MAX_VEL or ang.Magnitude > FLING_MAX_ANG
		local now = os.clock()
		if spike then fling_hold_until = now + FLING_HOLD end
		if spike or now < fling_hold_until then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			if full and fling_safe_cf then
				if (hrp.Position - fling_safe_cf.Position).Magnitude > FLING_SNAP_DIST then
					hrp.CFrame = fling_safe_cf
				end
			end
		elseif full and lin.Magnitude < FLING_SAFE_VEL then
			fling_safe_cf = hrp.CFrame
		end
	end

	local function fling_detach()
		fling_attached = false
		for i = 1, #fling_conns do
			pcall(function() fling_conns[i]:Disconnect() end)
		end
		table.clear(fling_conns)
	end

	local function fling_attach()
		if fling_attached then return end
		fling_attached = true
		local function push(c) fling_conns[#fling_conns + 1] = c end
		local function watch(pl)
			if pl == lp then return end
			push(pl.CharacterAdded:Connect(function(c)
				if anti_fling then fling_register(c) end
			end))
			push(pl.CharacterRemoving:Connect(function(c)
				fling_unregister(c)
			end))
		end
		for _, pl in players:GetPlayers() do watch(pl) end
		push(players.PlayerAdded:Connect(function(pl)
			watch(pl)
			if anti_fling and pl.Character then fling_register(pl.Character) end
		end))
		push(players.PlayerRemoving:Connect(function(pl)
			if pl.Character then fling_unregister(pl.Character) end
		end))
		push(ws.ChildAdded:Connect(function(m)
			if not anti_fling then return end
			task.defer(function()
				if anti_fling and m.Parent == ws and fling_is_body(m) then
					fling_register(m)
				end
			end)
		end))
		push(lp.CharacterAdded:Connect(function(c)
			fling_unregister(c)
			fling_safe_cf = nil
			fling_hold_until = 0
			if anti_fling then task.defer(fling_scan) end
		end))
		fling_scan()
	end

	local function fling_restore()
		fling_detach()
		for model in pairs(fling_reg) do
			fling_unregister(model)
		end
		table.clear(fling_reg)
		for p, v in pairs(fling_cache) do
			if p and p.Parent then pcall(function() p.CanCollide = v end) end
		end
		table.clear(fling_cache)
		fling_safe_cf = nil
		fling_hold_until = 0
	end

	local TRAP_LOCK = 1
	local TRAP_HOLD = 5
	local trap_window = 0
	local trap_busy = false
	local trap_speed_cache = 16
	local trap_jump_cache = 50
	local trap_hit_conn = nil

	local function trap_hum()
		local c = lp.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function trap_kill_gui()
		local gui = fade_gui()
		if not gui then return end
		for _, child in ipairs(gui:GetChildren()) do
			if child.Name == "TrapGUI" then
				pcall(function() child:Destroy() end)
			end
		end
	end

	local function trap_unlock(hum)
		if not hum or not hum.Parent then return end
		pcall(function()
			if hum.WalkSpeed <= TRAP_LOCK then hum.WalkSpeed = trap_speed_cache end
			if hum.JumpPower <= TRAP_LOCK then hum.JumpPower = trap_jump_cache end
		end)
	end

	local function trap_engage()
		if not anti_trap then return end
		trap_window = os.clock() + TRAP_HOLD
		local hum = trap_hum()
		if hum then
			if hum.WalkSpeed > TRAP_LOCK then trap_speed_cache = hum.WalkSpeed end
			if hum.JumpPower > TRAP_LOCK then trap_jump_cache = hum.JumpPower end
		end
		trap_kill_gui()
		if trap_busy then return end
		trap_busy = true
		task.spawn(function()
			while anti_trap and os.clock() < trap_window do
				trap_unlock(trap_hum())
				trap_kill_gui()
				run.Heartbeat:Wait()
			end
			trap_busy = false
		end)
	end

	local function trap_attach()
		if trap_hit_conn then return end
		local ok, remote = pcall(function()
			local sys = rs:FindFirstChild("TrapSystem")
			return sys and sys:FindFirstChild("TrapHitLocal")
		end)
		if not ok or not remote then return end
		trap_hit_conn = remote.OnClientEvent:Connect(function()
			task.spawn(trap_engage)
		end)
	end

	local function trap_detach()
		if trap_hit_conn then
			pcall(function() trap_hit_conn:Disconnect() end)
			trap_hit_conn = nil
		end
		trap_window = 0
		trap_unlock(trap_hum())
	end

	local function upd_anti()
		anti_afk = anti_master and afk_set
		local new_void = anti_master and void_set
		if new_void ~= anti_void then
			anti_void = new_void
			pcall(function()
				ws.FallenPartsDestroyHeight = anti_void and -9e9 or void_original
			end)
		end
		local new_fling = anti_master and fling_set
		if new_fling ~= anti_fling then
			anti_fling = new_fling
			if anti_fling then fling_attach() else fling_restore() end
		end
		local new_coin = anti_master and coin_set
		if new_coin ~= coin_on then
			coin_on = new_coin
			if coin_on then wipe_coins() else restore_coins() end
		end
		local new_fade = anti_master and fade_set
		if new_fade ~= fade_on then
			fade_on = new_fade
			if fade_on then fade_apply() else fade_restore() end
		end
		local new_trap = anti_master and trap_set
		if new_trap ~= anti_trap then
			anti_trap = new_trap
			if anti_trap then trap_attach() else trap_detach() end
		end
	end

	local idle_conn = lp.Idled:Connect(function()
		if anti_afk then
			pcall(function()
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end
	end)

	local coin_conn = cs:GetInstanceAddedSignal("CoinVisual"):Connect(function(v)
		if coin_on then
			task.wait()
			if coin_on then pcall(function() v:Destroy() end) end
		end
	end)

	local coin_desc_conn = ws.DescendantAdded:Connect(function(d)
		if coin_on and d.Name == "CoinContainer" then
			task.wait()
			if coin_on then kill_container(d) end
		end
	end)

	local function noclip_restore()
		for p, v in pairs(noclip_cache) do
			if p and p.Parent then p.CanCollide = v end
		end
		noclip_cache = {}
	end

	local part_index = setmetatable({}, { __mode = "k" })

	local function char_parts(char)
		local entry = part_index[char]
		if not entry then
			entry = { list = {}, valid = false }
			part_index[char] = entry
			local function dirty(d)
				if d:IsA("BasePart") then entry.valid = false end
			end
			entry.added = char.DescendantAdded:Connect(dirty)
			entry.removing = char.DescendantRemoving:Connect(dirty)
		end
		if not entry.valid then
			local list = entry.list
			table.clear(list)
			local n = 0
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") then
					n = n + 1
					list[n] = p
				end
			end
			entry.valid = true
		end
		return entry.list
	end

	local function release_part_index()
		for _, entry in pairs(part_index) do
			if entry.added then pcall(function() entry.added:Disconnect() end) end
			if entry.removing then pcall(function() entry.removing:Disconnect() end) end
		end
		part_index = setmetatable({}, { __mode = "k" })
	end

	local step_conn = run.Stepped:Connect(function()
		if anti_fling then
			if not fling_attached then pcall(fling_attach) end
			pcall(fling_sweep)
			pcall(fling_guard, true)
		end
		if noclip_on then
			if (getgenv().FLING_ACTIVE or 0) == 0 then
				local c = lp.Character
				if c then
					local list = char_parts(c)
					for i = 1, #list do
						local p = list[i]
						if p.Parent and p.CanCollide then
							if noclip_cache[p] == nil then noclip_cache[p] = p.CanCollide end
							p.CanCollide = false
						end
					end
				end
			elseif next(noclip_cache) then
				noclip_restore()
			end
		end
	end)

	local fling_beat_conn = run.Heartbeat:Connect(function()
		if anti_fling then
			pcall(fling_guard, false)
		end
	end)

	local controls_ref = nil
	local function get_controls()
		if controls_ref then return controls_ref end
		local ok, res = pcall(function()
			local ps = lp:FindFirstChild("PlayerScripts")
			local pm = ps and ps:FindFirstChild("PlayerModule")
			if not pm then return nil end
			return require(pm):GetControls()
		end)
		if ok and res then controls_ref = res end
		return controls_ref
	end

	local function flat_unit(v)
		local f = Vector3.new(v.X, 0, v.Z)
		if f.Magnitude > 0 then return f.Unit end
		return Vector3.zero
	end

	local function get_move_vector(cam)
		local c = get_controls()
		if c then
			local ok, v = pcall(function() return c:GetMoveVector() end)
			if ok and typeof(v) == "Vector3" and v.Magnitude > 0.05 then
				return v
			end
		end
		local ch = lp.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum and cam then
			local md = hum.MoveDirection
			if md.Magnitude > 0.05 then
				local ff, fr = flat_unit(cam.CFrame.LookVector), flat_unit(cam.CFrame.RightVector)
				return Vector3.new(md:Dot(fr), 0, -md:Dot(ff))
			end
		end
		return Vector3.zero
	end

	local hop_params = RaycastParams.new()
	hop_params.FilterType = Enum.RaycastFilterType.Exclude
	hop_params.IgnoreWater = true
	local hop_ang = { 0, 0.45, -0.45, 0.9, -0.9, 1.4, -1.4, 2, -2, 2.6, -2.6, 3.14 }

	local function hop_wall(hrp, hum)
		local cam = ws.CurrentCamera
		local base = flat_unit(hum.MoveDirection)
		if base == Vector3.zero then
			base = cam and flat_unit(cam.CFrame.LookVector) or Vector3.zero
		end
		if base == Vector3.zero then return nil end
		hop_params.FilterDescendantsInstances = { lp.Character }
		local pos = hrp.Position
		for i = 1, #hop_ang do
			local c, s = math.cos(hop_ang[i]), math.sin(hop_ang[i])
			local dir = Vector3.new(base.X * c + base.Z * s, 0, base.Z * c - base.X * s) * 3
			local hit = ws:Raycast(pos, dir, hop_params)
			if not hit then
				hit = ws:Raycast(pos - Vector3.new(0, 2, 0), dir, hop_params)
			end
			if hit and math.abs(hit.Normal.Y) < 0.5 then return hit end
		end
		return nil
	end

	local jump_hold_t = 0
	local hop_scan_t = 0
	local jump_conn = uis.JumpRequest:Connect(function()
		jump_hold_t = os.clock()
		if fly_on or (not inf_jump_on and not wallhop_on) then return end
		local hrp = get_hrp()
		local ch = lp.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end
		if inf_jump_on then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			return
		end
		if hum.FloorMaterial ~= Enum.Material.Air then return end
		local now = os.clock()
		if now - hop_scan_t < 0.1 then return end
		hop_scan_t = now
		local wall = hop_wall(hrp, hum)
		if not wall then return end
		local n = flat_unit(wall.Normal)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X + n.X * 3, v.Y, v.Z + n.Z * 3)
	end)

	local fly_conn = run.RenderStepped:Connect(function()
		if not fly_on then return end
		local h = get_hrp()
		if not h then return end
		local cam = ws.CurrentCamera
		local dir = Vector3.zero
		if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
		if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
		local mv = get_move_vector(cam)
		if mv.Magnitude > 0.05 then
			dir = dir + cam.CFrame.LookVector * (-mv.Z) + cam.CFrame.RightVector * mv.X
		end
		local jump_held = (os.clock() - jump_hold_t) < 0.2
		if fly_up_on and (uis:IsKeyDown(fly_up_kc) or jump_held) then dir = dir + Vector3.yAxis end
		if fly_down_on and uis:IsKeyDown(fly_down_kc) then dir = dir - Vector3.yAxis end
		if dir.Magnitude > 0 then dir = dir.Unit * fly_speed end
		h.AssemblyLinearVelocity = dir
	end)

	getgenv().MISC_UNLOAD = function()
		anti_master, anti_afk, anti_fling, anti_void = false, false, false, false
		coin_set, coin_on = false, false
		fade_set, fade_on = false, false
		trap_set, anti_trap = false, false
		pcall(function() ws.FallenPartsDestroyHeight = void_original end)
		noclip_on, fly_on = false, false
		inf_jump_on, wallhop_on = false, false
		if idle_conn then pcall(function() idle_conn:Disconnect() end) idle_conn = nil end
		if coin_conn then pcall(function() coin_conn:Disconnect() end) coin_conn = nil end
		if coin_desc_conn then pcall(function() coin_desc_conn:Disconnect() end) coin_desc_conn = nil end
		if fade_desc_conn then pcall(function() fade_desc_conn:Disconnect() end) fade_desc_conn = nil end
		if step_conn then pcall(function() step_conn:Disconnect() end) step_conn = nil end
		if fling_beat_conn then pcall(function() fling_beat_conn:Disconnect() end) fling_beat_conn = nil end
		if fly_conn then pcall(function() fly_conn:Disconnect() end) fly_conn = nil end
		if jump_conn then pcall(function() jump_conn:Disconnect() end) jump_conn = nil end
		trap_detach()
		restore_coins()
		fade_restore()
		noclip_restore()
		fling_restore()
		release_part_index()
		ws.Gravity = fly_gravity
	end
	local surf_on = false
	local surf_speed = 34
	local surf_active = false
	local surf_sign = 0
	local surf_seen = 0
	local surf_lock = nil
	local surf_part = nil
	local surf_conn = nil
	local surf_solid = nil
	local surf_params = RaycastParams.new()
	surf_params.FilterType = Enum.RaycastFilterType.Exclude
	surf_params.IgnoreWater = true

	local SURF_RANGE = 5
	local SURF_LEN = 11
	local SURF_DEPTH = 2.6
	local SURF_THICK = 1.6
	local SURF_UP = 2.9
	local SURF_DOWN = 2.4
	local SURF_ANG = { 0, 0.3, -0.3, 0.62, -0.62, 0.95, -0.95 }
	local SURF_OFF = { -0.35, -0.15, 0.06, 0.26, 0.5, 0.85, 1.25 }
	local SURF_DROP = Vector3.new(0, -(SURF_UP + SURF_DOWN + 0.2), 0)
	local SURF_GROUND = Vector3.new(0, -(SURF_DOWN + 4), 0)

	local surf_ind = CreateIndicator({
		Name = "SURF",
		Icon = "cube-vertexes",
		Color = "White",
	})

	local function surf_platform()
		if not surf_part then
			local p = Instance.new("Part")
			p.Name = "PixelStep"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Transparency = 1
			p.Material = Enum.Material.SmoothPlastic
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 100, 1)
			p.Size = Vector3.new(SURF_LEN, SURF_THICK, SURF_DEPTH)
			surf_part = p
		end
		if surf_part.Parent ~= ws then surf_part.Parent = ws end
		return surf_part
	end

	local function surf_hide()
		if surf_part then
			if surf_part.Parent then surf_part.Parent = nil end
			if surf_solid ~= false then
				surf_solid = false
				surf_part.CanCollide = false
			end
		end
		surf_sign = 0
		surf_lock = nil
		if surf_active then
			surf_active = false
			pcall(function() surf_ind:Set(false) end)
		end
	end

	local function surf_cast(origin, dir)
		surf_params.FilterDescendantsInstances = { lp.Character, surf_part }
		return ws:Raycast(origin, dir, surf_params)
	end

	local function surf_feet(hrp, hum)
		local hip = hum.HipHeight
		if hip > 0 then
			return hrp.Position.Y - hrp.Size.Y * 0.5 - hip
		end
		return hrp.Position.Y - 3
	end

	local function surf_yaw(v, a)
		local c, s = math.cos(a), math.sin(a)
		return Vector3.new(v.X * c + v.Z * s, 0, v.Z * c - v.X * s)
	end

	local function surf_probe(origin, feet, dir)
		local hit = surf_cast(origin, dir)
		if hit and math.abs(hit.Normal.Y) < 0.45 then return hit end
		hit = surf_cast(Vector3.new(origin.X, feet + 0.8, origin.Z), dir)
		if hit and math.abs(hit.Normal.Y) < 0.45 then return hit end
		return nil
	end

	local function surf_wall(hrp, feet, move, look)
		local pos = hrp.Position
		for pass = 1, 2 do
			local base = pass == 1 and move or look
			if base ~= Vector3.zero and (pass == 1 or move == Vector3.zero or move:Dot(look) < 0.99) then
				for i = 1, #SURF_ANG do
					local hit = surf_probe(pos, feet, surf_yaw(base, SURF_ANG[i]) * SURF_RANGE)
					if hit then return hit end
				end
			end
		end
		return nil
	end

	local function surf_scan(hrp, hum, move, look, hold)
		local feet = surf_feet(hrp, hum)
		local wall = surf_wall(hrp, feet, move, look)
		if not wall then return nil end
		local n = flat_unit(wall.Normal)
		if n == Vector3.zero then return nil end
		local ground = surf_cast(hrp.Position, SURF_GROUND)
		local gy = ground and ground.Position.Y or -1e9
		local face = wall.Position
		local best, top, tp
		for i = 1, #SURF_OFF do
			local o = face + n * SURF_OFF[i]
			local hit = surf_cast(Vector3.new(o.X, feet + SURF_UP, o.Z), SURF_DROP)
			if hit and hit.Normal.Y > 0.35 then
				local y = hit.Position.Y
				if y > gy + 0.75 and y < feet + SURF_UP - 0.25 and y > feet - SURF_DOWN then
					local score
					if hold then
						score = math.abs(y - hold)
					elseif y >= feet - 0.3 then
						score = y - feet
					else
						score = 1000 - y
					end
					if not best or score < best then
						best, top, tp = score, y, hit.Position
					end
				end
			end
		end
		if not top then return nil end
		return Vector3.new(tp.X, top, tp.Z), n, feet
	end

	local function surf_step(_, dt)
		if not surf_on then return end
		local char = lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			surf_hide()
			return
		end
		local cam = ws.CurrentCamera
		local move = flat_unit(hum.MoveDirection)
		local look = cam and flat_unit(cam.CFrame.LookVector) or Vector3.zero
		local pos, n, feet = surf_scan(hrp, hum, move, look, surf_active and surf_lock and surf_lock.Y or nil)
		if not pos then
			if os.clock() - surf_seen > 0.3 then surf_hide() end
			return
		end
		local tangent = flat_unit(n:Cross(Vector3.yAxis))
		if tangent == Vector3.zero then return end
		local hp = hrp.Position
		local dx, dz = pos.X - hp.X, pos.Z - hp.Z
		local dist = math.sqrt(dx * dx + dz * dz)
		local push = move ~= Vector3.zero and move:Dot(n) or 0
		if surf_active then
			if dist > 4.5 or push > 0.5 then
				surf_hide()
				return
			end
		elseif hum.FloorMaterial ~= Enum.Material.Air or dist > 2.8 or move == Vector3.zero or push > -0.15 then
			if os.clock() - surf_seen > 0.3 then surf_hide() end
			return
		end
		surf_seen = os.clock()
		local step = math.min(dt or 0.016, 0.1)
		if surf_lock and (surf_lock - pos).Magnitude < 2 then
			pos = surf_lock:Lerp(pos, 1 - math.exp(-16 * step))
		end
		surf_lock = pos
		local p = surf_platform()
		local center = pos + n * (SURF_DEPTH * 0.5 - 0.45) - Vector3.new(0, SURF_THICK * 0.5 + 0.02, 0)
		p.CFrame = CFrame.lookAt(center, center - n)
		local solid = surf_solid
		if feet >= pos.Y - 0.06 then
			solid = true
		elseif feet < pos.Y - 0.55 then
			solid = false
		end
		if surf_solid ~= solid then
			surf_solid = solid
			p.CanCollide = solid
		end
		if not surf_active then
			surf_active = true
			surf_sign = 0
			pcall(function() surf_ind:Set(true) end)
		end
		local along = move:Dot(tangent)
		if math.abs(along) > 0.35 then
			surf_sign = along > 0 and 1 or -1
		elseif surf_sign == 0 then
			surf_sign = (look:Dot(tangent) < 0) and -1 or 1
		end
		local v = hrp.AssemblyLinearVelocity
		local err = pos.Y - feet
		local vy
		if err > 0.05 then
			vy = math.min(err * 14 + 1.5, 34)
		elseif err < -0.4 then
			vy = math.max(v.Y, err * 8)
		elseif v.Y > 0 then
			vy = v.Y
		else
			vy = err * 8
		end
		local blend = 1 - math.exp(-14 * step)
		local cur = v.X * tangent.X + v.Z * tangent.Z
		local speed = cur + (surf_speed * surf_sign - cur) * blend
		local gap = (hp.X - pos.X) * n.X + (hp.Z - pos.Z) * n.Z
		local hug = math.clamp((0.75 - gap) * 9, -9, 9)
		local glide = tangent * speed + n * hug
		hrp.AssemblyLinearVelocity = Vector3.new(glide.X, vy, glide.Z)
	end

	surf_conn = run.Stepped:Connect(surf_step)

	getgenv().PIXEL_SURF_UNLOAD = function()
		surf_on = false
		if surf_conn then pcall(function() surf_conn:Disconnect() end) surf_conn = nil end
		surf_hide()
		if surf_part then
			pcall(function() surf_part:Destroy() end)
			surf_part = nil
		end
		pcall(function() surf_ind:Set(false) end)
	end
	getgenv().MX = {
		setAntiMaster = function(v) anti_master = v upd_anti() end,
		setAfk = function(v) afk_set = v upd_anti() end,
		setFling = function(v) fling_set = v upd_anti() end,
		setVoid = function(v) void_set = v upd_anti() end,
		setCoin = function(v) coin_set = v upd_anti() end,
		setFade = function(v) fade_set = v upd_anti() end,
		setTrap = function(v) trap_set = v upd_anti() end,
		setFly = function(v)
			fly_on = v
			if v then ws.Gravity = 0
			else
				ws.Gravity = fly_gravity
				local h = get_hrp()
				if h then h.AssemblyLinearVelocity = Vector3.zero end
			end
		end,
		setFlySpeed = function(v) fly_speed = v end,
		setFlyUp = function(v) fly_up_on = v end,
		setFlyDown = function(v) fly_down_on = v end,
		setFlyUpKey = function(k)
			local ok, kc = pcall(function() return Enum.KeyCode[k] end)
			if ok and kc then fly_up_kc = kc end
		end,
		setFlyDownKey = function(k)
			local ok, kc = pcall(function() return Enum.KeyCode[k] end)
			if ok and kc then fly_down_kc = kc end
		end,
		setNoclip = function(v)
			noclip_on = v
			if not v then noclip_restore() end
		end,
		setWallhop = function(v) wallhop_on = v end,
		setInfJump = function(v) inf_jump_on = v end,
		setSurf = function(v)
			surf_on = v
			if not v then surf_hide() end
		end,
		setSurfSpeed = function(v) surf_speed = v end,
		unload = function()
			pcall(getgenv().MISC_UNLOAD)
			pcall(getgenv().PIXEL_SURF_UNLOAD)
		end,
	}
end
do
print("[world] init initMisc...")
local ok, err = pcall(initMisc)
print("[world] init initMisc " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ CHAR ENGINE ------------------------------
function initChar()
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local ws = workspace
	local lp = players.LocalPlayer

	local uis = game:GetService("UserInputService")

	local ws_on, ws_value = false, 40
	local jp_on, jp_value = false, 80
	local boost_on, boost_value = false, 40
	local boost_strafe_on = false
	local boost_auto_strafe_on = false
	local ratio_on, ratio_value = false, 100

	local ws_original, jp_original, use_jp_original = nil, nil, nil
	local ratio_multiplier = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	local was_jumping = false
	local is_boosting = false
	local bhop_speed = 0
	local jump_held_at = 0

	uis.JumpRequest:Connect(function()
		jump_held_at = os.clock()
	end)

	local function jump_is_held()
		if os.clock() - jump_held_at < 0.2 then return true end
		if uis:IsKeyDown(Enum.KeyCode.Space) then return true end
		return false
	end

	local last_cam_yaw = nil

	local function cam_yaw()
		local cam = ws.CurrentCamera
		if not cam then return nil end
		local look = cam.CFrame.LookVector
		return math.atan2(-look.X, -look.Z)
	end

	local function get_hum()
		local c = lp.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function get_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local apply_conn = run.Stepped:Connect(function()
		local hum = get_hum()
		if not hum then return end
		if ws_on and hum.WalkSpeed ~= ws_value then
			hum.WalkSpeed = ws_value
		end
		if jp_on then
			if not hum.UseJumpPower then hum.UseJumpPower = true end
			if hum.JumpPower ~= jp_value then hum.JumpPower = jp_value end
		end
	end)

	local boost_conn = run.Heartbeat:Connect(function()
		if not boost_on then
			was_jumping = false
			is_boosting = false
			bhop_speed = 0
			last_cam_yaw = nil
			return
		end
		local hum = get_hum()
		local hrp = get_hrp()
		if not hum or not hrp then
			was_jumping = false
			is_boosting = false
			bhop_speed = 0
			last_cam_yaw = nil
			return
		end
		local state = hum:GetState()
		local jumping = state == Enum.HumanoidStateType.Jumping
		local freefall = state == Enum.HumanoidStateType.Freefall
		local airborne = jumping or freefall

		if boost_strafe_on or boost_auto_strafe_on then
			bhop_speed = 0

			if jumping and not was_jumping then
				local dir = hum.MoveDirection
				if dir.Magnitude < 0.1 then dir = hrp.CFrame.LookVector end
				dir = Vector3.new(dir.X, 0, dir.Z)
				if dir.Magnitude > 0 then
					dir = dir.Unit
					local v = hrp.AssemblyLinearVelocity
					hrp.AssemblyLinearVelocity = Vector3.new(dir.X * boost_value, v.Y, dir.Z * boost_value)
					is_boosting = true
				end
			end

			if is_boosting and airborne then
				if boost_auto_strafe_on then
					local yaw = cam_yaw()
					if yaw and last_cam_yaw then
						local delta = yaw - last_cam_yaw
						while delta > math.pi do delta = delta - math.pi * 2 end
						while delta < -math.pi do delta = delta + math.pi * 2 end
						if math.abs(delta) > 0.0005 then
							local v = hrp.AssemblyLinearVelocity
							local xz = Vector3.new(v.X, 0, v.Z)
							if xz.Magnitude > 1 then
								local rotated = CFrame.fromEulerAnglesYXZ(0, delta, 0) * xz
								hrp.AssemblyLinearVelocity = Vector3.new(rotated.X, v.Y, rotated.Z)
							end
						end
					end
				end

				local dir = hum.MoveDirection
				if dir.Magnitude > 0.1 then
					dir = Vector3.new(dir.X, 0, dir.Z).Unit
					local v = hrp.AssemblyLinearVelocity
					local current_xz = Vector3.new(v.X, 0, v.Z)
					local target = dir * boost_value
					local new_xz = current_xz:Lerp(target, 0.3)
					hrp.AssemblyLinearVelocity = Vector3.new(new_xz.X, v.Y, new_xz.Z)
				elseif boost_auto_strafe_on then
					local v = hrp.AssemblyLinearVelocity
					local xz = Vector3.new(v.X, 0, v.Z)
					if xz.Magnitude > 0.1 and xz.Magnitude < boost_value then
						local keep = xz.Unit * boost_value
						hrp.AssemblyLinearVelocity = Vector3.new(keep.X, v.Y, keep.Z)
					end
				end
			end

			if not airborne then
				is_boosting = false
			end
		else
			local base = math.max(hum.WalkSpeed, 1)
			local cap = math.max(boost_value, base)
			local step = math.max(boost_value * 0.1, 1)
			if bhop_speed < base then bhop_speed = base end

			if jumping and not was_jumping then
				bhop_speed = math.min(bhop_speed + step, cap)
				local v = hrp.AssemblyLinearVelocity
				local xz = Vector3.new(v.X, 0, v.Z)
				local dir
				if xz.Magnitude > 0.1 then
					dir = xz.Unit
				else
					local md = hum.MoveDirection
					if md.Magnitude > 0.1 then
						dir = Vector3.new(md.X, 0, md.Z).Unit
					else
						local lv = hrp.CFrame.LookVector
						dir = Vector3.new(lv.X, 0, lv.Z)
						dir = (dir.Magnitude > 0) and dir.Unit or Vector3.new(0, 0, 0)
					end
				end
				if dir.Magnitude > 0 then
					hrp.AssemblyLinearVelocity = Vector3.new(dir.X * bhop_speed, v.Y, dir.Z * bhop_speed)
					is_boosting = true
				end
			end

			if airborne and is_boosting then
				local v = hrp.AssemblyLinearVelocity
				local xz = Vector3.new(v.X, 0, v.Z)
				local md = hum.MoveDirection
				local dir
				if md.Magnitude > 0.1 then
					dir = Vector3.new(md.X, 0, md.Z).Unit
				elseif xz.Magnitude > 0.1 then
					dir = xz.Unit
				end
				if dir then
					local speed = math.max(xz.Magnitude, bhop_speed)
					hrp.AssemblyLinearVelocity = Vector3.new(dir.X * speed, v.Y, dir.Z * speed)
				end
			end

			if not airborne then
				is_boosting = false
				if jump_is_held() then
					hum.Jump = true
				else
					bhop_speed = 0
				end
			end
		end

		last_cam_yaw = cam_yaw()
		was_jumping = jumping
	end)

	run:BindToRenderStep("shitaro_aspect", Enum.RenderPriority.Camera.Value + 1, function()
		if not ratio_on then return end
		local cam = ws.CurrentCamera
		if cam and typeof(ratio_multiplier) == "CFrame" then
			pcall(function() cam.CFrame = cam.CFrame * ratio_multiplier end)
		end
	end)


	lp.CharacterAdded:Connect(function()
		task.wait(0.1)
		if fov_on then
			local cam = ws.CurrentCamera
			if cam then
				if not fov_original then fov_original = cam.FieldOfView end
				cam.FieldOfView = fov_value
			end
		end
	end)

	getgenv().CHARACTER_UNLOAD = function()
		ws_on, jp_on, boost_on, ratio_on, fov_on = false, false, false, false, false
		if apply_conn then pcall(function() apply_conn:Disconnect() end) apply_conn = nil end
		if boost_conn then pcall(function() boost_conn:Disconnect() end) boost_conn = nil end
		if fov_conn then pcall(function() fov_conn:Disconnect() end) fov_conn = nil end
		pcall(function() run:UnbindFromRenderStep("shitaro_aspect") end)
		local hum = get_hum()
		if hum then
			if ws_original then pcall(function() hum.WalkSpeed = ws_original end) end
			if use_jp_original ~= nil then pcall(function() hum.UseJumpPower = use_jp_original end) end
			if jp_original then pcall(function() hum.JumpPower = jp_original end) end
		end
		local cam = ws.CurrentCamera
		if cam and fov_original then
			pcall(function() cam.FieldOfView = fov_original end)
		end
	end
	local players = game:GetService("Players")
	local lp = players.LocalPlayer

	local korblox_on, headless_on = false, false
	local korblox_backup = {}
	local head_backup = {}
	local char_conn = nil

	local function restore_korblox()
		local c = lp.Character
		if not c then return end
		
		local ru = c:FindFirstChild("RightUpperLeg")
		local rl = c:FindFirstChild("RightLowerLeg")
		local rf = c:FindFirstChild("RightFoot")
		
		if ru and korblox_backup.RU then
			pcall(function()
				ru.TextureID = korblox_backup.RU.TextureID or ""
				ru.MeshId = korblox_backup.RU.MeshId or ""
			end)
		end
		if rl and korblox_backup.RL then
			pcall(function()
				rl.MeshId = korblox_backup.RL.MeshId or ""
				rl.Transparency = korblox_backup.RL.Transparency or 0
			end)
		end
		if rf and korblox_backup.RF then
			pcall(function()
				rf.MeshId = korblox_backup.RF.MeshId or ""
				rf.Transparency = korblox_backup.RF.Transparency or 0
			end)
		end
		korblox_backup = {}
	end

	local function restore_headless()
		local c = lp.Character
		if not c then return end
		local head = c:FindFirstChild("Head")
		if head and head_backup.Head then
			pcall(function()
				head.Transparency = head_backup.Head
				if head_backup.MeshId then head.MeshId = head_backup.MeshId end
				if head_backup.TextureID then head.TextureID = head_backup.TextureID end
			end)
		end
		for _, v in ipairs(head_backup.Children or {}) do
			if v.Obj and v.Obj.Parent then
				pcall(function() v.Obj.Transparency = v.Val end)
			end
		end
		head_backup = {}
	end

	local function apply_korblox()
		if not korblox_on then return end
		local c = lp.Character
		if not c then return end
		
		local ru = c:FindFirstChild("RightUpperLeg")
		local rl = c:FindFirstChild("RightLowerLeg")
		local rf = c:FindFirstChild("RightFoot")
		
		if not ru then return end
		
		korblox_backup = {}
		
		if ru then
			korblox_backup.RU = {
				MeshId = ru.MeshId,
				TextureID = ru.TextureID
			}
			pcall(function()
				ru.MeshId = "rbxassetid://902942096"
				ru.TextureID = "rbxassetid://902843398"
			end)
		end
		if rl then
			korblox_backup.RL = {
				MeshId = rl.MeshId,
				Transparency = rl.Transparency
			}
			pcall(function()
				rl.MeshId = "rbxassetid://902942093"
				rl.Transparency = 1
			end)
		end
		if rf then
			korblox_backup.RF = {
				MeshId = rf.MeshId,
				Transparency = rf.Transparency
			}
			pcall(function()
				rf.MeshId = "rbxassetid://902942089"
				rf.Transparency = 1
			end)
		end
	end

	local function apply_headless()
		if not headless_on then return end
		restore_headless()
		local c = lp.Character
		if not c then return end
		local head = c:FindFirstChild("Head")
		if not head then return end

		head_backup.Head = head.Transparency
		head_backup.MeshId = head.MeshId
		head_backup.TextureID = head.TextureID
		head_backup.Children = {}
		
		pcall(function()
			head.MeshId = "rbxassetid://6686307858"
			head.TextureID = "rbxassetid://6686307858"
			head.Transparency = 1
		end)
		
		for _, child in ipairs(head:GetDescendants()) do
			if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("MeshPart") or child:IsA("SpecialMesh") then
				local hasTrans = pcall(function() return child.Transparency end)
				if hasTrans then
					local original = child.Transparency
					head_backup.Children[#head_backup.Children+1] = {Obj = child, Val = original}
					pcall(function() child.Transparency = 1 end)
				end
			end
		end
	end
	local fov_on, fov_value = false, 70
	local fov_original = nil
	local fov_conn = nil
	local function char_reapply()
		if korblox_on then apply_korblox() end
		if headless_on then apply_headless() end
	end
	local char_reconn = lp.CharacterAdded:Connect(function()
		task.wait(1)
		char_reapply()
	end)
	getgenv().CX = {
		setWs = function(v)
			local hum = get_hum()
			if v then
				if hum then ws_original = hum.WalkSpeed end
				ws_on = true
			else
				ws_on = false
				if hum and ws_original then hum.WalkSpeed = ws_original end
			end
		end,
		setWsVal = function(v) ws_value = v end,
		setJp = function(v)
			local hum = get_hum()
			if v then
				if hum then
					use_jp_original = hum.UseJumpPower
					jp_original = hum.JumpPower
				end
				jp_on = true
			else
				jp_on = false
				if hum then
					if use_jp_original ~= nil then hum.UseJumpPower = use_jp_original end
					if jp_original then hum.JumpPower = jp_original end
				end
			end
		end,
		setJpVal = function(v) jp_value = v end,
		setBhop = function(v) boost_on = v end,
		setBhopPower = function(v) boost_value = v end,
		setStrafe = function(v) boost_strafe_on = v end,
		setAutoStrafe = function(v) boost_auto_strafe_on = v end,
		setAspect = function(v) ratio_on = v end,
		setAspectVal = function(v)
			ratio_value = v
			ratio_multiplier = CFrame.new(0, 0, 0, 1, 0, 0, 0, v / 100, 0, 0, 0, 1)
		end,
		setFov = function(v)
			fov_on = v
			local cam = ws.CurrentCamera
			if v then
				if cam then
					fov_original = cam.FieldOfView
					cam.FieldOfView = fov_value
				end
				if not fov_conn then
					fov_conn = run.RenderStepped:Connect(function()
						if fov_on then
							local camera = ws.CurrentCamera
							if camera and camera.FieldOfView ~= fov_value then
								camera.FieldOfView = fov_value
							end
						end
					end)
				end
			else
				if cam and fov_original then
					cam.FieldOfView = fov_original
				end
				if fov_conn then
					pcall(function() fov_conn:Disconnect() end)
					fov_conn = nil
				end
			end
		end,
		setFovVal = function(v)
			fov_value = v
			if fov_on then
				local cam = ws.CurrentCamera
				if cam then cam.FieldOfView = v end
			end
		end,
		setKorblox = function(v)
			korblox_on = v
			if v then apply_korblox() else restore_korblox() end
		end,
		setHeadless = function(v)
			headless_on = v
			if v then apply_headless() else restore_headless() end
		end,
		reset = function()
			local c = lp.Character
			local hum = c and c:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Dead)
			elseif c then
				pcall(function() c:BreakJoints() end)
			end
		end,
		unload = function()
			pcall(getgenv().CHARACTER_UNLOAD)
			korblox_on, headless_on = false, false
			pcall(restore_korblox)
			pcall(restore_headless)
			if char_reconn then pcall(function() char_reconn:Disconnect() end) end
		end,
	}
end
do
print("[world] init initChar...")
local ok, err = pcall(initChar)
print("[world] init initChar " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ MODEL CHANGER (simplified) ------------------------------
function initModel()
	local players = game:GetService("Players")
	local mkt = game:GetService("MarketplaceService")
	local lp = players.LocalPlayer

	local MO = {
		on = false, pick = nil, list = {}, inst = nil,
		conn = nil, charConn = nil, hidden = {}, gen = 0,
	}

	local function ids_in(text)
		local out, seen = {}, {}
		if type(text) ~= "string" then return out end
		for run in string.gmatch(text, "%d+") do
			if #run >= 5 and #run <= 19 and not seen[run] then
				seen[run] = true
				out[#out + 1] = run
			end
		end
		return out
	end

	local function title_of(info, id)
		if info and type(info.Name) == "string" and info.Name ~= "" then return info.Name end
		return "model " .. id
	end

	local function model_clear()
		MO.gen = MO.gen + 1
		if MO.conn then pcall(function() MO.conn:Disconnect() end) MO.conn = nil end
		if MO.inst then pcall(function() MO.inst:Destroy() end) MO.inst = nil end
		local c = lp.Character
		if c then
			for p, d in pairs(MO.hidden) do
				if p and p.Parent then
					pcall(function()
						p.Transparency = d.tr
						if d.decals then
							for _, dc in ipairs(d.decals) do
								if dc[1] and dc[1].Parent == nil then dc[1].Parent = p end
							end
						end
					end)
				end
			end
		end
		MO.hidden = {}
	end

	local function model_use(entry)
		model_clear()
		if not entry then return end
		local gen = MO.gen
		task.spawn(function()
			local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. entry.Id) end)
			if not ok or type(objs) ~= "table" or gen ~= MO.gen or not MO.on then return end
			local tpl = nil
			for _, o in ipairs(objs) do
				if o:IsA("Model") then tpl = o break end
			end
			if not tpl then
				for _, o in ipairs(objs) do
					pcall(function() o:Destroy() end)
				end
				return
			end
			for _, d in ipairs(tpl:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
					pcall(function() d:Destroy() end)
				elseif d:IsA("Humanoid") then
					pcall(function() d:Destroy() end)
				end
			end
			local c = lp.Character
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local hum = c:FindFirstChildOfClass("Humanoid")
			local clone = tpl:Clone()
			pcall(function() tpl:Destroy() end)
			local _, charSize = c:GetBoundingBox()
			local _, rawSize = clone:GetBoundingBox()
			if rawSize.Y > 0.05 and charSize.Y > 0.05 then
				local sc = charSize.Y / rawSize.Y
				if math.abs(sc - 1) > 0.02 then
					pcall(function() clone:ScaleTo(sc) end)
				end
			end
			local box, size = clone:GetBoundingBox()
			local pivotFix = (clone:GetPivot():Inverse() * box):Inverse()
			local yOff = size.Y * 0.5 - hrp.Size.Y * 0.5 - (hum and hum.HipHeight or 0)
			clone.Name = "WORLD_FAKE_MODEL"
			clone.Parent = workspace
			MO.inst = clone
			for _, p in c:GetDescendants() do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					if not MO.hidden[p] then
						local decals = {}
						for _, dc in ipairs(p:GetChildren()) do
							if dc:IsA("Decal") or dc:IsA("Texture") then
								decals[#decals + 1] = { dc }
								pcall(function() dc.Parent = nil end)
							end
						end
						MO.hidden[p] = { tr = p.Transparency, decals = decals }
						pcall(function() p.Transparency = 1 end)
					end
				end
			end
			MO.conn = game:GetService("RunService").RenderStepped:Connect(function()
				if not MO.on or not clone.Parent then return end
				local ch = lp.Character
				local root = ch and ch:FindFirstChild("HumanoidRootPart")
				if not root then return end
				local cf = root.CFrame
				local look = cf.LookVector
				clone:PivotTo(CFrame.new(cf.Position.X, cf.Position.Y + yOff, cf.Position.Z)
					* CFrame.fromEulerAnglesYXZ(0, math.atan2(-look.X, -look.Z), 0)
					* pivotFix)
			end)
		end)
	end

	local refreshList = nil

	local function model_add(text)
		local ids = ids_in(text)
		if #ids == 0 then return false end
		task.spawn(function()
			local picked = nil
			for i = 1, #ids do
				local id = ids[i]
				local dup = false
				for _, e in ipairs(MO.list) do
					if e.Id == id then dup = true break end
				end
				if not dup then
					local ok, info = pcall(function() return mkt:GetProductInfo(tonumber(id)) end)
					local entry = { Name = title_of(ok and info or nil, id), Id = id }
					MO.list[#MO.list + 1] = entry
					picked = entry
				end
			end
			if refreshList then pcall(refreshList) end
			if picked and MO.on then
				MO.pick = picked.Name
				model_use(picked)
				if refreshList then pcall(refreshList) end
			end
		end)
		return true
	end

	local function model_forget(entry)
		for i = 1, #MO.list do
			if MO.list[i] == entry then
				table.remove(MO.list, i)
				break
			end
		end
		if MO.pick == entry.Name then
			MO.pick = nil
			model_clear()
		end
		if refreshList then pcall(refreshList) end
	end

	local function model_choose(name)
		for _, e in ipairs(MO.list) do
			if e.Name == name then
				MO.pick = name
				if MO.on then model_use(e) end
				if refreshList then pcall(refreshList) end
				return
			end
		end
	end

	MO.charConn = lp.CharacterAdded:Connect(function()
		task.wait(1)
		if MO.on and MO.pick then
			model_choose(MO.pick)
		end
	end)

	getgenv().MDL = {
		setOn = function(v)
			MO.on = v
			if v then
				if MO.pick then model_choose(MO.pick) end
			else
				model_clear()
			end
		end,
		names = function()
			local out = {}
			for _, e in ipairs(MO.list) do out[#out + 1] = e.Name end
			return out
		end,
		entries = function() return MO.list end,
		pick = function() return MO.pick end,
		choose = model_choose,
		add = model_add,
		forget = model_forget,
		copyId = function(entry)
			if type(setclipboard) == "function" and entry then
				pcall(setclipboard, tostring(entry.Id))
			end
		end,
		setRefresh = function(fn) refreshList = fn end,
		unload = function()
			MO.on = false
			model_clear()
			if MO.charConn then pcall(function() MO.charConn:Disconnect() end) MO.charConn = nil end
		end,
	}
end
do
print("[world] init initModel...")
local ok, err = pcall(initModel)
print("[world] init initModel " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end
------------------------------ GUI helpers 2 + BUILD: EFFECTS/MISC/CHARACTER ------------------------------
local function TKey(parent, name, def, cb)
	local key = def
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local b = mk("TextButton", {
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundColor3 = C(30, 30, 40), BorderSizePixel = 0,
		Text = key, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	local capture = false
	b.MouseButton1Click:Connect(function()
		capture = true
		b.Text = "..."
	end)
	UIS.InputBegan:Connect(function(inp, gpe)
		if capture and inp.UserInputType == Enum.UserInputType.Keyboard then
			local nm = inp.KeyCode.Name
			if nm and nm ~= "Unknown" then
				key = nm
				b.Text = nm
				capture = false
				pcall(cb, nm)
				playSnd()
			end
		end
	end)
	cfgReg(CurSec, name, {
		type = "key",
		get = function() return key end,
		set = function(v)
			if type(v) ~= "string" or v == "" then return end
			local ok, kc = pcall(function() return Enum.KeyCode[v] end)
			if ok and kc then
				key = v
				b.Text = v
				pcall(cb, v)
			end
		end,
	})
end

local function TInput(parent, name, placeholder, btnText, cb)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
	mk("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0), BackgroundTransparency = 1,
		Text = name, Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local box = mk("TextBox", {
		Position = UDim2.new(0.3, 0, 0, 0), Size = UDim2.new(0.42, -4, 1, 0),
		BackgroundColor3 = C(30, 30, 40), BorderSizePixel = 0,
		Text = "", PlaceholderText = placeholder or "",
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TXT,
		PlaceholderColor3 = FAINT, ClearTextOnFocus = false,
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
	local b = mk("TextButton", {
		Position = UDim2.new(0.72, 0, 0, 0), Size = UDim2.new(0.28, 0, 1, 0),
		BackgroundColor3 = C(45, 45, 60), BorderSizePixel = 0,
		Text = btnText, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
	}, row)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	b.MouseButton1Click:Connect(function()
		local t = box.Text
		if t and t ~= "" then
			pcall(cb, t)
			box.Text = ""
		end
	end)
end

local function TBtn(parent, name, cb)
	local b = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C(45, 45, 60), BorderSizePixel = 0,
		Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TXT,
	}, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
	b.MouseButton1Click:Connect(function()
		pcall(cb)
		playSnd()
	end)
end

------------------------------ BUILD: EFFECTS (visuals tab) ------------------------------
do
	local FXM, FXP, FXT = getgenv().FXM, getgenv().FXP, getgenv().FXT

	do
		local sec = Section(pVis, "murder", "right")
		local opt = TRow(sec, "murder", false, function(v)
			FXM.st.on = v
			if v then FXM.start() else FXM.stop() end
		end, true)
		TRow(opt, "clone", false, function(v) FXM.st.clone = v end, false)
		TColor(opt, "color", FXM.st.cloneCol, function(c)
			FXM.st.cloneCol = c
			FXM.recolorClones()
		end)
		TSlider(opt, "duration", 1, 5, FXM.st.cloneDur, 1, function(v) FXM.st.cloneDur = v end)
		TRow(opt, "particle", false, function(v) FXM.st.part = v end, false)
		TColor(opt, "particle color", FXM.st.partCol, function(c) FXM.st.partCol = c end)
		TRow(opt, "emitter", false, function(v) FXM.st.emit = v end, false)
		TColor(opt, "emitter color", FXM.st.emitCol, function(c)
			FXM.st.emitCol = c
			FXM.recolorEmit()
		end)
		TSlider(opt, "emitter duration", 1, 5, FXM.st.emitDur, 1, function(v) FXM.st.emitDur = v end)
	end

	do
		local sec = Section(pVis, "players", "right")
		local opt = TRow(sec, "players", false, function(v)
			FXP.st.on = v
			if v then FXP.start() else FXP.stop() end
		end, true)
		TRow(opt, "clone", false, function(v) FXP.st.clone = v end, false)
		TColor(opt, "color", FXP.st.cloneCol, function(c)
			FXP.st.cloneCol = c
			FXP.recolorClones()
		end)
		TSlider(opt, "duration", 1, 5, FXP.st.cloneDur, 1, function(v) FXP.st.cloneDur = v end)
		TRow(opt, "particle", false, function(v) FXP.st.part = v end, false)
		TColor(opt, "particle color", FXP.st.partCol, function(c) FXP.st.partCol = c end)
		TRow(opt, "emitter", false, function(v) FXP.st.emit = v end, false)
		TColor(opt, "emitter color", FXP.st.emitCol, function(c)
			FXP.st.emitCol = c
			FXP.recolorEmit()
		end)
		TSlider(opt, "emitter duration", 1, 5, FXP.st.emitDur, 1, function(v) FXP.st.emitDur = v end)
	end

	do
		local sec = Section(pVis, "bullet tracer", "right")
		local opt = TRow(sec, "bullet tracer", false, function(v)
			getgenv().SHERIFF_TRACER_ENABLED = v
			if v then FXT.start() else FXT.stop() end
		end, true)
		TColor(opt, "color", getgenv().SHERIFF_TRACER_COLOR, function(c)
			getgenv().SHERIFF_TRACER_COLOR = c
		end)
		TSlider(opt, "duration", 0.1, 5, getgenv().SHERIFF_TRACER_DURATION, 1, function(v)
			getgenv().SHERIFF_TRACER_DURATION = v
		end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		FXM.st.on = false FXM.stop()
		FXP.st.on = false FXP.stop()
		FXT.stop()
	end)
end

------------------------------ BUILD: MISC + CHARACTER (player tab) ------------------------------
do
	local MX, MXF, CX, MDL = getgenv().MX, getgenv().MXF, getgenv().CX, getgenv().MDL

	do
		local sec = Section(pPlayer, "anti", "left")
		local opt = TRow(sec, "anti", false, function(v) MX.setAntiMaster(v) end, true)
		TRow(opt, "afk", false, function(v) MX.setAfk(v) end, false)
		TRow(opt, "fling", false, function(v) MX.setFling(v) end, false)
		TRow(opt, "void kill", false, function(v) MX.setVoid(v) end, false)
		TRow(opt, "coin", false, function(v) MX.setCoin(v) end, false)
		TRow(opt, "fade", false, function(v) MX.setFade(v) end, false)
		TRow(opt, "trap", false, function(v) MX.setTrap(v) end, false)
	end

	do
		local sec = Section(pPlayer, "fake", "left")
		local opt = TRow(sec, "fake", false, function(v) MXF.fake(v) end, true)
		TSlider(opt, "x", 1, 9, 9, 0, function(v) getgenv().FAKE_POS_RANGE_X = v * 1e9 end)
		TSlider(opt, "y", 1, 9, 9, 0, function(v) getgenv().FAKE_POS_RANGE_Y = v * 1e9 end)
		TSlider(opt, "z", 1, 9, 9, 0, function(v) getgenv().FAKE_POS_RANGE_Z = v * 1e9 end)
		TRow(opt, "marker", true, function(v) MXF.setMarker(v) end, false)
		TColor(opt, "color", Color3.fromRGB(193, 247, 255), function(c) MXF.setMarkerCol(c) end)
	end

	do
		local sec = Section(pPlayer, "velocity spoof", "left")
		local opt = TRow(sec, "velocity spoof", false, function(v) MXF.vel(v) end, true)
		TDrop(opt, "preset", { "low", "high", "y high", "limit", "zero" }, "low", function(v) MXF.setVelType(v) end)
	end

	do
		local sec = Section(pPlayer, "wallhop", "left")
		TRow(sec, "wallhop", false, function(v) MX.setWallhop(v) end, false)
	end

	do
		local sec = Section(pPlayer, "pixel surf", "left")
		local opt = TRow(sec, "pixel surf", false, function(v) MX.setSurf(v) end, true)
		TSlider(opt, "speed", 8, 90, 34, 0, function(v) MX.setSurfSpeed(v) end)
	end

	do
		local sec = Section(pPlayer, "bhop", "right")
		local opt = TRow(sec, "bhop", false, function(v) CX.setBhop(v) end, true)
		TSlider(opt, "Power", 10, 150, 40, 0, function(v) CX.setBhopPower(v) end)
		TRow(opt, "Strafe", false, function(v) CX.setStrafe(v) end, false)
		TRow(opt, "Auto Strafe", false, function(v) CX.setAutoStrafe(v) end, false)
	end

	do
		local sec = Section(pPlayer, "aspect ratio", "right")
		local opt = TRow(sec, "aspect ratio", false, function(v) CX.setAspect(v) end, true)
		TSlider(opt, "Value", 1, 100, 100, 0, function(v) CX.setAspectVal(v) end)
	end

	do
		local sec = Section(pPlayer, "custom fov", "right")
		local opt = TRow(sec, "custom fov", false, function(v) CX.setFov(v) end, true)
		TSlider(opt, "Value", 30, 120, 70, 0, function(v) CX.setFovVal(v) end)
	end

	do
		local sec = Section(pPlayer, "fly", "right")
		local opt = TRow(sec, "fly", false, function(v) MX.setFly(v) end, true)
		TSlider(opt, "speed", 10, 300, 60, 0, function(v) MX.setFlySpeed(v) end)
		TRow(opt, "up", true, function(v) MX.setFlyUp(v) end, false)
		TRow(opt, "down", true, function(v) MX.setFlyDown(v) end, false)
		TKey(opt, "up key", "Space", function(k) MX.setFlyUpKey(k) end)
		TKey(opt, "down key", "LeftControl", function(k) MX.setFlyDownKey(k) end)
	end

	do
		local sec = Section(pPlayer, "noclip", "right")
		TRow(sec, "noclip", false, function(v) MX.setNoclip(v) end, false)
	end

	do
		local sec = Section(pPlayer, "infinite jump", "right")
		TRow(sec, "infinite jump", false, function(v) MX.setInfJump(v) end, false)
	end

	do
		local sec = Section(pPlayer, "walkspeed", "right")
		local opt = TRow(sec, "walkspeed", false, function(v) CX.setWs(v) end, true)
		TSlider(opt, "Value", 16, 300, 40, 0, function(v) CX.setWsVal(v) end)
	end

	do
		local sec = Section(pPlayer, "jumppower", "right")
		local opt = TRow(sec, "jumppower", false, function(v) CX.setJp(v) end, true)
		TSlider(opt, "Value", 0, 500, 80, 0, function(v) CX.setJpVal(v) end)
	end

	do
		local sec = Section(pPlayer, "fake korblox", "right")
		TRow(sec, "fake korblox", false, function(v) CX.setKorblox(v) end, false)
	end

	do
		local sec = Section(pPlayer, "fake headless", "right")
		TRow(sec, "fake headless", false, function(v) CX.setHeadless(v) end, false)
	end

	do
		local sec = Section(pPlayer, "model changer", "right")
		local opt = TRow(sec, "model changer", false, function(v) MDL.setOn(v) end, true)
		local dropRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, opt)
		mk("TextLabel", {
			Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1,
			Text = "Model", Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
		}, dropRow)
		local pickBtn = mk("TextButton", {
			Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
			BackgroundTransparency = 1, Text = "none  ▾",
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
			TextXAlignment = Enum.TextXAlignment.Right, AutoButtonColor = false,
		}, dropRow)
		pickBtn.MouseButton1Click:Connect(function()
			local names = MDL.names()
			if #names == 0 then return end
			local cur = MDL.pick()
			local idx = 0
			for i, n in ipairs(names) do
				if n == cur then idx = i break end
			end
			idx = idx % #names + 1
			pickBtn.Text = names[idx] .. "  ▾"
			MDL.choose(names[idx])
		end)
		TInput(opt, "Models", "model id or link", "add", function(t) MDL.add(t) end)
		local listHost = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, opt)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)
		local function refreshModels()
			for _, ch in ipairs(listHost:GetChildren()) do
				if ch:IsA("GuiObject") then ch:Destroy() end
			end
			for _, e in ipairs(MDL.entries()) do
				local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, listHost)
				local isPick = MDL.pick() == e.Name
				mk("TextLabel", {
					Size = UDim2.new(1, -76, 1, 0), BackgroundTransparency = 1,
					Text = (isPick and "● " or "") .. e.Name,
					Font = Enum.Font.Gotham, TextSize = 12,
					TextColor3 = isPick and ACCENT or TXT,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local useB = mk("TextButton", {
					Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 34, 1, 0),
					BackgroundTransparency = 1, Text = "use",
					Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
				}, row)
				useB.MouseButton1Click:Connect(function() MDL.choose(e.Name) end)
				local idB = mk("TextButton", {
					Position = UDim2.new(1, -38, 0, 0), Size = UDim2.new(0, 20, 1, 0),
					BackgroundTransparency = 1, Text = "id",
					Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM,
				}, row)
				idB.MouseButton1Click:Connect(function() MDL.copyId(e) end)
				local xB = mk("TextButton", {
					Position = UDim2.new(1, -18, 0, 0), Size = UDim2.new(0, 18, 1, 0),
					BackgroundTransparency = 1, Text = "x",
					Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM,
				}, row)
				xB.MouseButton1Click:Connect(function() MDL.forget(e) end)
			end
			local pk = MDL.pick()
			pickBtn.Text = (pk or "none") .. "  ▾"
		end
		MDL.setRefresh(refreshModels)
		refreshModels()
	end

	do
		local sec = Section(pPlayer, "reset", "right")
		TBtn(sec, "reset", function() CX.reset() end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		getgenv().MXF.unload()
		getgenv().MX.unload()
		getgenv().CX.unload()
		getgenv().MDL.unload()
	end)
end
------------------------------ SHERIFF ENGINE ------------------------------
function initSheriff()
	local rs = game:GetService("ReplicatedStorage")
	local players = game:GetService("Players")
	local collection = game:GetService("CollectionService")
	local run = game:GetService("RunService")
	local lp = players.LocalPlayer

	local stats = game:GetService("Stats")

	getgenv().SILENT_S = {
		enabled = false,
		predict = true,
		force = false,
		auto_on = false,
		auto_delay = 0,
		am_sheriff = false,
		fire_gap = 0,
		last_shot = 0,
		stand_off = 15,
	}
	local S = getgenv().SILENT_S

	local MAX_RANGE = 300

	local gap_min = 0
	local gap_seen = false
	local gap_gun = nil
	local want_since = 0

	local function gap_reset()
		gap_min = 0
		gap_seen = false
		S.fire_gap = 0
	end

	local function gap_push(value)
		if value <= 0 then return end
		if not gap_seen or value < gap_min then
			gap_min = value
			gap_seen = true
			S.fire_gap = value
		end
	end

	local round_mod = nil

	local function get_round()
		if round_mod then return round_mod end
		local ok, m = pcall(function()
			return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
		end)
		if ok and type(m) == "table" then round_mod = m end
		return round_mod
	end

	local function holds(container, name)
		return container ~= nil and container:FindFirstChild(name) ~= nil
	end

	local function lp_has_gun()
		return holds(lp.Character, "Gun") or holds(lp:FindFirstChildOfClass("Backpack"), "Gun")
	end

	local target_player = nil
	local target_char = nil
	local target_part = nil
	local target_hum = nil

	local function refresh_target()
		local found = nil
		local m = get_round()
		local data = m and m.PlayerData or nil
		if type(data) == "table" then
			local me = data[lp.Name]
			S.am_sheriff = (me ~= nil and (me.Role == "Sheriff" or me.Role == "Hero")) or lp_has_gun()
			for name, d in pairs(data) do
				if type(d) == "table" and d.Role == "Murderer" and not d.Dead then
					found = players:FindFirstChild(name)
					break
				end
			end
		else
			S.am_sheriff = lp_has_gun()
		end
		if not found then
			for _, plr in ipairs(players:GetPlayers()) do
				if plr ~= lp and holds(plr.Character, "Knife") then
					found = plr
					break
				end
			end
		end
		if found ~= target_player then
			target_player = found
			target_char = nil
			target_part = nil
			target_hum = nil
		end
		if not found then return end
		local char = found.Character
		if char ~= target_char then
			target_char = char
			target_part = nil
			target_hum = nil
		end
		if not char then return end
		if not target_part or not target_part.Parent then
			target_part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		end
		if not target_hum or not target_hum.Parent then
			target_hum = char:FindFirstChildOfClass("Humanoid")
		end
	end

	local function target_alive()
		if not target_part or not target_part.Parent then return false end
		if not target_hum or not target_hum.Parent then return false end
		return target_hum.Health > 0
	end

	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.IgnoreWater = false

	local ignore_base = {}
	local ignore_work = {}
	local ignore_time = 0

	local function refresh_ignore()
		local now = os.clock()
		if #ignore_base > 0 and now - ignore_time < 0.5 then return end
		ignore_time = now
		table.clear(ignore_base)
		local char = lp.Character
		if char then ignore_base[1] = char end
		local ok, tagged = pcall(function() return collection:GetTagged("WeaponPassthrough") end)
		if ok and type(tagged) == "table" then
			for k = 1, #tagged do
				ignore_base[#ignore_base + 1] = tagged[k]
			end
		end
	end

	local function trace(origin, direction)
		refresh_ignore()
		table.clear(ignore_work)
		for k = 1, #ignore_base do ignore_work[k] = ignore_base[k] end
		local result = nil
		for _ = 1, 6 do
			ray_params.FilterDescendantsInstances = ignore_work
			result = workspace:Raycast(origin, direction, ray_params)
			if not result then break end
			local inst = result.Instance
			if not inst then break end
			local ok, tr = pcall(function() return inst.Transparency end)
			if not ok or tr ~= 1 then break end
			ignore_work[#ignore_work + 1] = inst
		end
		return result
	end

	local function gun_attachment()
		local char = lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil, nil end
		return hrp:FindFirstChild("GunRaycastAttachment"), hrp
	end

	local function origin_cframe()
		local att, hrp = gun_attachment()
		if att then return att.WorldCFrame end
		if hrp then return hrp.CFrame end
		return nil
	end

	local function grav()
		local ok, g = pcall(function() return workspace.Gravity end)
		if ok and type(g) == "number" and g > 0 then return g end
		return 0
	end

	local P = {
		snap = 48,
		ring = 48,
		hit_r = 2.1,
		pad = 2.6,
		min_span = 5,
		max_span = 90,
		acc_t = 0.15,
		acc_max = 280,
		acc_min = 40,
		speed_floor = 26,
		speed_head = 1.3,
	}

	local snap_t = table.create(P.snap, 0)
	local snap_p = table.create(P.snap, Vector3.zero)
	local snap_n = 0
	local snap_i = 0

	local TR = {
		part = nil,
		pos = nil,
		time = 0,
		vel = Vector3.zero,
		gap = 0,
		ready = false,
		fresh = Vector3.zero,
		air = false,
		air_since = 0,
		jumping = false,
		jump_v = 0,
		fresh_ok = false,
		turn = 0,
		spoof = 0,
		clr = 0,
		air_edge = 0,
		jump_fresh = false,
	}

	local SK = {
		vt = table.create(P.ring, 0),
		dx = table.create(P.ring, 0),
		dz = table.create(P.ring, 0),
		vn = 0,
		vi = 0,
	}

	local EC = {
		ping = 0,
		rtt = 0,
		jitter = 0,
		seen = false,
		step = 0,
		step_seen = false,
	}

	local function step_push(dt)
		if dt <= 0 or dt > 0.5 then return end
		if EC.step_seen then
			EC.step = EC.step * 0.85 + dt * 0.15
		else
			EC.step = dt
			EC.step_seen = true
		end
	end

	local function sample_span()
		local span = math.max(EC.step, TR.gap)
		if span <= 0 then return 0 end
		return span
	end

	local HY = {
		pos = {},
		w = {},
		n = 0,
		weight = 0,
		primary = nil,
		stamp = 0,
		conf = 0,
	}

	local ground_params = RaycastParams.new()
	ground_params.FilterType = Enum.RaycastFilterType.Exclude
	ground_params.IgnoreWater = true

	local ground_filter = {}
	local axis_pool = {}

	local function ground_below(pos, reach)
		table.clear(ground_filter)
		local n = 0
		local char = target_char
		if char then
			n = n + 1
			ground_filter[n] = char
		end
		local mine = lp.Character
		if mine then
			n = n + 1
			ground_filter[n] = mine
		end
		ground_params.FilterDescendantsInstances = ground_filter
		local res = workspace:Raycast(pos, Vector3.new(0, -reach, 0), ground_params)
		if res then return res.Position.Y end
		return nil
	end

	local function snap_push(now, pos)
		snap_i = snap_i % P.snap + 1
		snap_t[snap_i] = now
		snap_p[snap_i] = pos
		if snap_n < P.snap then snap_n = snap_n + 1 end
	end

	local function snap_get(k)
		local idx = (snap_i - k - 1) % P.snap + 1
		return snap_t[idx], snap_p[idx]
	end

	local function fit_velocity()
		if snap_n < 3 then return nil end
		local newest = snap_get(0)
		local used = 0
		local sum_d = 0
		local win = sample_span() * 4
		for k = 0, snap_n - 1 do
			local t = snap_get(k)
			if newest - t > win then break end
			used = used + 1
			sum_d = sum_d + t - newest
		end
		if used < 3 then return nil end
		local mean_d = sum_d / used
		local num = Vector3.zero
		local den = 0
		for k = 0, used - 1 do
			local t, p = snap_get(k)
			local d = t - newest - mean_d
			num = num + p * d
			den = den + d * d
		end
		if den < 1e-8 then return nil end
		return num / den, -mean_d
	end

	local function recent_velocity()
		if snap_n < 2 then return nil end
		local newest, head = snap_get(0)
		local fallback, fallback_age = nil, nil
		local target_span = sample_span() * 2
		local max_span = target_span * 2
		for k = 1, snap_n - 1 do
			local t, p = snap_get(k)
			local dt = newest - t
			if dt > max_span then break end
			if dt > 0 then
				fallback = (head - p) / dt
				fallback_age = dt * 0.5
				if dt >= target_span then
					return fallback, fallback_age
				end
			end
		end
		return fallback, fallback_age
	end

	local KIN = {
		ok = false,
		ax = 0,
		az = 0,
		smax = 0,
	}

	local function kin_clear()
		KIN.ok = false
		KIN.ax = 0
		KIN.az = 0
		KIN.smax = 0
	end

	local function fit_kin()
		if snap_n < 5 then return nil end
		local t0 = snap_get(0)
		local win = math.max(sample_span() * 5, 0.12)
		local scale = win
		local n, s1, s2, s3, s4 = 0, 0, 0, 0, 0
		local bx0, bx1, bx2 = 0, 0, 0
		local bz0, bz1, bz2 = 0, 0, 0
		for k = 0, snap_n - 1 do
			local t, p = snap_get(k)
			local age = t0 - t
			if age > win then break end
			local u = -age / scale
			local u2 = u * u
			n = n + 1
			s1 = s1 + u
			s2 = s2 + u2
			s3 = s3 + u2 * u
			s4 = s4 + u2 * u2
			bx0 = bx0 + p.X
			bx1 = bx1 + p.X * u
			bx2 = bx2 + p.X * u2
			bz0 = bz0 + p.Z
			bz1 = bz1 + p.Z * u
			bz2 = bz2 + p.Z * u2
		end
		if n < 5 then return nil end
		local det = n * (s2 * s4 - s3 * s3)
			- s1 * (s1 * s4 - s3 * s2)
			+ s2 * (s1 * s3 - s2 * s2)
		if math.abs(det) < 1e-9 then return nil end
		local function solve(b0, b1, b2)
			local d1 = n * (b1 * s4 - s3 * b2)
				- b0 * (s1 * s4 - s3 * s2)
				+ s2 * (s1 * b2 - b1 * s2)
			local d2 = n * (s2 * b2 - b1 * s3)
				- s1 * (s1 * b2 - b1 * s2)
				+ b0 * (s1 * s3 - s2 * s2)
			return d1 / det, d2 / det
		end
		local cx1, cx2 = solve(bx0, bx1, bx2)
		local cz1, cz2 = solve(bz0, bz1, bz2)
		local vx, vz = cx1 / scale, cz1 / scale
		local ax, az = 2 * cx2 / (scale * scale), 2 * cz2 / (scale * scale)
		if vx ~= vx or vz ~= vz or ax ~= ax or az ~= az then return nil end
		return Vector3.new(vx, 0, vz), Vector3.new(ax, 0, az)
	end

	local function kin_update()
		local kv, ka = fit_kin()
		if not kv then
			KIN.ok = false
			KIN.ax = 0
			KIN.az = 0
			return nil
		end
		KIN.ok = true
		local sp = math.sqrt(kv.X * kv.X + kv.Z * kv.Z)
		if sp > KIN.smax then
			KIN.smax = sp
		else
			KIN.smax = KIN.smax * 0.985 + sp * 0.015
		end
		if ka and not TR.air then
			local am = math.sqrt(ka.X * ka.X + ka.Z * ka.Z)
			local ax, az = ka.X, ka.Z
			if am > P.acc_max and am > 0 then
				ax = ax * P.acc_max / am
				az = az * P.acc_max / am
			end
			KIN.ax = KIN.ax * 0.5 + ax * 0.5
			KIN.az = KIN.az * 0.5 + az * 0.5
		else
			KIN.ax = KIN.ax * 0.5
			KIN.az = KIN.az * 0.5
		end
		return kv
	end

	local function snap_vel(k)
		local t0, p0 = snap_get(k)
		local t1, p1 = snap_get(k + 1)
		local d = t0 - t1
		if d <= 0 then return nil end
		return (p0 - p1) / d, d
	end

	local function vert_accel()
		if snap_n < 3 then return nil end
		local v0, d0 = snap_vel(0)
		local v1, d1 = snap_vel(1)
		if not v0 or not v1 then return nil end
		local span = (d0 + d1) * 0.5
		if span <= 1e-4 then return nil end
		return (v0.Y - v1.Y) / span
	end

	local function air_vy()
		if snap_n < 2 then return nil end
		local edge = TR.air_edge
		if edge <= 0 then return nil end
		local g = grav()
		local newest, head = snap_get(0)
		local want = sample_span() * 2
		local best = nil
		for k = 1, snap_n - 1 do
			local t, p = snap_get(k)
			if t < edge then break end
			local dt = newest - t
			if dt > 1e-4 then
				best = (head.Y - p.Y) / dt - 0.5 * g * dt
				if dt >= want then break end
			end
		end
		return best
	end

	local function body_clearance()
		local part = target_part
		local hum = target_hum
		if not part or not hum then return 0 end
		local ok, value = pcall(function() return part.Size.Y * 0.5 + hum.HipHeight end)
		if ok and type(value) == "number" and value > 0 then return value end
		return 0
	end

	local GC = {
		base = 0,
		seen = false,
	}

	local JL = {
		v = 0,
		seen = false,
	}

	local function stand_clearance()
		if GC.seen then return GC.base end
		return body_clearance()
	end

	local function engine_vel(part)
		local ok, v = pcall(function() return part.AssemblyLinearVelocity end)
		if not ok or typeof(v) ~= "Vector3" then
			ok, v = pcall(function() return part.Velocity end)
		end
		if not ok or typeof(v) ~= "Vector3" then return nil end
		if v.Magnitude ~= v.Magnitude then return nil end
		return v
	end

	local function vel_trust(pv, ev)
		if not pv or not ev then return 0 end
		local ph = Vector3.new(pv.X, 0, pv.Z)
		local eh = Vector3.new(ev.X, 0, ev.Z)
		local pm, em = ph.Magnitude, eh.Magnitude
		if pm < 1 and em < 1 then return 1 end
		if pm < 1 or em < 1 then return 0 end
		local ratio = em / pm
		if ratio > 1.5 or ratio < 0.6 then return 0 end
		local align = ph.Unit:Dot(eh.Unit)
		if align < 0.7 then return 0 end
		local a = math.clamp((align - 0.7) / 0.25, 0, 1)
		local r = 1 - math.clamp(math.abs(ratio - 1) / 0.4, 0, 1)
		return a * r
	end

	local function phase_velocity(v, age, air)
		if not v then return nil end
		local y = 0
		if air then
			y = v.Y - grav() * math.clamp(age or 0, 0, sample_span() * 4)
		end
		return Vector3.new(v.X, y, v.Z)
	end

	local function merge_vel(fit, fit_age, fast, fast_age, engine, engine_age, air)
		local stable = phase_velocity(fit, fit_age, air)
		local instant = phase_velocity(fast, fast_age, air)
		local turn = 0
		if stable and instant then
			local sh = Vector3.new(stable.X, 0, stable.Z)
			local ih = Vector3.new(instant.X, 0, instant.Z)
			if sh.Magnitude > 1 and ih.Magnitude > 1 then
				turn = math.acos(math.clamp(sh.Unit:Dot(ih.Unit), -1, 1)) / math.pi
			end
		end
		local base = instant or stable
		if not base then return Vector3.zero, 0, nil, 0 end
		if stable and instant then
			local agility = math.clamp(turn * 2.2, 0, 1)
			base = stable:Lerp(instant, 0.4 + 0.6 * agility)
		end
		local trust = 0
		if engine then
			local live = phase_velocity(engine, engine_age, air)
			trust = vel_trust(base, live)
			if trust > 0 and air then
				base = Vector3.new(base.X, base.Y, base.Z):Lerp(Vector3.new(base.X, live.Y, base.Z), trust * 0.35)
			end
		end
		return base, turn, instant or stable, trust
	end

	local function vel_push(now, hx, hz)
		SK.vi = SK.vi % P.ring + 1
		SK.vt[SK.vi] = now
		SK.dx[SK.vi] = hx
		SK.dz[SK.vi] = hz
		if SK.vn < P.ring then SK.vn = SK.vn + 1 end
	end

	local function track_clear()
		TR.part = nil
		TR.pos = nil
		TR.vel = Vector3.zero
		TR.gap = 0
		TR.ready = false
		TR.fresh = Vector3.zero
		TR.air = false
		TR.jumping = false
		TR.jump_v = 0
		TR.fresh_ok = false
		TR.turn = 0
		TR.spoof = 0
		TR.clr = 0
		TR.air_edge = 0
		TR.jump_fresh = false
		GC.base = 0
		GC.seen = false
		JL.v = 0
		JL.seen = false
		snap_n, snap_i = 0, 0
		SK.vn, SK.vi = 0, 0
		kin_clear()
	end

	local function track_seed(part, pos, now)
		TR.part = part
		TR.pos = pos
		TR.time = now
		TR.vel = Vector3.zero
		TR.fresh = Vector3.zero
		TR.fresh_ok = false
		TR.turn = 0
		TR.jump_v = 0
		TR.gap = 0
		TR.ready = false
		TR.spoof = 0
		TR.air_edge = 0
		TR.jump_fresh = false
		GC.base = 0
		GC.seen = false
		snap_n, snap_i = 0, 0
		kin_clear()
		snap_push(now, pos)
	end

	local function track_fresh(now)
		local part = target_part
		if not part or not part.Parent then
			TR.fresh_ok = false
			return
		end
		local pos = part.Position
		local g = grav()
		local sv = snap_vel(0)
		local vy = sv and sv.Y or 0
		local accel = vert_accel()
		local falling = accel ~= nil and accel < -g * 0.5
		local guess = stand_clearance()
		local reach = guess + 6 + math.abs(vy) * sample_span() * 4
		local air
		local gy = ground_below(pos, reach)
		if gy then
			local clr = pos.Y - gy
			TR.clr = clr
			if math.abs(vy) < 1 and not falling then
				if GC.seen then
					if clr < GC.base then
						GC.base = GC.base * 0.7 + clr * 0.3
					else
						GC.base = GC.base * 0.98 + clr * 0.02
					end
				else
					GC.base = clr
					GC.seen = true
				end
			end
			local floor = GC.seen and GC.base or guess
			local tol = math.max(floor * 0.35, 1)
			air = clr > floor + tol
			if not air and falling and math.abs(vy) > 4 and clr > floor + 0.35 then
				air = true
			end
		else
			air = true
		end
		if air ~= TR.air then
			TR.air_edge = now
			if air then
				TR.air_since = now
				TR.jump_fresh = true
				TR.jump_v = JL.seen and JL.v or math.max(vy, 0)
			else
				TR.jump_fresh = false
				TR.jump_v = 0
			end
		end
		local model_vy = TR.jump_v - g * math.max(0, now - TR.air_since)
		TR.air = air
		TR.jumping = air and (vy > 1 or model_vy > 1)
	end

	local function track(now)
		local part = target_part
		if not part or not part.Parent then
			if TR.part then track_clear() end
			return
		end
		track_fresh(now)
		local pos = part.Position
		if part ~= TR.part or not TR.pos then
			track_seed(part, pos, now)
			return
		end
		local dt = now - TR.time
		if dt > 0.75 or (pos - TR.pos).Magnitude > 140 then
			track_seed(part, pos, now)
			return
		end
		if dt <= 0 then return end
		if (pos - TR.pos).Magnitude == 0 then
			if TR.gap > 0 and dt >= TR.gap then
				TR.vel = Vector3.zero
				TR.fresh = Vector3.zero
			end
			return
		end
		step_push(dt)
		TR.gap = dt
		snap_push(now, pos)
		TR.pos = pos
		TR.time = now
		local fit, fit_age = fit_velocity()
		local fast, fast_age = recent_velocity()
		local engine = engine_vel(part)
		local fresh, turn, instant, trust = merge_vel(fit, fit_age, fast, fast_age, engine, sample_span() * 0.5, TR.air)
		local kv = kin_update()
		if kv then
			fresh = Vector3.new(kv.X, fresh.Y, kv.Z)
		end
		if engine and trust <= 0 then
			if TR.spoof < 20 then TR.spoof = TR.spoof + 1 end
		elseif TR.spoof > 0 then
			TR.spoof = TR.spoof - 1
		end
		if TR.air then
			local vy = air_vy()
			if vy then
				fresh = Vector3.new(fresh.X, vy, fresh.Z)
				local since = math.max(0, now - TR.air_edge)
				if TR.jump_fresh and since <= 0.2 then
					local impulse = vy + grav() * since
					if impulse > 1 then
						if JL.seen then
							JL.v = JL.v * 0.7 + impulse * 0.3
						else
							JL.v = impulse
							JL.seen = true
						end
						if impulse > TR.jump_v then TR.jump_v = impulse end
					end
				else
					TR.jump_fresh = false
				end
			end
		end
		TR.vel = fresh
		TR.ready = fit ~= nil or fast ~= nil
		TR.fresh = TR.vel
		TR.fresh_ok = TR.ready
		TR.turn = turn
		local raw = instant or fresh
		vel_push(now, raw.X, raw.Z)
	end

	local function raw_rtt()
		local a, b
		local ok, ms = pcall(function()
			return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and type(ms) == "number" and ms == ms and ms > 4 and ms < 800 then
			a = ms / 1000
		end
		local fine, value = pcall(function() return lp:GetNetworkPing() end)
		if fine and type(value) == "number" and value == value and value > 0 then
			local rtt = value * 2
			if rtt > 0.004 and rtt < 0.8 then b = rtt end
		end
		if a and b then return (a + b) * 0.5 end
		return a or b
	end

	local function sample_ping()
		local rtt = raw_rtt()
		if not rtt or rtt ~= rtt then return end
		rtt = math.clamp(rtt, 0, 1)
		if EC.seen then
			EC.jitter = EC.jitter * 0.9 + math.abs(rtt - EC.rtt) * 0.1
			EC.rtt = EC.rtt * 0.82 + rtt * 0.18
		else
			EC.rtt = rtt
			EC.jitter = 0
			EC.seen = true
		end
		EC.ping = EC.rtt
	end

	local function lead_time()
		if not EC.seen then return 0 end
		local stale = 0
		if TR.time > 0 and EC.step_seen then
			stale = math.clamp(os.clock() - TR.time, 0, EC.step)
		end
		return math.clamp(EC.rtt + EC.jitter * 0.5 + stale, 0, 1)
	end

	local function rotate_y(v, ang)
		local c, s = math.cos(ang), math.sin(ang)
		return Vector3.new(v.X * c - v.Z * s, v.Y, v.X * s + v.Z * c)
	end

	local function dir_stats(win)
		if SK.vn < 4 then return 1, 0 end
		win = math.max(win, sample_span() * 3)
		local newest = SK.vt[SK.vi]
		local sx, sz, n = 0, 0, 0
		local prev = nil
		local turn, turn_n = 0, 0
		local oldest = newest
		for k = 0, SK.vn - 1 do
			local idx = (SK.vi - k - 1) % P.ring + 1
			local t = SK.vt[idx]
			if newest - t > win then break end
			local hx, hz = SK.dx[idx], SK.dz[idx]
			local m = math.sqrt(hx * hx + hz * hz)
			if m > 0 then
				sx = sx + hx / m
				sz = sz + hz / m
				n = n + 1
				local ang = math.atan2(hz, hx)
				if prev then
					local d = ang - prev
					while d > math.pi do d = d - 6.2831853 end
					while d < -math.pi do d = d + 6.2831853 end
					turn = turn + d
					turn_n = turn_n + 1
				end
				prev = ang
				oldest = t
			end
		end
		if n < 2 then return 1, 0 end
		local coh = math.clamp(math.sqrt(sx * sx + sz * sz) / n, 0, 1)
		local omega = 0
		local elapsed = newest - oldest
		if turn_n >= 1 and elapsed > 1e-3 then
			omega = -turn / elapsed
		end
		return coh, omega
	end

	local function predict_from(base, sa, sb, fh, now)
		local span = math.max(0, sa + sb)
		local g = grav()
		local dir = fh
		if dir.Magnitude == 0 then
			dir = Vector3.new(TR.vel.X, 0, TR.vel.Z)
		end
		local x, z
		if span > 0 and KIN.ok then
			local age = math.clamp(now - TR.time, 0, sample_span() * 2)
			local ax, az = KIN.ax, KIN.az
			if TR.air or math.sqrt(ax * ax + az * az) < P.acc_min then ax, az = 0, 0 end
			local vx = dir.X + ax * age
			local vz = dir.Z + az * age
			local ta = math.min(span, P.acc_t)
			local dx = vx * span + 0.5 * ax * ta * ta
			local dz = vz * span + 0.5 * az * ta * ta
			local reach = math.sqrt(dx * dx + dz * dz)
			local cap = math.max(KIN.smax * P.speed_head, P.speed_floor) * span
			if reach > cap and reach > 1e-6 then
				dx = dx * cap / reach
				dz = dz * cap / reach
			end
			x = base.X + dx
			z = base.Z + dz
		else
			local hspan = span
			if span > 0 and dir.Magnitude > 0 and not TR.air then
				local coh, omega = dir_stats(span)
				local conf = math.clamp(coh, 0, 1) * (1 - math.clamp(TR.turn, 0, 1) * 0.5)
				if omega ~= 0 then
					dir = rotate_y(dir, math.clamp(omega * span * 0.5 * conf, -0.6, 0.6))
				end
				hspan = span * (0.85 + 0.15 * conf)
			end
			x = base.X + dir.X * hspan
			z = base.Z + dir.Z * hspan
		end
		local y = base.Y
		if TR.air and span > 0 then
			local vy = TR.vel.Y
			local phase = math.max(0, now - TR.air_since)
			local modeled = TR.jump_v - g * phase
			if TR.jumping and TR.jump_v > 0 and g > 0 and phase <= TR.jump_v / g and modeled > vy then
				vy = modeled
			end
			y = base.Y + vy * span - 0.5 * g * span * span
			if y < base.Y then
				local clearance = stand_clearance()
				local reach = base.Y - y + clearance
				local gy = ground_below(Vector3.new(x, base.Y, z), reach)
				if gy then
					local floor = gy + clearance
					if y < floor then y = floor end
				end
			end
		end
		return Vector3.new(x, y, z)
	end

	local function build_hyps(base, now)
		table.clear(HY.pos)
		table.clear(HY.w)
		local horizon = S.predict and TR.ready and lead_time() or 0
		local fh = Vector3.new(TR.fresh.X, 0, TR.fresh.Z)
		HY.primary = predict_from(base, 0, horizon, fh, now)
		HY.n = 1
		HY.pos[1] = HY.primary
		HY.w[1] = 1
		HY.weight = 1
		HY.stamp = now
	end

	local function score_axis(anchor, axis)
		local covered = 0
		local lo, hi = 0, 0
		for k = 1, HY.n do
			local d = HY.pos[k] - anchor
			local a = d:Dot(axis)
			local perp = (d - axis * a).Magnitude
			if perp <= P.hit_r then
				covered = covered + HY.w[k]
				if a < lo then lo = a end
				if a > hi then hi = a end
			end
		end
		return covered, lo, hi
	end

	local function corridor_axes(anchor)
		table.clear(axis_pool)
		local n = 0
		local function add(v)
			if typeof(v) ~= "Vector3" or v.Magnitude < 1e-4 then return end
			local u = v.Unit
			for k = 1, n do
				if axis_pool[k]:Dot(u) > 0.985 then return end
			end
			n = n + 1
			axis_pool[n] = u
		end
		local fh = Vector3.new(TR.fresh.X, 0, TR.fresh.Z)
		if TR.air then add(TR.fresh) end
		add(fh)
		for k = 1, HY.n do
			add(HY.pos[k] - anchor)
		end
		add(TR.fresh)
		add(Vector3.new(0, 1, 0))
		return n
	end

	local function build_corridor(now)
		local part = target_part
		if not part or not part.Parent then return nil end
		local base = part.Position
		build_hyps(base, now)
		local anchor = HY.primary or base
		local count = corridor_axes(anchor)
		local best_axis, best_cov, best_lo, best_hi = nil, -1, 0, 0
		for k = 1, count do
			local axis = axis_pool[k]
			local cov, lo, hi = score_axis(anchor, axis)
			if cov > best_cov then
				best_axis, best_cov, best_lo, best_hi = axis, cov, lo, hi
			end
		end
		if not best_axis then return nil end
		HY.conf = HY.weight > 0 and best_cov / HY.weight or 0

		local pad = P.pad
		local origin = anchor + best_axis * (best_lo - pad)
		local aim = anchor + best_axis * (best_hi + pad)
		if (aim - origin).Magnitude < 4 then
			origin = anchor - best_axis * 4
			aim = anchor + best_axis * 4
		end
		return origin, aim, HY.conf, anchor
	end

	local pred_off = Vector3.zero
	local pred_stamp = 0

	local function lead_offset()
		local part = target_part
		if not part or not part.Parent then return Vector3.zero end
		if not S.predict or not TR.ready then return Vector3.zero end
		local base = part.Position
		local now = os.clock()
		local fh = Vector3.new(TR.fresh.X, 0, TR.fresh.Z)
		local point = predict_from(base, 0, lead_time(), fh, now)
		local off = point - base
		pred_stamp = now
		pred_off = off
		return pred_off
	end

	local function cloud_confidence()
		local anchor = HY.primary
		if not anchor or HY.n == 0 or HY.weight <= 0 then return 0 end
		local covered = 0
		for k = 1, HY.n do
			if (HY.pos[k] - anchor).Magnitude <= P.hit_r then
				covered = covered + HY.w[k]
			end
		end
		return covered / HY.weight
	end
	local hit_names = {
		"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head",
		"RightUpperArm", "LeftUpperArm", "Right Arm", "Left Arm",
		"RightUpperLeg", "LeftUpperLeg", "Right Leg", "Left Leg",
		"RightLowerLeg", "LeftLowerLeg",
	}

	local hit_parts = {}
	local hit_count = 0
	local hit_char = nil

	local function refresh_parts()
		local char = target_char
		if char == hit_char then return end
		table.clear(hit_parts)
		hit_count = 0
		hit_char = char
		if not char then return end
		for k = 1, #hit_names do
			local part = char:FindFirstChild(hit_names[k])
			if part and part:IsA("BasePart") then
				hit_count = hit_count + 1
				hit_parts[hit_count] = part
			end
		end
	end

	local function los_clear(origin, point)
		if not origin or not point then return false end
		local delta = point - origin
		local dist = delta.Magnitude
		if dist < 0.5 then return true end
		if dist > MAX_RANGE then return false end
		local hit = trace(origin, delta)
		if not hit then return true end
		local inst = hit.Instance
		local char = target_char
		if inst and char and (inst == char or inst:IsDescendantOf(char)) then return true end
		return (hit.Position - origin).Magnitude >= dist - 0.75
	end

	local function pick_point(origin, strict)
		refresh_parts()
		if hit_count == 0 then return nil end
		local off = lead_offset()
		local first = nil
		for k = 1, hit_count do
			local part = hit_parts[k]
			if not part.Parent then
				hit_char = nil
			else
				local point = part.Position + off
				if not origin then return point end
				if not first then first = point end
				if los_clear(origin, point) then return point end
			end
		end
		if strict then return nil end
		return first
	end

	local force_att = nil
	local force_saved = nil
	local force_stamp = 0

	local function restore_origin()
		local att = force_att
		if not att then return end
		local saved = force_saved
		force_att = nil
		force_saved = nil
		if saved then
			pcall(function()
				if att.Parent then att.CFrame = saved end
			end)
		end
	end

	local function push_origin(cf)
		local att = gun_attachment()
		if not att then return false end
		if force_att and force_att ~= att then restore_origin() end
		if not force_att then
			local ok, saved = pcall(function() return att.CFrame end)
			if not ok or typeof(saved) ~= "CFrame" then return false end
			force_att = att
			force_saved = saved
		end
		force_stamp = os.clock()
		local ok = pcall(function() att.WorldCFrame = cf end)
		if not ok then
			restore_origin()
			return false
		end
		task.defer(restore_origin)
		return true
	end

	local function is_target_hit(inst)
		local char = target_char
		if not inst or not char then return false end
		return inst == char or inst:IsDescendantOf(char)
	end

	local function force_clear(origin, aim)
		local hit = trace(origin, aim - origin)
		if not hit then return false end
		return is_target_hit(hit.Instance)
	end

	local function force_velocity()
		if TR.fresh_ok and TR.fresh.Magnitude > 0.5 then return TR.fresh end
		if TR.ready and TR.vel.Magnitude > 0.5 then return TR.vel end
		return Vector3.zero
	end

	local function resolve_force()
		local part = target_part
		if not part or not part.Parent then return nil end
		local live = part.Position
		local now = os.clock()

		local origin, aim, conf, anchor = build_corridor(now)
		if origin and aim then
			local axis = aim - origin
			local span = axis.Magnitude
			if span > 1e-3 then
				local u = axis / span
				local mark = anchor or live
				local behind = (mark - origin):Dot(u)
				if behind < P.pad then
					origin = origin - u * (P.pad - behind)
				end
				local ahead = (aim - mark):Dot(u)
				if ahead < P.min_span then
					aim = mark + u * P.min_span
				end
				local want = S.stand_off
				while want > 0 do
					local probe = origin - u * want
					if (aim - probe).Magnitude <= P.max_span
						and los_clear(probe, mark)
						and los_clear(probe, live) then
						origin = probe
						break
					end
					want = want - 3
				end
				if (aim - origin).Magnitude > P.max_span then
					origin = aim - u * P.max_span
				end
				return CFrame.new(origin, aim), CFrame.new(aim), conf or 0, mark
			end
		end

		local vel = force_velocity()
		local dir = Vector3.new(0, -1, 0)
		if vel.Magnitude > 3 then
			dir = vel.Unit
		else
			local mine = origin_cframe()
			if mine then
				local delta = live - mine.Position
				if delta.Magnitude > 2 then dir = delta.Unit end
			end
		end
		local back = live - dir * 6
		local front = live + dir * math.max(P.min_span, vel.Magnitude * lead_time() + 8)
		if not force_clear(back, front) then
			back = live - dir * 2.5
		end
		return CFrame.new(back, front), CFrame.new(front), 0, live
	end

	local function shot_shift(dt)
		if not S.predict or not TR.ready or dt <= 0 then return Vector3.zero end
		local shift = Vector3.new(TR.vel.X * dt, 0, TR.vel.Z * dt)
		if TR.air then
			local g = grav()
			local horizon = lead_time()
			local vy = TR.vel.Y
			local phase = math.max(0, os.clock() - TR.air_since)
			local modeled = TR.jump_v - g * phase
			if TR.jumping and TR.jump_v > 0 and g > 0 and phase <= TR.jump_v / g and modeled > vy then vy = modeled end
			shift = Vector3.new(shift.X, vy * dt - g * horizon * dt - 0.5 * g * dt * dt, shift.Z)
		end
		return shift
	end

	local function compensate_force(origin_cf, aim_cf, started)
		local shift = shot_shift(math.max(0, os.clock() - started))
		if shift == Vector3.zero then return origin_cf, aim_cf end
		local origin = origin_cf.Position + shift
		local aim = aim_cf.Position + shift
		return CFrame.new(origin, aim), CFrame.new(aim)
	end

	local function resolve_shot()
		if not S.enabled or not S.am_sheriff or not target_alive() then return nil end
		if S.force then
			local started = os.clock()
			local origin_cf, aim_cf = resolve_force()
			if origin_cf and aim_cf then
				origin_cf, aim_cf = compensate_force(origin_cf, aim_cf, started)
				if push_origin(origin_cf) then return aim_cf end
			end
		end
		local cf = origin_cframe()
		local aim = pick_point(cf and cf.Position or nil, false)
		if not aim then return nil end
		return CFrame.new(aim)
	end

	local function compensate_resolve(cf)
		if S.force or typeof(cf) ~= "CFrame" then return cf end
		return CFrame.new(cf.Position + shot_shift(math.max(0, os.clock() - pred_stamp)))
	end

	local weapon_service = nil
	local orig_mouse = nil
	local orig_screen = nil
	local hook_mouse = nil
	local hook_screen = nil

	local function get_weapon_service()
		if weapon_service then return weapon_service end
		local ok, m = pcall(function()
			return require(rs:WaitForChild("ClientServices"):WaitForChild("WeaponService"))
		end)
		if ok and type(m) == "table" then weapon_service = m end
		return weapon_service
	end

	local function install_hooks()
		local m = get_weapon_service()
		if not m then return end
		if not hook_mouse then
			local function knife_aim()
				local fn = getgenv().KNIFE_AIM_RESOLVE
				if type(fn) ~= "function" then return nil end
				local ok, cf = pcall(fn)
				if ok and typeof(cf) == "CFrame" then return cf end
				return nil
			end
			hook_mouse = function(self, ...)
				sample_ping()
				local ok, cf = pcall(resolve_shot)
				if ok and cf then return compensate_resolve(cf) end
				local kcf = knife_aim()
				if kcf then return kcf end
				return orig_mouse(self, ...)
			end
			hook_screen = function(self, x, y, ...)
				sample_ping()
				local ok, cf = pcall(resolve_shot)
				if ok and cf then return compensate_resolve(cf) end
				local kcf = knife_aim()
				if kcf then return kcf end
				return orig_screen(self, x, y, ...)
			end
		end
		pcall(function() setreadonly(m, false) end)
		if type(m.GetMouseTargetCFrame) == "function" and m.GetMouseTargetCFrame ~= hook_mouse then
			orig_mouse = m.GetMouseTargetCFrame
			pcall(function() m.GetMouseTargetCFrame = hook_mouse end)
		end
		if type(m.GetTargetPosition) == "function" and m.GetTargetPosition ~= hook_screen then
			orig_screen = m.GetTargetPosition
			pcall(function() m.GetTargetPosition = hook_screen end)
		end
	end

	local gun_fired_conn = nil
	local last_fire_stamp = 0

	local function on_gun_fired(tool)
		if typeof(tool) ~= "Instance" then return end
		local char = lp.Character
		if not char then return end
		local ok, mine = pcall(function() return tool:IsDescendantOf(char) end)
		if not ok or not mine then return end
		local now = os.clock()
		if last_fire_stamp > 0 and want_since > 0 and want_since <= last_fire_stamp then
			gap_push(now - last_fire_stamp)
		end
		last_fire_stamp = now
	end

	local function connect_gun_fired()
		if gun_fired_conn then return end
		local m = get_weapon_service()
		if not m then return end
		local ev = m.GunFired
		if typeof(ev) ~= "Instance" then return end
		gun_fired_conn = ev.OnClientEvent:Connect(function(tool)
			pcall(on_gun_fired, tool)
		end)
	end

	local function get_gun()
		local char = lp.Character
		if char then
			local g = char:FindFirstChild("Gun")
			if g then return g, true end
		end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then
			local g = bp:FindFirstChild("Gun")
			if g then return g, false end
		end
		return nil, false
	end

	local function fire_gun(gun, start_cf, aim_cf)
		if not gun or not start_cf or not aim_cf then return false end
		local remote = gun:FindFirstChild("Shoot")
		if not remote or not remote:IsA("RemoteEvent") then return false end
		return (pcall(function() remote:FireServer(start_cf, aim_cf) end))
	end

	local function auto_step(now)
		if not S.auto_on or not S.enabled or not S.am_sheriff or getgenv().AUTOFARM_HOLD or not target_alive() then
			want_since = 0
			return
		end
		local gun, equipped = get_gun()
		if not gun then
			want_since = 0
			return
		end
		if gun ~= gap_gun then
			gap_gun = gun
			gap_reset()
		end
		if not equipped then
			want_since = 0
			local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(gun) end) end
			return
		end
		if want_since == 0 then want_since = now end
		local hold = S.auto_delay
		if hold < S.fire_gap then hold = S.fire_gap end
		local since = last_fire_stamp > 0 and last_fire_stamp or S.last_shot
		if now - since < hold then return end
		if S.force then
			local started = os.clock()
			local origin_cf, aim_cf = resolve_force()
			if not origin_cf or not aim_cf then return end
			origin_cf, aim_cf = compensate_force(origin_cf, aim_cf, started)
			if fire_gun(gun, origin_cf, aim_cf) then
				S.last_shot = now
			end
			return
		end
		local cf = origin_cframe()
		if not cf then return end
		local aim = pick_point(cf.Position, true)
		if not aim then return end
		local aim_cf = compensate_resolve(CFrame.new(aim))
		if fire_gun(gun, cf, aim_cf) then
			S.last_shot = now
		end
	end

	local watch_conns = {}

	local function clear_watch()
		for k = 1, #watch_conns do
			local conn = watch_conns[k]
			pcall(function() conn:Disconnect() end)
		end
		table.clear(watch_conns)
	end

	local function setup_watch()
		clear_watch()
		local m = get_round()
		if m and m.PlayerDataChanged then
			watch_conns[#watch_conns + 1] = m.PlayerDataChanged.Event:Connect(function()
				pcall(refresh_target)
			end)
		end
		watch_conns[#watch_conns + 1] = lp.CharacterAdded:Connect(function()
			task.wait(0.3)
			pcall(refresh_target)
		end)
	end

	local next_role = 0
	local next_hook = 0

	local function tick()
		if force_att and os.clock() - force_stamp > 0.05 then restore_origin() end
		if not S.enabled then return end
		local now = os.clock()
		if now >= next_role then
			next_role = now + 0.2
			refresh_target()
		end
		sample_ping()
		track(now)
		if now >= next_hook then
			next_hook = now + 1
			install_hooks()
			connect_gun_fired()
		end
		auto_step(now)
	end

	local main_conn = run.Heartbeat:Connect(function()
		pcall(tick)
	end)

	getgenv().SILENT_INSTALL_HOOKS = function()
		pcall(install_hooks)
	end

	getgenv().SILENT_DBG = function()
		local coh, omega = dir_stats(lead_time())
		return {
			target = target_player and target_player.Name or "none",
			ping = EC.ping,
			rtt = EC.rtt,
			jitter = EC.jitter,
			step = EC.step,
			lead = lead_time(),
			coherence = coh,
			omega = omega,
			turn = TR.turn,
			spoof = TR.spoof,
			clearance = TR.clr,
			ground = GC.seen and GC.base or 0,
			jump_learned = JL.seen and JL.v or 0,
			jump_v = TR.jump_v,
			fire_gap = S.fire_gap,
			want_since = want_since,
			conf_point = cloud_confidence(),
			conf_ray = HY.conf,
			gap = TR.gap,
			airborne = TR.air,
			vel_fresh = TR.fresh,
			vel_pos = TR.vel,
		}
	end

	task.spawn(function()
		pcall(install_hooks)
		pcall(connect_gun_fired)
	end)

	getgenv().SILENT_UNLOAD = function()
		S.enabled = false
		S.predict = false
		S.force = false
		S.auto_on = false
		getgenv().SILENT_AIM_ACTIVE = false
		restore_origin()
		clear_watch()
		track_clear()
		if gun_fired_conn then
			pcall(function() gun_fired_conn:Disconnect() end)
			gun_fired_conn = nil
		end
		if main_conn then
			pcall(function() main_conn:Disconnect() end)
			main_conn = nil
		end
		local m = weapon_service
		if m then
			pcall(function() setreadonly(m, false) end)
			if orig_mouse then
				pcall(function() m.GetMouseTargetCFrame = orig_mouse end)
			end
			if orig_screen then
				pcall(function() m.GetTargetPosition = orig_screen end)
			end
		end
	end
	getgenv().SH = {
		setSilent = function(v)
			S.enabled = v
			getgenv().SILENT_AIM_ACTIVE = v
			if v then
				task.spawn(function()
					pcall(install_hooks)
					pcall(connect_gun_fired)
					pcall(setup_watch)
					pcall(refresh_target)
				end)
			else
				clear_watch()
				track_clear()
			end
		end,
		setPredict = function(v)
			S.predict = v
			if not v then track_clear() end
		end,
		setForce = function(v)
			S.force = v
			if not v then restore_origin() end
		end,
		setOrigin = function(v) S.stand_off = v end,
		setAuto = function(v) S.auto_on = v end,
		setDelay = function(v) S.auto_delay = v / 1000 end,
		unload = getgenv().SILENT_UNLOAD,
	}
end
do
print("[world] init initSheriff...")
local ok, err = pcall(initSheriff)
print("[world] init initSheriff " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ KILLAURA ENGINE ------------------------------
function initAura()
	local rs = game:GetService("ReplicatedStorage")
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local lp = players.LocalPlayer

	local aura_on = false
	local killall_on = false
	local aura_distance = 30

	local am_murderer = false

	local aura_round_mod = nil

	local function aura_require_round()
		return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
	end

	local function refresh_murderer()
		local module = aura_round_mod
		if not module then
			local ok, m = pcall(aura_require_round)
			if not ok or type(m) ~= "table" then
				am_murderer = false
				return
			end
			aura_round_mod = m
			module = m
		end
		local data = module.PlayerData
		if type(data) ~= "table" then
			am_murderer = false
			return
		end
		local me = data[lp.Name]
		am_murderer = me ~= nil and me.Role == "Murderer" and not me.Dead
	end

	local function get_knife()
		local char = lp.Character
		if char then
			local equipped = char:FindFirstChild("Knife")
			if equipped then return equipped, true end
		end
		local backpack = lp:FindFirstChildOfClass("Backpack")
		if backpack then
			local stored = backpack:FindFirstChild("Knife")
			if stored then return stored, false end
		end
		return nil, false
	end

	local function ensure_knife_equipped()
		local knife, equipped = get_knife()
		if not knife then return nil end
		if not equipped then
			local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				pcall(function() hum:EquipTool(knife) end)
			end
			return nil
		end
		return knife
	end

	local function knife_stab(knife)
		local events = knife:FindFirstChild("Events")
		local stabbed = events and events:FindFirstChild("KnifeStabbed")
		if stabbed then
			pcall(function() stabbed:FireServer() end)
		end
	end

	local function knife_touch(knife, part)
		local events = knife:FindFirstChild("Events")
		local touched = events and events:FindFirstChild("HandleTouched")
		if touched then
			pcall(function() touched:FireServer(part) end)
		end
	end

	local last_kill = 0
	local genv = getgenv()
	local victims = {}

	task.spawn(function()
		while task.wait(0.3) do
			if aura_on or killall_on then
				pcall(refresh_murderer)
			end
		end
	end)

	task.spawn(function()
		while task.wait() do
			if not ((aura_on or killall_on) and am_murderer) then
				continue
			end
			if genv.AUTOFARM_HOLD then
				continue
			end
			local knife = ensure_knife_equipped()
			if not knife then
				continue
			end
			if os.clock() - last_kill < 0.05 then
				continue
			end
			local char = lp.Character
			local my_part = char and char:FindFirstChild("HumanoidRootPart")
			table.clear(victims)
			local victim_count = 0
			for _, plr in ipairs(players:GetPlayers()) do
				if plr == lp then continue end
				local target_char = plr.Character
				if not target_char then continue end
				local hum = target_char:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then continue end
				local part = target_char:FindFirstChild("HumanoidRootPart") or target_char:FindFirstChild("Head")
				if not part then continue end
				if killall_on then
					victim_count = victim_count + 1
					victims[victim_count] = part
				elseif aura_on and my_part and (part.Position - my_part.Position).Magnitude <= aura_distance then
					victim_count = victim_count + 1
					victims[victim_count] = part
				end
			end
			if victim_count > 0 then
				knife_stab(knife)
				for i = 1, victim_count do
					knife_touch(knife, victims[i])
				end
				last_kill = os.clock()
			end
		end
	end)
	getgenv().KILLAURA_UNLOAD = function()
		aura_on = false
		killall_on = false
	end
	getgenv().KA = {
		setAura = function(v)
			aura_on = v
			if v then task.spawn(refresh_murderer) end
		end,
		setDist = function(v) aura_distance = v end,
		setKillAll = function(v)
			killall_on = v
			if v then task.spawn(refresh_murderer) end
		end,
		unload = getgenv().KILLAURA_UNLOAD,
	}
end
do
print("[world] init initAura...")
local ok, err = pcall(initAura)
print("[world] init initAura " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ FARM ENGINE ------------------------------
function initFarm()
	local players = game:GetService("Players")
	local lp = players.LocalPlayer

	local autograb_on = false

	local grab_rs = game:GetService("ReplicatedStorage")
	local grab_round_mod = nil
	local function grab_has_role()
		if not grab_round_mod then
			local ok, m = pcall(function()
				return require(grab_rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
			end)
			if ok and type(m) == "table" then grab_round_mod = m end
		end
		local d = grab_round_mod and grab_round_mod.PlayerData
		if type(d) ~= "table" then return false end
		local me = d[lp.Name]
		return me ~= nil and me.Role ~= nil and not me.Dead
	end

	local function has_knife()
		local char = lp.Character
		if char and char:FindFirstChild("Knife") then return true end
		local backpack = lp:FindFirstChildOfClass("Backpack")
		if backpack and backpack:FindFirstChild("Knife") then return true end
		return false
	end

	local function grab_gun(obj)
		if not autograb_on or has_knife() then return end
		if not grab_has_role() then return end
		local char = lp.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		pcall(function() obj.CFrame = root.CFrame end)
		local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			pcall(function() fireproximityprompt(prompt) end)
		end
	end

	local function scan_guns()
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.Name == "GunDrop" and obj:IsA("BasePart") then
				grab_gun(obj)
			end
		end
	end

	local grab_desc_conn = nil

	local function grab_desc_added(obj)
		if obj.Name == "GunDrop" and obj:IsA("BasePart") then
			task.wait(0.1)
			grab_gun(obj)
		end
	end

	local function grab_desc_stop()
		if grab_desc_conn then
			pcall(function() grab_desc_conn:Disconnect() end)
			grab_desc_conn = nil
		end
	end

	local run = game:GetService("RunService")
	local cs = game:GetService("CollectionService")
	local rs = game:GetService("ReplicatedStorage")

	local autofarm_on = false
	local autoreset_on = false
	local autokill_on = false
	local coins_done = false
	local saw_coins = false
	local farm_target = nil
	local nc_cache = {}
	local FARM_SPEED = 23
	local round_mod = nil
	local collected_ids = {}
	local collected_count = 0

	local farm_mode = "Basic"
	local avoid_murder = false
	local was_down = false
	local down_ref_y = nil
	local last_touch = 0
	local DOWN_DEPTH = 14
	local DOWN_RISE_XZ = 4
	local AVOID_DIST = 40
	local RISE_SAFE_DIST = 20

	getgenv().AUTOFARM_HOLD = false

	local function farm_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function get_round_data()
		if not round_mod then
			local ok, m = pcall(function()
				return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
			end)
			if ok and type(m) == "table" then round_mod = m end
		end
		return round_mod and round_mod.PlayerData
	end

	local function can_farm()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end
		local d = get_round_data()
		if type(d) == "table" then
			local me = d[lp.Name]
			if not me or not me.Role or me.Dead then return false end
		end
		return true
	end

	local function coin_bags_full()
		local pg = lp:FindFirstChild("PlayerGui")
		local main = pg and pg:FindFirstChild("MainGUI")
		local gg = main and main:FindFirstChild("Game")
		local bags = gg and gg:FindFirstChild("CoinBags")
		local container = bags and bags:FindFirstChild("Container")
		if not container then return false end
		local any = false
		for _, v in ipairs(container:GetChildren()) do
			if v:IsA("Frame") and v.Visible then
				any = true
				local full = v:FindFirstChild("Full")
				if not (full and full.Visible) then
					return false
				end
			end
		end
		return any
	end

	local function update_hold()
		getgenv().AUTOFARM_HOLD = autofarm_on and autokill_on and not coins_done
	end

	local function reset_farm_progress()
		collected_ids = {}
		collected_count = 0
		coins_done = false
		saw_coins = false
		farm_target = nil
		update_hold()
	end

	task.spawn(function()
		local ok, remote = pcall(function()
			return rs:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinsStarted", 15)
		end)
		if ok and remote then
			remote.OnClientEvent:Connect(reset_farm_progress)
		end
	end)

	lp.CharacterAdded:Connect(function()
		reset_farm_progress()
	end)

	local function coin_available(v)
		return v and v.Parent and v:IsA("BasePart") and not v:GetAttribute("Collected") and not v:GetAttribute("Delete")
	end

	local function available_coins()
		local list = {}
		for _, v in ipairs(cs:GetTagged("CoinVisual")) do
			if coin_available(v) then
				list[#list + 1] = v
			end
		end
		return list
	end

	local function nearest_coin(pos, list)
		local best, bd = nil, math.huge
		for _, v in ipairs(list) do
			local d = (v.Position - pos).Magnitude
			if d < bd then bd = d best = v end
		end
		return best
	end

	local function set_farm_noclip(on)
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if on then
			if not char then return end
			if hum then pcall(function() hum.PlatformStand = true end) end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					if nc_cache[p] == nil then nc_cache[p] = p.CanCollide end
					p.CanCollide = false
				end
			end
		else
			if hum then pcall(function() hum.PlatformStand = false end) end
			for p, v in pairs(nc_cache) do
				if p and p.Parent then pcall(function() p.CanCollide = v end) end
			end
			nc_cache = {}
		end
	end

	local up_params = RaycastParams.new()
	up_params.FilterType = Enum.RaycastFilterType.Exclude
	up_params.IgnoreWater = true

	local function return_to_surface()
		local hrp = farm_hrp()
		if not hrp then return end
		local origin = hrp.Position
		up_params.FilterDescendantsInstances = { lp.Character }
		local res = workspace:Raycast(origin, Vector3.new(0, 400, 0), up_params)
		local y = res and (res.Position.Y + 5) or (down_ref_y and down_ref_y + 5 or nil)
		if not y then return end
		pcall(function()
			hrp.CFrame = CFrame.new(origin.X, y, origin.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	local function farm_release()
		if was_down then
			was_down = false
			return_to_surface()
		end
		set_farm_noclip(false)
	end

	local murder_hrp_cache, murder_hrp_t = nil, 0
	local function murderer_hrp()
		local now = os.clock()
		if now - murder_hrp_t < 0.25 then return murder_hrp_cache end
		murder_hrp_t = now
		murder_hrp_cache = nil
		local d = get_round_data()
		if type(d) == "table" then
			local me = d[lp.Name]
			if me and me.Role == "Murderer" then return nil end
			for name, info in pairs(d) do
				if type(info) == "table" and info.Role == "Murderer" and not info.Dead and name ~= lp.Name then
					local pl = players:FindFirstChild(name)
					local char = pl and pl.Character
					local h = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if h and (not hum or hum.Health > 0) then murder_hrp_cache = h end
					break
				end
			end
		end
		return murder_hrp_cache
	end

	local function flat_dist(a, b)
		return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
	end

	local function pick_coin(pos, list, mpos)
		if not (avoid_murder and mpos) then
			return nearest_coin(pos, list)
		end
		local safe, sd = nil, math.huge
		local far, fd = nil, -1
		for _, v in ipairs(list) do
			local md = flat_dist(v.Position, mpos)
			if md > fd then fd = md far = v end
			if md >= AVOID_DIST then
				local d = (v.Position - pos).Magnitude
				if d < sd then sd = d safe = v end
			end
		end
		if safe then return safe end
		if far and fd >= AVOID_DIST * 0.6 then return far end
		return nil
	end

	local function coin_ok_now(v, mpos)
		if not coin_available(v) then return false end
		if avoid_murder and mpos and flat_dist(v.Position, mpos) < AVOID_DIST * 0.6 then return false end
		return true
	end

	local function avoid_steer(cur, dest, mpos)
		if not (avoid_murder and mpos) then return dest end
		local dm = flat_dist(cur, mpos)
		if dm >= AVOID_DIST then return dest end
		local away = Vector3.new(cur.X - mpos.X, 0, cur.Z - mpos.Z)
		if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
		away = away.Unit
		local want = Vector3.new(dest.X - cur.X, 0, dest.Z - cur.Z)
		local mag = want.Magnitude
		if mag < 0.1 then return dest end
		local weight = 1 + (1 - dm / AVOID_DIST) * 2
		local blend = (want.Unit + away * weight)
		if blend.Magnitude < 0.1 then blend = away else blend = blend.Unit end
		local np = cur + blend * mag
		return Vector3.new(np.X, dest.Y, np.Z)
	end

	local function touch_targets(coin)
		local list = {}
		local seen = {}
		local function add(p)
			if p and not seen[p] and p:IsA("BasePart") and p:FindFirstChildOfClass("TouchTransmitter") then
				seen[p] = true
				list[#list + 1] = p
			end
		end
		add(coin)
		for _, v in ipairs(coin:GetChildren()) do add(v) end
		local par = coin.Parent
		if par then
			if par:IsA("BasePart") then add(par) end
			for _, v in ipairs(par:GetChildren()) do add(v) end
		end
		if #list == 0 then list[1] = coin end
		return list
	end

	local function fire_touch(coin)
		if type(firetouchinterest) ~= "function" then return end
		if not coin or not coin.Parent then return end
		local now = os.clock()
		if now - last_touch < 0.05 then return end
		last_touch = now
		local hrp = farm_hrp()
		if not hrp then return end
		for _, p in ipairs(touch_targets(coin)) do
			pcall(firetouchinterest, hrp, p, 0)
			pcall(firetouchinterest, hrp, p, 1)
		end
	end

	local function farm_move(hrp, dest, dt)
		local dir = dest - hrp.Position
		local dist = dir.Magnitude
		local np = dest
		if dist > 0.1 then
			np = hrp.Position + dir.Unit * math.min(FARM_SPEED * dt, dist)
		end
		local cf = CFrame.new(np)
		if farm_mode == "Down" then
			cf = cf * CFrame.Angles(-math.pi * 0.5, 0, 0)
			was_down = true
		end
		pcall(function()
			hrp.CFrame = cf
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	local farm_conn = run.Stepped:Connect(function(_, dt)
		if not autofarm_on then return end
		if not can_farm() then
			farm_target = nil
			was_down = false
			set_farm_noclip(false)
			return
		end
		local hrp = farm_hrp()
		if not hrp then return end

		local list = {}
		for _, v in ipairs(cs:GetTagged("CoinVisual")) do
			if v and v.Parent and v:IsA("BasePart") then
				if v:GetAttribute("Collected") then
					local id = v:GetAttribute("CoinID")
					if id and not collected_ids[id] then
						collected_ids[id] = true
						collected_count = collected_count + 1
					end
				elseif not v:GetAttribute("Delete") then
					list[#list + 1] = v
				end
			end
		end

		local function finish()
			farm_target = nil
			farm_release()
			if not coins_done then
				coins_done = true
				update_hold()
				if autoreset_on then
					local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
					if hum then pcall(function() hum.Health = 0 end) end
				end
			end
		end

		if saw_coins and coin_bags_full() then
			finish()
			return
		end

		if #list > 0 then
			saw_coins = true
			if coins_done then coins_done = false update_hold() end

			local mhrp = avoid_murder and murderer_hrp() or nil
			local mpos = mhrp and mhrp.Position or nil

			if not coin_ok_now(farm_target, mpos) then
				farm_target = pick_coin(hrp.Position, list, mpos)
			end

			if farm_target then
				set_farm_noclip(true)
				local cpos = farm_target.Position
				down_ref_y = cpos.Y
				local dest = cpos

				if farm_mode == "Down" then
					local xz = flat_dist(hrp.Position, cpos)
					local safe_to_rise = (not mpos) or flat_dist(hrp.Position, mpos) > RISE_SAFE_DIST
					if xz <= DOWN_RISE_XZ and safe_to_rise then
						dest = cpos
						fire_touch(farm_target)
					else
						dest = Vector3.new(cpos.X, cpos.Y - DOWN_DEPTH, cpos.Z)
					end
				elseif (cpos - hrp.Position).Magnitude <= 6 then
					fire_touch(farm_target)
				end

				dest = avoid_steer(hrp.Position, dest, mpos)
				farm_move(hrp, dest, dt)
			elseif mpos then
				set_farm_noclip(true)
				local away = Vector3.new(hrp.Position.X - mpos.X, 0, hrp.Position.Z - mpos.Z)
				if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
				away = away.Unit
				local y = hrp.Position.Y
				if farm_mode == "Down" and down_ref_y then y = down_ref_y - DOWN_DEPTH end
				farm_move(hrp, hrp.Position + away * 40 + Vector3.new(0, y - hrp.Position.Y, 0), dt)
			end
		else
			farm_target = nil
			farm_release()
			if saw_coins and not coins_done and collected_count > 0 then
				finish()
			end
		end
	end)

	getgenv().AUTOFARM_UNLOAD = function()
		autofarm_on = false
		autoreset_on = false
		autokill_on = false
		coins_done = false
		saw_coins = false
		farm_target = nil
		getgenv().AUTOFARM_HOLD = false
		avoid_murder = false
		farm_mode = "Basic"
		if farm_conn then pcall(function() farm_conn:Disconnect() end) farm_conn = nil end
		farm_release()
	end

	getgenv().AUTOGRAB_UNLOAD = function()
		autograb_on = false
		grab_desc_stop()
	end
	getgenv().AF = {
		setGrab = function(v)
			autograb_on = v
			if v then
				if not grab_desc_conn then
					grab_desc_conn = workspace.DescendantAdded:Connect(grab_desc_added)
				end
				task.spawn(scan_guns)
			else
				grab_desc_stop()
			end
		end,
		setFarm = function(v)
			autofarm_on = v
			reset_farm_progress()
			if not v then
				farm_release()
			end
		end,
		setType = function(v)
			local nv = v
			if nv ~= "Basic" and nv ~= "Down" then nv = "Basic" end
			if nv == farm_mode then return end
			farm_mode = nv
			farm_target = nil
			if farm_mode == "Basic" and was_down then
				was_down = false
				return_to_surface()
			end
		end,
		setMurderCheck = function(v)
			avoid_murder = v
			farm_target = nil
		end,
		setAutoReset = function(v) autoreset_on = v end,
		setAutoKill = function(v)
			autokill_on = v
			update_hold()
		end,
		unload = function()
			pcall(getgenv().AUTOFARM_UNLOAD)
			pcall(getgenv().AUTOGRAB_UNLOAD)
		end,
	}
end
do
print("[world] init initFarm...")
local ok, err = pcall(initFarm)
print("[world] init initFarm " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ BUILD: GAME (sheriff/murder/autos) ------------------------------
do
	local SH, KA, AF = getgenv().SH, getgenv().KA, getgenv().AF

	do
		local sec = Section(pGame, "sheriff", "left")
		TRow(sec, "silent", false, function(v) SH.setSilent(v) end, false)
		TRow(sec, "prediction", true, function(v) SH.setPredict(v) end, false)
		local fopt = TRow(sec, "force shoot", false, function(v) SH.setForce(v) end, true)
		TSlider(fopt, "origin", 0, 40, 15, 0, function(v) SH.setOrigin(v) end)
		local aopt = TRow(sec, "auto shoot", false, function(v) SH.setAuto(v) end, true)
		TSlider(aopt, "delay", 0, 600, 0, 0, function(v) SH.setDelay(v) end)
	end

	do
		local sec = Section(pGame, "murder", "left")
		local kopt = TRow(sec, "kill aura", false, function(v) KA.setAura(v) end, true)
		TSlider(kopt, "distance", 5, 60, 30, 0, function(v) KA.setDist(v) end)
		TRow(sec, "kill all", false, function(v) KA.setKillAll(v) end, false)
	end

	do
		local sec = Section(pGame, "autos", "right")
		TRow(sec, "grab gun", false, function(v) AF.setGrab(v) end, false)
		local fopt = TRow(sec, "farm", false, function(v) AF.setFarm(v) end, true)
		TDrop(fopt, "type", { "Basic", "Down" }, "Basic", function(v) AF.setType(v) end)
		TRow(fopt, "murder check", false, function(v) AF.setMurderCheck(v) end, false)
		TRow(fopt, "auto reset", false, function(v) AF.setAutoReset(v) end, false)
		TRow(fopt, "auto kill", false, function(v) AF.setAutoKill(v) end, false)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		SH.unload()
		KA.unload()
		AF.unload()
	end)
end
------------------------------ MENU SETTINGS impl ------------------------------
-- custom cursor (drawn, no assets)
local Cur = { on = false, preset = "cross", objs = {}, conn = nil, oldIcon = nil }
local function curClear()
	for i = 1, #Cur.objs do
		local o = Cur.objs[i]
		if o then pcall(function() o:Remove() end) end
	end
	Cur.objs = {}
end
local function curLine(w, black)
	local o = nil
	if HASDRAW then
		pcall(function()
			o = Drawing.new("Line")
			o.Thickness = black and (w + 2) or w
			o.Color = black and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
			o.Transparency = 1
			o.ZIndex = 2000
			o.Visible = false
		end)
	end
	Cur.objs[#Cur.objs + 1] = o
	return o
end
local function curBuild()
	curClear()
	if Cur.preset == "dot" then
		local b = nil
		if HASDRAW then
			pcall(function()
				b = Drawing.new("Square")
				b.Filled = true
				b.Color = Color3.new(1, 1, 1)
				b.Transparency = 1
				b.ZIndex = 2000
				b.Visible = false
			end)
		end
		Cur.objs[1] = b
	else
		local n = Cur.preset == "arrow" and 3 or 2
		for i = 1, n do
			curLine(2, true)
			curLine(2, false)
		end
	end
end
local function curFrame()
	if not Cur.on then return end
	local mp = UIS:GetMouseLocation()
	local x, y = mp.X, mp.Y
	if Cur.preset == "dot" then
		local b = Cur.objs[1]
		if b then
			pcall(function()
				b.Position = Vector2.new(x - 3, y - 3)
				b.Size = Vector2.new(6, 6)
				b.Visible = true
			end)
		end
	elseif Cur.preset == "arrow" then
		local pts = {
			{ Vector2.new(x, y), Vector2.new(x - 11, y + 15) },
			{ Vector2.new(x, y), Vector2.new(x + 2, y + 15) },
			{ Vector2.new(x - 11, y + 15), Vector2.new(x + 2, y + 15) },
		}
		for i = 1, 3 do
			local o1, o2 = Cur.objs[(i - 1) * 2 + 1], Cur.objs[(i - 1) * 2 + 2]
			if o1 then pcall(function() o1.From, o1.To, o1.Visible = pts[i][1], pts[i][2], true end) end
			if o2 then pcall(function() o2.From, o2.To, o2.Visible = pts[i][1], pts[i][2], true end) end
		end
	else
		local L = 9
		local segs = {
			{ Vector2.new(x - L, y), Vector2.new(x + L, y) },
			{ Vector2.new(x, y - L), Vector2.new(x, y + L) },
		}
		for i = 1, 2 do
			local o1, o2 = Cur.objs[(i - 1) * 2 + 1], Cur.objs[(i - 1) * 2 + 2]
			if o1 then pcall(function() o1.From, o1.To, o1.Visible = segs[i][1], segs[i][2], true end) end
			if o2 then pcall(function() o2.From, o2.To, o2.Visible = segs[i][1], segs[i][2], true end) end
		end
	end
end
local function setCursor(on)
	if on and not HASDRAW then
		print("[world] custom cursor needs Drawing")
		return
	end
	Cur.on = on
	if on then
		local m = LP:GetMouse()
		if m then
			Cur.oldIcon = m.Icon
			pcall(function() m.Icon = "" end)
		end
		curBuild()
		if not Cur.conn then
			Cur.conn = RS.RenderStepped:Connect(curFrame)
		end
	else
		if Cur.conn then pcall(function() Cur.conn:Disconnect() end) Cur.conn = nil end
		curClear()
		local m = LP:GetMouse()
		if m then pcall(function() m.Icon = Cur.oldIcon or "" end) end
	end
end

-- watermark
local WM = { on = true, gui = nil, lab = nil, conn = nil, fps = 60, acc = 0, n = 0, t = 0 }
local function wmFrame(dt)
	if not WM.on then return end
	WM.acc = WM.acc + dt
	WM.n = WM.n + 1
	WM.t = WM.t + dt
	if WM.t >= 0.5 then
		WM.fps = math.floor(WM.n / math.max(WM.t, 0.01) + 0.5)
		WM.n, WM.t = 0, 0
		if WM.lab then
			pcall(function() WM.lab.Text = "shitaro  |  " .. WM.fps .. " fps" end)
		end
	end
end
local function setWatermark(on)
	WM.on = on
	if on then
		if not WM.gui or not WM.gui.Parent then
			local g = Instance.new("ScreenGui")
			g.Name = "WorldWM"
			g.ResetOnSpawn = false
			g.IgnoreGuiInset = true
			g.DisplayOrder = 400
			local ok, par = pcall(function() return gethui() end)
			if ok and typeof(par) == "Instance" then g.Parent = par
			else
				pcall(function() g.Parent = game:GetService("CoreGui") end)
				if not g.Parent then g.Parent = LP:FindFirstChildOfClass("PlayerGui") end
			end
			WM.gui = g
			WM.lab = Instance.new("TextLabel")
			WM.lab.Size = UDim2.new(0, 170, 0, 22)
			WM.lab.Position = UDim2.new(0, 10, 0, 8)
			WM.lab.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
			WM.lab.BorderSizePixel = 0
			WM.lab.Text = "shitaro"
			WM.lab.Font = Enum.Font.GothamBold
			WM.lab.TextSize = 12
			WM.lab.TextColor3 = Color3.fromRGB(235, 235, 240)
			WM.lab.Parent = g
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent = WM.lab
		end
		WM.gui.Enabled = true
		if not WM.conn then
			WM.conn = RS.Heartbeat:Connect(wmFrame)
		end
	else
		if WM.conn then pcall(function() WM.conn:Disconnect() end) WM.conn = nil end
		if WM.gui then WM.gui.Enabled = false end
	end
end

-- furry badge (mascot placeholder on menu corner)
local Fur = { on = true, f = nil }
local function setFurry(on)
	Fur.on = on
	if on then
		if not Fur.f or not Fur.f.Parent then
			local f = Instance.new("Frame")
			f.Name = "Furry"
			f.Size = UDim2.new(0, 120, 0, 30)
			f.Position = UDim2.new(0, -18, 0, -34)
			f.BackgroundTransparency = 1
			local paw = Instance.new("TextLabel")
			paw.Size = UDim2.new(0, 30, 0, 30)
			paw.BackgroundTransparency = 1
			paw.Text = "🐾"
			paw.Font = Enum.Font.Gotham
			paw.TextSize = 24
			paw.Parent = f
			local tx = Instance.new("TextLabel")
			tx.Position = UDim2.new(0, 30, 0, 0)
			tx.Size = UDim2.new(0, 90, 0, 30)
			tx.BackgroundTransparency = 1
			tx.Text = "shitaro"
			tx.Font = Enum.Font.GothamBlack
			tx.TextSize = 15
			tx.TextColor3 = Color3.fromRGB(235, 235, 240)
			tx.TextXAlignment = Enum.TextXAlignment.Left
			tx.Parent = f
			f.Parent = menuGui
			Fur.f = f
		end
		Fur.f.Visible = true
	elseif Fur.f then
		Fur.f.Visible = false
	end
end

------------------------------ BUILD: MENU SETTINGS (misc tab) ------------------------------
do
	do
		local sec = Section(pMisc, "custom cursor", "left")
		local opt = TRow(sec, "custom cursor", false, function(v) setCursor(v) end, true)
		TDrop(opt, "preset", { "cross", "dot", "arrow" }, Cur.preset, function(v)
			Cur.preset = v
			if Cur.on then curBuild() end
		end)
	end

	do
		local sec = Section(pMisc, "menu sounds", "left")
		local opt = TRow(sec, "menu sounds", false, function(v) MenuSnd.on = v end, true)
		TDrop(opt, "sound", { "Click", "Tick", "Slash" }, MenuSnd.tone, function(v) MenuSnd.tone = v end)
	end

	do
		local sec = Section(pMisc, "furry", "left")
		TRow(sec, "furry", true, function(v) setFurry(v) end, false)
	end

	do
		local sec = Section(pMisc, "hotkeys", "left")
		TRow(sec, "hotkeys", true, function(v)
			ShowBinds = v
			for _, b in ipairs(BindBtns) do
				pcall(function() b.Visible = v end)
			end
		end, false)
	end

	do
		local sec = Section(pMisc, "watermark", "right")
		TRow(sec, "watermark", true, function(v) setWatermark(v) end, false)
	end

	do
		local sec = Section(pMisc, "menu key", "right")
		TKey(sec, "menu key", "Insert", function(k)
			local ok, kc = pcall(function() return Enum.KeyCode[k] end)
			if ok and kc then MenuKey = kc end
		end)
	end

	do
		local sec = Section(pMisc, "telegram", "right")
		TBtn(sec, "telegram", function()
			if type(setclipboard) == "function" then
				pcall(setclipboard, "https://t.me/shitarouse")
			end
			print("[world] copied invite to gay party")
		end)
	end

	do
		local sec = Section(pMisc, "unload", "right")
		TBtn(sec, "Unload", function()
			local g = getgenv()
			if g.LX then pcall(g.LX.unload) end
			if g.EX then pcall(g.EX.unload) end
			if g.MXF then pcall(g.MXF.unload) end
			if g.MX then pcall(g.MX.unload) end
			if g.CX then pcall(g.CX.unload) end
			if g.MDL then pcall(g.MDL.unload) end
			if g.FXM then g.FXM.st.on = false pcall(g.FXM.stop) end
			if g.FXP then g.FXP.st.on = false pcall(g.FXP.stop) end
			if g.FXT then pcall(g.FXT.stop) end
			if g.SH then pcall(g.SH.unload) end
			if g.KA then pcall(g.KA.unload) end
			if g.AF then pcall(g.AF.unload) end
			if g.TT then pcall(g.TT.unload) end
			if g.NT then pcall(g.NT.unload) end
			if g.SN then pcall(g.SN.unload) end
			if g.FR then pcall(g.FR.unload) end
			if g.MP then pcall(g.MP.unload) end
			if g.SKN then pcall(g.SKN.unload) end
			if g.SV then pcall(g.SV.unload) end
			setCursor(false)
			setWatermark(false)
			unloadAll()
		end)
	end

	setFurry(true)
	setWatermark(true)
	print("[world] menu settings loaded")
end
------------------------------ TARGET ENGINE ------------------------------
function initTarget()
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local ws = workspace
	local lp = players.LocalPlayer

	local sel_map, sel_order = {}, {}
	local busy = false
	local primary = nil
	local plist, info = nil, nil
	local fling_on, spectate_on, looptp_on = false, false, false
	local headsit_on, bang_on = false, false
	local bang_speed = 3
	local fling_bypass_velocity = false
	local bang_track, bang_anim, bang_hum = nil, nil, nil
	local tpx, tpy, tpz = 0, 0, 0

	local function my_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end
	local function tgt_hrp(plr)
		local c = plr and plr.Character
		return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head"))
	end
	local function tp_root(cf)
		if getgenv().SHITARO_TELEPORT and getgenv().SHITARO_TELEPORT(cf) then return end
		local hrp = my_hrp()
		if hrp then hrp.CFrame = cf end
	end
	local function player_list(excl)
		local t = {}
		for _, p in ipairs(players:GetPlayers()) do
			if p ~= lp and p ~= excl then
				t[#t + 1] = { name = p.Name, display = p.DisplayName, id = p.UserId }
			end
		end
		return t
	end

	local function label_for(name)
		if not name then return "none" end
		local p = players:FindFirstChild(name)
		return (p and p.DisplayName) or name
	end

	local function modes()
		local t = {}
		if spectate_on then t[#t + 1] = "spec" end
		if headsit_on then t[#t + 1] = "sit" end
		if bang_on then t[#t + 1] = "bang" end
		if looptp_on then t[#t + 1] = "tp" end
		if #t == 0 then return "" end
		return " [" .. table.concat(t, " ") .. "]"
	end

	local function sync_info()
		if not info then return end
		local n = #sel_order
		if n == 0 then
			info:SetValue("target: none")
		elseif n == 1 then
			info:SetValue("target: " .. label_for(primary) .. modes())
		else
			info:SetValue("target: " .. label_for(primary) .. " (+" .. (n - 1) .. ")" .. modes())
		end
	end

	local function push(names)
		busy = true
		pcall(function() plist:SetValue(names) end)
		busy = false
	end

	local function commit(names)
		local map = {}
		for i = 1, #names do map[names[i]] = true end

		for i = #sel_order, 1, -1 do
			if not map[sel_order[i]] then table.remove(sel_order, i) end
		end

		for i = 1, #names do
			if not sel_map[names[i]] then sel_order[#sel_order + 1] = names[i] end
		end

		sel_map = map

		if not primary or not players:FindFirstChild(primary) then
			primary = sel_order[#sel_order]
		end

		sync_info()
	end

	local function on_pick(v)
		if busy then return end

		local names = {}
		if type(v) == "table" then
			for _, nm in ipairs(v) do
				if type(nm) == "string" and nm ~= "" then names[#names + 1] = nm end
			end
		elseif type(v) == "string" and v ~= "" then
			names[1] = v
		end

		commit(names)
	end

	local open_ctx = nil

	local function refresh_lists(excl)
		local plrs = player_list(excl)
		local keep = {}
		for i = 1, #plrs do keep[plrs[i].name] = true end
		for i = #sel_order, 1, -1 do
			if not keep[sel_order[i]] then
				sel_map[sel_order[i]] = nil
				table.remove(sel_order, i)
			end
		end
		if primary and not players:FindFirstChild(primary) then
			primary = nil
		end
		if not primary then
			primary = sel_order[#sel_order]
		end
		pcall(function() plist:SetData(plrs) end)
		sync_info()
	end

	local add_conn = players.PlayerAdded:Connect(function() refresh_lists() end)
	local rem_conn = players.PlayerRemoving:Connect(function(p) refresh_lists(p) end)
	refresh_lists()

	local function do_fling(tp)
		if not tp or not tp.Character then return end
		local hrp = my_hrp()
		local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if not hrp then return end
		local tc = tp.Character
		local thrp = tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Head")
		local th = tc:FindFirstChildOfClass("Humanoid")
		if not thrp then return end
		getgenv().FLING_ACTIVE = (getgenv().FLING_ACTIVE or 0) + 1
		if hrp.Velocity.Magnitude < 50 then
			getgenv().OldPos = hrp.CFrame
		end
		if th and th.Sit then
			getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
			return
		end
		local camera = ws.CurrentCamera
		local old_fdh = ws.FallenPartsDestroyHeight
		if thrp then
			camera.CameraSubject = thrp
		elseif th then
			camera.CameraSubject = th
		end
		pcall(function() ws.FallenPartsDestroyHeight = 0/0 end)
		local bv = Instance.new("BodyVelocity")
		bv.Parent = hrp
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		local se = hum and hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
		local tw = 2
		local tm = tick()
		local ang = 0
		repeat
			if hrp and th then
				local tv
				if fling_bypass_velocity then
					tv = th.MoveDirection * th.WalkSpeed
				else
					tv = thrp.Velocity
				end
				if tv.Magnitude < 50 then
					ang = ang + 100
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				else
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, -th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				end
			end
		until tm + tw < tick() or not fling_on
		if bv then bv:Destroy() end
		if hum and se ~= nil then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, se) end
		camera.CameraSubject = hum
		if getgenv().OldPos and hrp then
			hrp.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
			lp.Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
			if hum then hum:ChangeState("GettingUp") end
			for _, part in pairs(lp.Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.Velocity = Vector3.new()
					part.RotVelocity = Vector3.new()
				end
			end
			pcall(function() ws.FallenPartsDestroyHeight = old_fdh end)
		end
		getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
	end

	local function selected_present()
		local list, seen = {}, {}
		for i = 1, #sel_order do
			local name = sel_order[i]
			if not seen[name] then
				local p = players:FindFirstChild(name)
				if p and p ~= lp then
					seen[name] = true
					list[#list + 1] = p
				end
			end
		end
		return list
	end

	local fling_thread = nil
	local function start_fling()
		if fling_thread then return end
		fling_thread = task.spawn(function()
			while fling_on do
				local list = selected_present()
				if #list == 0 then
					task.wait(0.3)
				else
					for i = 1, #list do
						if not fling_on then break end
						local tp = list[i]
						if tp and tp.Parent and tp.Character then
							if my_hrp() then
								do_fling(tp)
							else
								task.wait(0.2)
							end
						end
					end
					task.wait()
				end
			end
			fling_thread = nil
		end)
	end

	local rs = game:GetService("ReplicatedStorage")

	local kill_round_mod = nil

	local function kill_require_round()
		return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
	end

	local function kill_data()
		if not kill_round_mod then
			local ok, m = pcall(kill_require_round)
			if not ok or type(m) ~= "table" then return nil end
			kill_round_mod = m
		end
		return kill_round_mod.PlayerData
	end

	local function target_killable(data, plr)
		local info = data and data[plr.Name]
		if type(info) ~= "table" then return false end
		if info.Dead then return false end
		return info.Role == "Innocent" or info.Role == "Sheriff" or info.Role == "Hero"
	end

	local function get_kill_knife()
		local char = lp.Character
		if char then
			local equipped = char:FindFirstChild("Knife")
			if equipped then return equipped, true end
		end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then
			local stored = bp:FindFirstChild("Knife")
			if stored then return stored, false end
		end
		return nil, false
	end

	local function ensure_kill_knife()
		local knife, equipped = get_kill_knife()
		if not knife then return nil end
		if not equipped then
			local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(knife) end) end
			return nil
		end
		return knife
	end

	local function kill_stab(knife)
		local events = knife:FindFirstChild("Events")
		local stabbed = events and events:FindFirstChild("KnifeStabbed")
		if stabbed then pcall(function() stabbed:FireServer() end) end
	end

	local function kill_touch(knife, part)
		local events = knife:FindFirstChild("Events")
		local touched = events and events:FindFirstChild("HandleTouched")
		if touched then pcall(function() touched:FireServer(part) end) end
	end

	local kill_on = false
	local last_target_kill = 0
	local kill_thread = nil
	local function start_kill()
		if kill_thread then return end
		kill_thread = task.spawn(function()
			while kill_on do
				local data = kill_data()
				local me = data and data[lp.Name]
				if not (me ~= nil and me.Role == "Murderer" and not me.Dead) then
					task.wait(0.3)
					continue
				end
				if getgenv().AUTOFARM_HOLD then
					task.wait()
					continue
				end
				local knife = ensure_kill_knife()
				if not knife then
					task.wait(0.1)
					continue
				end
				if os.clock() - last_target_kill < 0.05 then
					task.wait()
					continue
				end
				local list = selected_present()
				local victims = {}
				for i = 1, #list do
					local plr = list[i]
					if target_killable(data, plr) then
						local tc = plr.Character
						local hum = tc and tc:FindFirstChildOfClass("Humanoid")
						local part = tc and (tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Head"))
						if hum and hum.Health > 0 and part then
							victims[#victims + 1] = part
						end
					end
				end
				if #victims > 0 then
					kill_stab(knife)
					for _, part in ipairs(victims) do
						kill_touch(knife, part)
					end
					last_target_kill = os.clock()
				end
				task.wait()
			end
			kill_thread = nil
		end)
	end



	local function cur_target()
		local name = primary or sel_order[#sel_order]
		if not name or name == "" then return nil end
		local p = players:FindFirstChild(name)
		if p and p ~= lp then return p end
	end

	local spec_conn = run.RenderStepped:Connect(function()
		if not spectate_on then return end
		local tp = cur_target()
		local thrp = tgt_hrp(tp)
		local th = tp and tp.Character and tp.Character:FindFirstChildOfClass("Humanoid")
		if thrp then
			ws.CurrentCamera.CameraSubject = th or thrp
		end
	end)

	local looptp_conn = run.Heartbeat:Connect(function()
		if not looptp_on then return end
		local thrp = tgt_hrp(cur_target())
		local hrp = my_hrp()
		if thrp and hrp then
			tp_root(thrp.CFrame + Vector3.new(tpx, tpy, tpz))
		end
	end)

	local function my_hum()
		local c = lp.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function is_r15(char)
		local h = char and char:FindFirstChildOfClass("Humanoid")
		return h ~= nil and h.RigType == Enum.HumanoidRigType.R15
	end

	local headsit_conn = run.Heartbeat:Connect(function()
		if not headsit_on then return end
		local thrp = tgt_hrp(cur_target())
		local hrp = my_hrp()
		local hum = my_hum()
		if thrp and hrp and hum then
			hum.Sit = true
			hrp.CFrame = thrp.CFrame * CFrame.new(0, 1.6, 0.4)
		end
	end)

	local function ensure_bang_anim()
		local hum = my_hum()
		if not hum then return end
		if bang_hum == hum and bang_track then return end
		if bang_track then pcall(function() bang_track:Stop() end) bang_track = nil end
		if bang_anim then pcall(function() bang_anim:Destroy() end) bang_anim = nil end
		bang_anim = Instance.new("Animation")
		bang_anim.AnimationId = is_r15(lp.Character) and "rbxassetid://5918726674" or "rbxassetid://148840371"
		local ok, tr = pcall(function() return hum:LoadAnimation(bang_anim) end)
		if ok and tr then
			bang_track = tr
			bang_track.Looped = true
			bang_track:Play(0.1, 1, 1)
			bang_track:AdjustSpeed(bang_speed)
			bang_hum = hum
		end
	end

	local function stop_bang()
		if bang_track then pcall(function() bang_track:Stop() end) bang_track = nil end
		if bang_anim then pcall(function() bang_anim:Destroy() end) bang_anim = nil end
		bang_hum = nil
	end

	local bang_conn = run.Stepped:Connect(function()
		if not bang_on then return end
		ensure_bang_anim()
		local thrp = tgt_hrp(cur_target())
		local hrp = my_hrp()
		if thrp and hrp then
			hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 1.1)
		end
	end)

	local function stop_spectate()
		local myh = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if myh then ws.CurrentCamera.CameraSubject = myh end
	end

	local function aim_at(name)
		primary = name
		sync_info()
	end

	local function tune(name, key, want)
		aim_at(name)

		if key == "spectate" then
			spectate_on = want
			if not want then stop_spectate() end
		elseif key == "headsit" then
			headsit_on = want
			if not want then
				local hum = my_hum()
				if hum then hum.Sit = false end
			end
		elseif key == "bang" then
			bang_on = want
			if want then ensure_bang_anim() else stop_bang() end
		elseif key == "looptp" then
			looptp_on = want
		end

		sync_info()

		return want
	end
	open_ctx = function(name, x, y, cell)
		local plr = players:FindFirstChild(name)
		if not plr or plr == lp then return end

		local live = primary == name

		popmenu({
			title = plr.DisplayName,
			icon = "user",
			x = x,
			y = y,
			follow = cell,
			items = {
				{
					icon = "map-pin",
					name = "teleport",
					callback = function()
						aim_at(name)
						local thrp = tgt_hrp(plr)
						local hrp = my_hrp()
						if thrp and hrp then
							tp_root(thrp.CFrame + Vector3.new(tpx, tpy, tpz))
						end
					end
				},
				{
					icon = "crosshair",
					name = "set",
					callback = function()
						aim_at(name)
					end
				},
				{
					icon = "video",
					name = "spectate",
					on = live and spectate_on,
					callback = function()
						return tune(name, "spectate", not (primary == name and spectate_on))
					end
				},
				{
					icon = "person-standing",
					name = "headsit",
					on = live and headsit_on,
					callback = function()
						return tune(name, "headsit", not (primary == name and headsit_on))
					end
				},
				{
					icon = "heart",
					name = "bang",
					on = live and bang_on,
					callback = function()
						return tune(name, "bang", not (primary == name and bang_on))
					end
				},
				{
					icon = "move",
					name = "loop tp",
					on = live and looptp_on,
					callback = function()
						return tune(name, "looptp", not (primary == name and looptp_on))
					end
				},
			}
		})
	end
	getgenv().TARGET_UNLOAD = function()
		fling_on, spectate_on, looptp_on = false, false, false
		headsit_on, bang_on = false, false
		kill_on = false
		if add_conn then pcall(function() add_conn:Disconnect() end) add_conn = nil end
		if rem_conn then pcall(function() rem_conn:Disconnect() end) rem_conn = nil end
		if spec_conn then pcall(function() spec_conn:Disconnect() end) spec_conn = nil end
		if looptp_conn then pcall(function() looptp_conn:Disconnect() end) looptp_conn = nil end
		if headsit_conn then pcall(function() headsit_conn:Disconnect() end) headsit_conn = nil end
		if bang_conn then pcall(function() bang_conn:Disconnect() end) bang_conn = nil end
		pcall(stop_bang)
		local myh = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if myh then pcall(function() myh.Sit = false end) end
		pcall(function() ws.FallenPartsDestroyHeight = -500 end)
		if myh then pcall(function() ws.CurrentCamera.CameraSubject = myh end) end
	end
	getgenv().TG = {
		setFling = function(v)
			fling_on = v
			if v then start_fling() end
		end,
		setVelCheck = function(v) fling_bypass_velocity = v end,
		setKill = function(v)
			kill_on = v
			if v then start_kill() end
		end,
		setBangSpeed = function(v)
			bang_speed = v
			if bang_track then pcall(function() bang_track:AdjustSpeed(bang_speed) end) end
		end,
		setX = function(v) tpx = v end,
		setY = function(v) tpy = v end,
		setZ = function(v) tpz = v end,
		listPlayers = function() return player_list() end,
		getSelected = function()
			local t = {}
			for i = 1, #sel_order do t[#t + 1] = sel_order[i] end
			return t
		end,
		pick = function(names) on_pick(names) end,
		refresh = function() refresh_lists() end,
		ctx = function(name)
			local mp = game:GetService("UserInputService"):GetMouseLocation()
			if open_ctx then open_ctx(name, mp.X, mp.Y, nil) end
		end,
		linkList = function(p, i) plist = p info = i end,
		unload = getgenv().TARGET_UNLOAD,
	}
end
do
print("[world] init initTarget...")
local ok, err = pcall(initTarget)
print("[world] init initTarget " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ TARGET GUI ------------------------------
local popCtx = nil
function popmenu(data)
	if popCtx then pcall(function() popCtx:Destroy() end) popCtx = nil end
	local items = data.items or {}
	local h = 34 + #items * 28
	local pop = mk("Frame", {
		Size = UDim2.new(0, 170, 0, h),
		Position = UDim2.new(0, math.min(data.x or 200, 480), 0, math.min(data.y or 100, 300)),
		BackgroundColor3 = C(21, 21, 29), BorderSizePixel = 0, ZIndex = 100,
	}, menuGui)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, pop)
	mk("UIStroke", { Color = ACCENT, Thickness = 1 }, pop)
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
		Text = data.title or "", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = TXT, ZIndex = 101,
	}, pop)
	mk("Frame", {
		Position = UDim2.new(0, 8, 0, 28), Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = C(55, 55, 72), BorderSizePixel = 0, ZIndex = 101,
	}, pop)
	for i, it in ipairs(items) do
		local b = mk("TextButton", {
			Position = UDim2.new(0, 8, 0, 32 + (i - 1) * 28), Size = UDim2.new(1, -16, 0, 26),
			BackgroundColor3 = C(27, 27, 37), BorderSizePixel = 0,
			Text = (it.on and "✓ " or "") .. (it.name or ""),
			Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = it.on and ACCENT or TXT, ZIndex = 101,
		}, pop)
		mk("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
		b.MouseButton1Click:Connect(function()
			pcall(it.callback)
			if popCtx == pop then
				pcall(function() pop:Destroy() end)
				popCtx = nil
			end
		end)
	end
	popCtx = pop
	task.delay(12, function()
		if popCtx == pop then
			pcall(function() pop:Destroy() end)
			popCtx = nil
		end
	end)
end

------------------------------ BUILD: TARGET ------------------------------
do
	local TG = getgenv().TG

	local sec = Section(pTarget, "players", "left")
	local infoLabel = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "target: none", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left,
	}, sec)
	local listHost = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, sec)
	mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)

	local function selectedSet()
		local s = {}
		for _, n in ipairs(TG.getSelected()) do s[n] = true end
		return s
	end

	local function rebuildRows()
		for _, ch in ipairs(listHost:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local sel = selectedSet()
		local all = TG.listPlayers()
		if #all == 0 then
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
				Text = "nobody around", Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
			}, listHost)
			return
		end
		table.sort(all, function(a, b) return (a.display or a.name) < (b.display or b.name) end)
		for _, e in ipairs(all) do
			local on = sel[e.name] and true or false
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, listHost)
			local box = mk("TextButton", {
				Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = on and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
				AutoButtonColor = false, Text = "",
			}, row)
			mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
			mk("UIStroke", { Color = on and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Text = on and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
				TextColor3 = C(255, 255, 255),
			}, box)
			local nm = e.display and (e.display .. " (@" .. e.name .. ")") or e.name
			local lab = mk("TextButton", {
				Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -46, 1, 0),
				BackgroundTransparency = 1, Text = nm,
				Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = on and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
			}, row)
			local dots = mk("TextButton", {
				Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 24, 1, 0),
				BackgroundTransparency = 1, Text = "...", Font = Enum.Font.GothamBold, TextSize = 14,
				TextColor3 = FAINT, AutoButtonColor = false,
			}, row)
			local function toggleSel()
				local cur = TG.getSelected()
				local has = false
				local out = {}
				for _, n in ipairs(cur) do
					if n == e.name then has = true
					else out[#out + 1] = n end
				end
				if not has then out[#out + 1] = e.name end
				TG.pick(out)
				rebuildRows()
			end
			box.MouseButton1Click:Connect(toggleSel)
			lab.MouseButton1Click:Connect(toggleSel)
			dots.MouseButton1Click:Connect(function() TG.ctx(e.name) end)
		end
	end

	local plistAd = {
		SetValue = function(_, names) rebuildRows() end,
		SetData = function(_) rebuildRows() end,
	}
	local infoAd = {
		SetValue = function(_, t) infoLabel.Text = tostring(t) end,
	}
	TG.linkList(plistAd, infoAd)
	rebuildRows()
	task.spawn(function()
		while task.wait(3) do
			if not infoLabel.Parent then break end
			pcall(function() TG.refresh() end)
			pcall(rebuildRows)
		end
	end)

	do
		local asec = Section(pTarget, "actions", "right")
		local fopt = TRow(asec, "fling", false, function(v) TG.setFling(v) end, true)
		TRow(fopt, "velocity check", false, function(v) TG.setVelCheck(v) end, false)
		TRow(asec, "kill", false, function(v) TG.setKill(v) end, false)
		TSlider(asec, "bang speed", 1, 10, 3, 0, function(v) TG.setBangSpeed(v) end)
		TSlider(asec, "x", 0, 5, 0, 0, function(v) TG.setX(v) end)
		TSlider(asec, "y", 0, 5, 0, 0, function(v) TG.setY(v) end)
		TSlider(asec, "z", 0, 5, 0, 0, function(v) TG.setZ(v) end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		TG.unload()
		if popCtx then pcall(function() popCtx:Destroy() end) popCtx = nil end
	end)
end
------------------------------ ANIM ENGINE ------------------------------
function initAnim()
	local players, http = game:GetService("Players"), game:GetService("HttpService")
	local lp = players.LocalPlayer
	local cats = {
		{"Idle", "idle"},
		{"Walk", "walk"},
		{"Run", "run"},
		{"Jump", "jump"},
		{"Fall", "fall"},
		{"Climb", "climb"},
		{"Swim", "swim"},
		{"Swim Idle", "swimidle"}
	}
	local cat_names, cat_map = {}, {}
	for _, c in ipairs(cats) do
		cat_names[#cat_names+1] = c[1]
		cat_map[c[1]] = c[2]
	end
	local animItems, byName, mapCache, sel, origMap = {}, {}, {}, {}, {}
	local enabled, animConn, active = false, nil, "idle"
	local fetched, pendingApply, selLockUntil, applyToken = false, false, 0, 0

	local function getParts()
		local char = lp.Character
		if not char then return end
		return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("Animate")
	end

	local function refreshAnimate(animate, hum)
		if animate and hum and hum.MoveDirection.Magnitude == 0 then
			animate.Disabled = true
			animate.Disabled = false
		end
	end

	local function stopTracks(hum)
		if not hum then return end
		for _, track in pairs(hum:GetPlayingAnimationTracks()) do
			pcall(function() track:Stop() end)
		end
	end

	local function resolveMappings(data)
		local key = tostring(data.id)
		if mapCache[key] then return mapCache[key] end
		local bundled = data.bundledItems
		if type(bundled) ~= "table" then return nil end
		local mappings = {}
		for _, ids in pairs(bundled) do
			if type(ids) == "table" then
				for _, assetId in pairs(ids) do
					local ok, objs = pcall(game.GetObjects, game, "rbxassetid://"..assetId)
					if ok and objs then
						local function scan(parent, path)
							for _, child in ipairs(parent:GetChildren()) do
								if child:IsA("Animation") then
									local parts = (path.."."..child.Name):split(".")
									mappings[#mappings+1] = {category = parts[#parts-1], name = parts[#parts], id = child.AnimationId}
								elseif #child:GetChildren() > 0 then
									scan(child, path.."."..child.Name)
								end
							end
						end
						for _, o in ipairs(objs) do scan(o, o.Name) pcall(function() o:Destroy() end) end
					end
				end
			end
		end
		mapCache[key] = mappings
		return mappings
	end

	local function catItems(data, folderName)
		local mappings = resolveMappings(data)
		if not mappings then return nil end
		local items = {}
		for _, m in ipairs(mappings) do
			if m.category and m.category:lower() == folderName then
				items[m.name:lower()] = m.id
			end
		end
		return items
	end

	local function applyCat(animate, folderName, data)
		if not (animate and data) then return end
		local items = catItems(data, folderName)
		if not (items and next(items)) then return end
		local folder = animate:FindFirstChild(folderName)
		if not folder then return end
		local _, first = next(items)
		for _, a in ipairs(folder:GetChildren()) do
			if a:IsA("Animation") then
				local id = items[a.Name:lower()] or first
				if id then
					if origMap[a] == nil then origMap[a] = a.AnimationId end
					a.AnimationId = id
					a.Parent = nil
					a.Parent = folder
				end
			end
		end
	end

	local function applyAll(animate)
		for _, c in ipairs(cats) do
			local name = sel[c[2]]
			if name and name ~= "none" and byName[name] then
				applyCat(animate, c[2], byName[name])
			end
		end
	end

	local function restore()
		for a, id in pairs(origMap) do
			if a and a.Parent then
				pcall(function()
					local folder = a.Parent
					a.AnimationId = id
					a.Parent = nil
					a.Parent = folder
				end)
			end
		end
		origMap = {}
	end

	local function doApply()
		applyToken += 1
		local token = applyToken
		task.spawn(function()
			local _, hum, animate = getParts()
			if not animate or token ~= applyToken then return end
			stopTracks(hum)
			restore()
			applyAll(animate)
			if token == applyToken then
				refreshAnimate(animate, hum)
			end
		end)
	end

	local function requestApply()
		if not enabled then return end
		if not fetched then
			pendingApply = true
			return
		end
		doApply()
	end

	local function fetchAll()
		local urls = {
			"https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json",
			"https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniperoffsale.json"
		}
		local seen = {}
		for _, url in ipairs(urls) do
			local ok, res = pcall(function()
				local c = game:HttpGet(url)
				return c ~= "" and http:JSONDecode(c) or nil
			end)
			if ok and type(res) == "table" then
				local list = res.data or res
				for _, item in pairs(list) do
					local id = tonumber(item.id)
					if id and id > 0 and item.bundledItems and not seen[id] then
						seen[id] = true
						local nm = tostring(item.name or ("Animation_"..id))
						if byName[nm] then nm = nm.." ["..id.."]" end
						byName[nm] = {id = id, bundledItems = item.bundledItems}
						if #animItems < 800 then
							animItems[#animItems+1] = {name = nm, id = id}
						end
					end
				end
			end
		end
	end

	local al
	local busy = false

	local function used()
		local s = {}
		for _, c in ipairs(cats) do
			local nm = sel[c[2]]
			if type(nm) == "string" and nm ~= "" and nm ~= "none" then s[nm] = true end
		end
		return s
	end

	local function bind_respawn()
		if animConn then return end
		animConn = lp.CharacterAdded:Connect(function(c)
			c:WaitForChild("Humanoid")
			local animate = c:WaitForChild("Animate", 5)
			task.wait(0.3)
			if enabled and animate then
				origMap = {}
				requestApply()
			end
		end)
	end

	local function drop_respawn()
		if animConn then pcall(function() animConn:Disconnect() end) animConn = nil end
	end

	local function wipe_anims()
		local _, hum, animate = getParts()
		stopTracks(hum)
		restore()
		refreshAnimate(animate, hum)
	end

	local function push_sel()
		if not al then return end
		local names = {}
		for nm in pairs(used()) do names[#names + 1] = nm end
		busy = true
		pcall(function() al:SetValue(names) end)
		busy = false
	end

	local function settle()
		if next(used()) ~= nil then
			enabled = true
			bind_respawn()
			requestApply()
		else
			enabled = false
			pendingApply = false
			applyToken += 1
			drop_respawn()
			wipe_anims()
		end
	end

	local function has_all(name)
		for _, c in ipairs(cats) do
			if sel[c[2]] ~= name then return false end
		end
		return true
	end

	local function assign(name, key, want)
		if key == "all" then
			for _, c in ipairs(cats) do
				if want then
					sel[c[2]] = name
				elseif sel[c[2]] == name then
					sel[c[2]] = nil
				end
			end
		else
			if want then
				sel[key] = name
			elseif sel[key] == name then
				sel[key] = nil
			end
		end
		push_sel()
		settle()
	end

	local function open_cats(name, x, y, cell)
		if not byName[name] then return end

		local rows = {
			{
				icon = "layers",
				name = "All",
				on = has_all(name),
				callback = function()
					assign(name, "all", not has_all(name))
					return has_all(name)
				end
			}
		}

		for _, c in ipairs(cats) do
			local key = c[2]
			rows[#rows + 1] = {
				icon = "circle-dot",
				name = c[1],
				on = sel[key] == name,
				callback = function()
					assign(name, key, sel[key] ~= name)
					return sel[key] == name
				end
			}
		end

		popmenu({ title = name, icon = "footprints", x = x, y = y, follow = cell, items = rows })
	end

	task.delay(8, function()
		print("[world] fetching anim bundles...")
		fetchAll()
		fetched = true
		print("[world] anim bundles: " .. #animItems)
		pcall(function() al:SetData(animItems) end)
		push_sel()
		if pendingApply then
			pendingApply = false
			requestApply()
		end
	end)
	getgenv().ANIM_UNLOAD = function()
		enabled = false
		pendingApply = false
		applyToken += 1
		pcall(function() lib:unhook("player_anim_sel") end)
		if animConn then pcall(function() animConn:Disconnect() end) animConn = nil end
		local _, hum, animate = getParts()
		stopTracks(hum)
		restore()
		if animate then
			pcall(function()
				animate.Disabled = true
				animate.Disabled = false
			end)
		end
	end
	getgenv().AN = {
		items = function() return animItems end,
		usedSet = function() return used() end,
		selMap = function()
			local t = {}
			for k, v in pairs(sel) do t[k] = v end
			return t
		end,
		cats = cats,
		toggle = function(name)
			local prev = used()
			if prev[name] then
				for _, c in ipairs(cats) do if sel[c[2]] == name then sel[c[2]] = nil end end
			else
				for _, c in ipairs(cats) do sel[c[2]] = name end
			end
			push_sel()
			settle()
		end,
		ctx = function(name)
			local mp = game:GetService("UserInputService"):GetMouseLocation()
			open_cats(name, mp.X, mp.Y, nil)
		end,
		setList = function(o) al = o end,
		refresh = function() push_sel() end,
		unload = getgenv().ANIM_UNLOAD,
	}
end
do
print("[world] init initAnim...")
local ok, err = pcall(initAnim)
print("[world] init initAnim " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ EMOTE ENGINE ------------------------------
function initEmote()
	local players, http = game:GetService("Players"), game:GetService("HttpService")
	local lp = players.LocalPlayer
	local emoteFile = "emotes.json"
	local statEmotes = {
		{"Griddy", "129149402922241"}
	}
	local custEmotes, emoteMap, emoteList, animCache = {}, {}, {}, {}
	local allList, allMap = {}, {}
	local curTrack, selId, custRaw, alive = nil, nil, nil, true

	local function parseCustom()
		if not (isfile and isfile(emoteFile)) then
			if custRaw ~= nil then custRaw, custEmotes = nil, {} return true end
			return false
		end
		local ok, raw = pcall(readfile, emoteFile)
		if not ok or raw == custRaw then return false end
		custRaw, custEmotes = raw, {}
		local dok, data = pcall(function() return http:JSONDecode(raw) end)
		if dok and type(data) == "table" then
			for k, v in pairs(data) do
				local name, id
				if type(v) == "table" then
					name, id = tostring(v.name or v[1] or k), tostring(v.id or v[2] or "")
				else
					name, id = tostring(k), tostring(v)
				end
				if name ~= "" and id ~= "" then
					custEmotes[#custEmotes+1] = {name, id}
				end
			end
		end
		return true
	end

	local function buildList()
		emoteMap, emoteList = {}, {}
		local function add(name, id)
			name = tostring(name)
			if emoteMap[name] then name = name.." ["..tostring(id).."]" end
			emoteMap[name] = tostring(id)
			emoteList[#emoteList+1] = {name = name, id = tonumber((tostring(id):gsub("%D", ""))) or id}
		end
		for _, e in ipairs(statEmotes) do
			add(e[1], e[2])
		end
		for _, e in ipairs(custEmotes) do
			add(e[1], e[2])
		end
		for _, e in ipairs(allList) do
			add(e.name, e.id)
		end
	end

	parseCustom()
	buildList()

	local function getHum()
		local char = lp.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	local function stopEmote()
		if curTrack then
			pcall(function() curTrack:Stop() end)
			curTrack = nil
		end
	end

	local function resolveId(id)
		if animCache[id] then return animCache[id] end
		if id:find("://") then animCache[id] = id return id end
		local raw = id:gsub("%D", "")
		local ok, objs = pcall(game.GetObjects, game, "rbxassetid://"..raw)
		if ok and type(objs) == "table" then
			local found
			local function scan(inst)
				if found then return end
				if inst:IsA("Animation") and inst.AnimationId ~= "" then
					found = inst.AnimationId
					return
				end
				for _, c in ipairs(inst:GetChildren()) do scan(c) end
			end
			for _, o in ipairs(objs) do scan(o) pcall(function() o:Destroy() end) end
			if found then animCache[id] = found return found end
		end
		local url = "rbxassetid://"..raw
		animCache[id] = url
		return url
	end

	local function playEmote()
		local hum = getHum()
		if not hum or not selId then return end
		stopEmote()
		local anim = Instance.new("Animation")
		anim.AnimationId = resolveId(selId)
		local ok, track = pcall(function() return hum:LoadAnimation(anim) end)
		anim:Destroy()
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play()
			curTrack = track
		end
	end

	local el
	local function refresh()
		if parseCustom() then
			buildList()
			pcall(function() el:SetData(emoteList) end)
		end
	end

	local function fetchEmotes()
		local ok, res = pcall(function()
			local c = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json")
			return c ~= "" and http:JSONDecode(c) or nil
		end)
		if ok and type(res) == "table" then
			local list = res.data or res
			local seen = {}
			for _, item in pairs(list) do
				local id = tonumber(item.id)
				if id and id > 0 and not seen[id] then
					seen[id] = true
					local nm = tostring(item.name or ("Emote_"..id))
					if allMap[nm] then nm = nm.." ["..id.."]" end
					allMap[nm] = tostring(id)
					if #allList < 800 then
						allList[#allList+1] = {name = nm, id = id}
					end
				end
			end
		end
	end

	task.delay(12, function()
		print("[world] fetching emotes...")
		fetchEmotes()
		buildList()
		print("[world] emotes: " .. #emoteList)
		pcall(function() el:SetData(emoteList) end)
	end)

	local char_conn = lp.CharacterAdded:Connect(function()
		task.wait(1)
		if selId then playEmote() end
	end)

	task.spawn(function()
		while alive and task.wait(3) do
			refresh()
		end
	end)

	getgenv().EMOTE_UNLOAD = function()
		alive, selId = false, nil
		stopEmote()
		if char_conn then pcall(function() char_conn:Disconnect() end) char_conn = nil end
	end
	getgenv().EM = {
		items = function() return emoteList end,
		current = function()
			if not selId then return nil end
			for nm, id in pairs(emoteMap) do
				if id == selId then return nm end
			end
			return nil
		end,
		select = function(name)
			if type(name) ~= "string" or name == "" then
				selId = nil
				stopEmote()
				return
			end
			selId = emoteMap[name]
			if selId then playEmote() else stopEmote() end
		end,
		setList = function(o) el = o end,
		refresh = function() refresh() end,
		unload = getgenv().EMOTE_UNLOAD,
	}
end
do
print("[world] init initEmote...")
local ok, err = pcall(initEmote)
print("[world] init initEmote " .. (ok and "ok" or ("FAIL: " .. tostring(err))))
end

------------------------------ BUILD: ANIMATIONS + EMOTES ------------------------------
do
	local AN, EM = getgenv().AN, getgenv().EM

	do
		local sec = Section(pAnim, "animations", "left")
		local listHost = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, sec)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)

		local function rebuildAnim()
			for _, ch in ipairs(listHost:GetChildren()) do
				if ch:IsA("GuiObject") then ch:Destroy() end
			end
			local used = AN.usedSet()
			local smap = AN.selMap()
			local items = AN.items()
			if #items == 0 then
				mk("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
					Text = "loading bundles", Font = Enum.Font.Gotham, TextSize = 12,
					TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
				}, listHost)
				return
			end
			local names = {}
			for _, e in ipairs(items) do names[#names + 1] = e.name end
			table.sort(names)
			animLimit = math.min(animLimit or 50, 500)
			for i, nm in ipairs(names) do
				if i > animLimit then break end
				local on = used[nm] and true or false
				local catsUsed = {}
				for _, c in ipairs(AN.cats) do
					if smap[c[2]] == nm then catsUsed[#catsUsed + 1] = c[1] end
				end
				local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, listHost)
				local box = mk("TextButton", {
					Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
					BackgroundColor3 = on and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
					AutoButtonColor = false, Text = "",
				}, row)
				mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
				mk("UIStroke", { Color = on and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
				mk("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
					Text = on and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
					TextColor3 = C(255, 255, 255),
				}, box)
				local sub = #catsUsed > 0 and ("   [" .. table.concat(catsUsed, " ") .. "]") or ""
				mk("TextButton", {
					Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -46, 1, 0),
					BackgroundTransparency = 1, Text = nm .. sub,
					Font = Enum.Font.Gotham, TextSize = 12,
					TextColor3 = on and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
				}, row).MouseButton1Click:Connect(function()
					AN.toggle(nm)
					rebuildAnim()
				end)
				box.MouseButton1Click:Connect(function()
					AN.toggle(nm)
					rebuildAnim()
				end)
				mk("TextButton", {
					Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 24, 1, 0),
					BackgroundTransparency = 1, Text = "...", Font = Enum.Font.GothamBold, TextSize = 14,
					TextColor3 = FAINT, AutoButtonColor = false,
				}, row).MouseButton1Click:Connect(function() AN.ctx(nm) end)
			end
			if #names > animLimit then
				local more = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C(27, 27, 37), BorderSizePixel = 0,
					Text = "show more (" .. (#names - animLimit) .. ")", Font = Enum.Font.GothamBold, TextSize = 12,
					TextColor3 = ACCENT,
				}, listHost)
				mk("UICorner", { CornerRadius = UDim.new(0, 4) }, more)
				more.MouseButton1Click:Connect(function()
					animLimit = animLimit + 50
					rebuildAnim()
				end)
			end
		end

		AN.setList({
			SetValue = function(_) rebuildAnim() end,
			SetData = function(_) rebuildAnim() end,
		})
		rebuildAnim()
		AN.refresh()
	end

	do
		local sec = Section(pEmote, "emotes", "left")
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
			Text = "custom: emotes.json in workspace", Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = FAINT, TextXAlignment = Enum.TextXAlignment.Left,
		}, sec)
		local listHost = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, sec)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)

		local function rebuildEmote()
			for _, ch in ipairs(listHost:GetChildren()) do
				if ch:IsA("GuiObject") then ch:Destroy() end
			end
			local cur = EM.current()
			local items = EM.items()
			if #items == 0 then
				mk("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
					Text = "loading emotes", Font = Enum.Font.Gotham, TextSize = 12,
					TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
				}, listHost)
				return
			end
			emoteLimit = math.min(emoteLimit or 50, 500)
			for i, e in ipairs(items) do
				if i > emoteLimit then break end
				local on = cur == e.name
				local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, listHost)
				local box = mk("TextButton", {
					Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
					BackgroundColor3 = on and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
					AutoButtonColor = false, Text = "",
				}, row)
				mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
				mk("UIStroke", { Color = on and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
				mk("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
					Text = on and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
					TextColor3 = C(255, 255, 255),
				}, box)
				local function pick()
					if EM.current() == e.name then
						EM.select(nil)
					else
						EM.select(e.name)
					end
					rebuildEmote()
				end
				mk("TextButton", {
					Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -22, 1, 0),
					BackgroundTransparency = 1, Text = e.name,
					Font = Enum.Font.Gotham, TextSize = 12,
					TextColor3 = on and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
				}, row).MouseButton1Click:Connect(pick)
				box.MouseButton1Click:Connect(pick)
			end
			if #items > emoteLimit then
				local more = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C(27, 27, 37), BorderSizePixel = 0,
					Text = "show more (" .. (#items - emoteLimit) .. ")", Font = Enum.Font.GothamBold, TextSize = 12,
					TextColor3 = ACCENT,
				}, listHost)
				mk("UICorner", { CornerRadius = UDim.new(0, 4) }, more)
				more.MouseButton1Click:Connect(function()
					emoteLimit = emoteLimit + 50
					rebuildEmote()
				end)
			end
		end

		EM.setList({ SetData = function(_) rebuildEmote() end })
		rebuildEmote()
		EM.refresh()
	end

	unloadBtn.MouseButton1Click:Connect(function()
		AN.unload()
		EM.unload()
	end)
end
------------------------------ TOOLS ENGINE ------------------------------
function initTools()
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local ws = workspace
	local lp = players.LocalPlayer

	local function my_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function break_velocity()
		local hrp = my_hrp()
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local function tp_root(cf)
		if getgenv().SHITARO_TELEPORT and getgenv().SHITARO_TELEPORT(cf) then return end
		local hrp = my_hrp()
		if hrp then hrp.CFrame = cf end
	end

	local function do_fling(tp)
		if not tp or not tp.Character then return end
		local hrp = my_hrp()
		local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if not hrp then return end
		local tc = tp.Character
		local thrp = tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Head")
		local th = tc:FindFirstChildOfClass("Humanoid")
		if not thrp then return end
		getgenv().FLING_ACTIVE = (getgenv().FLING_ACTIVE or 0) + 1
		if hrp.Velocity.Magnitude < 50 then
			getgenv().OldPos = hrp.CFrame
		end
		if th and th.Sit then
			getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
			return
		end
		local camera = ws.CurrentCamera
		local old_fdh = ws.FallenPartsDestroyHeight
		if thrp then
			camera.CameraSubject = thrp
		elseif th then
			camera.CameraSubject = th
		end
		pcall(function() ws.FallenPartsDestroyHeight = 0/0 end)
		local bv = Instance.new("BodyVelocity")
		bv.Parent = hrp
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		local se = hum and hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
		local tw = 2
		local tm = tick()
		local ang = 0
		local active = true
		repeat
			if hrp and th then
				local tv
				if fling_tool_bypass_velocity then
					tv = th.MoveDirection * th.WalkSpeed
				else
					tv = thrp.Velocity
				end
				if tv.Magnitude < 50 then
					ang = ang + 100
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				else
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, -th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				end
			end
		until tm + tw < tick() or not active
		if bv then bv:Destroy() end
		if hum and se ~= nil then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, se) end
		camera.CameraSubject = hum
		if getgenv().OldPos and hrp then
			hrp.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
			lp.Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
			if hum then hum:ChangeState("GettingUp") end
			for _, part in pairs(lp.Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.Velocity = Vector3.new()
					part.RotVelocity = Vector3.new()
				end
			end
			pcall(function() ws.FallenPartsDestroyHeight = old_fdh end)
		end
		getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
	end

	local tp_on = false
	local tp_tool = nil
	local tp_act_conn = nil
	local tp_add_conn = nil

	local function give_tp_tool()
		if not tp_on then return end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if not bp then return end
		local existing = bp:FindFirstChild("tp")
		if not existing and lp.Character then existing = lp.Character:FindFirstChild("tp") end
		if existing then
			tp_tool = existing
			return
		end
		if tp_act_conn then pcall(function() tp_act_conn:Disconnect() end) tp_act_conn = nil end
		tp_tool = Instance.new("Tool")
		tp_tool.Name = "tp"
		tp_tool.RequiresHandle = false
		tp_tool.CanBeDropped = false
		tp_tool.Parent = bp
		tp_act_conn = tp_tool.Activated:Connect(function()
			local root = my_hrp()
			local m = lp:GetMouse()
			local pos = m.Hit
			if not root or not pos then return end
			tp_root(CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components())))
			break_velocity()
		end)
	end

	local function remove_tp_tool()
		if tp_act_conn then pcall(function() tp_act_conn:Disconnect() end) tp_act_conn = nil end
		if tp_tool then pcall(function() tp_tool:Destroy() end) tp_tool = nil end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then local t = bp:FindFirstChild("tp") if t then pcall(function() t:Destroy() end) end end
		local c = lp.Character
		if c then local t = c:FindFirstChild("tp") if t then pcall(function() t:Destroy() end) end end
	end


	local fling_on = false
	local fling_tool = nil
	local fling_act_conn = nil
	local fling_add_conn = nil
	local fling_tool_bypass_velocity = false

	local function clicked_player()
		local m = lp:GetMouse()
		local target = m.Target
		if target then
			local node = target
			while node and node ~= ws do
				local p = players:GetPlayerFromCharacter(node)
				if p and p ~= lp then return p end
				node = node.Parent
			end
		end
		local cam = ws.CurrentCamera
		local mp = Vector2.new(m.X, m.Y)
		local best, bestd = nil, 110
		for _, p in ipairs(players:GetPlayers()) do
			if p ~= lp and p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head")
				if hrp then
					local sp, on = cam:WorldToViewportPoint(hrp.Position)
					if on then
						local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
						if d < bestd then bestd = d best = p end
					end
				end
			end
		end
		return best
	end

	local function give_fling_tool()
		if not fling_on then return end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if not bp then return end
		local existing = bp:FindFirstChild("fling")
		if not existing and lp.Character then existing = lp.Character:FindFirstChild("fling") end
		if existing then
			fling_tool = existing
			return
		end
		if fling_act_conn then pcall(function() fling_act_conn:Disconnect() end) fling_act_conn = nil end
		fling_tool = Instance.new("Tool")
		fling_tool.Name = "fling"
		fling_tool.RequiresHandle = false
		fling_tool.CanBeDropped = false
		fling_tool.Parent = bp
		fling_act_conn = fling_tool.Activated:Connect(function()
			local tp = clicked_player()
			if tp and my_hrp() then
				do_fling(tp)
			end
		end)
	end

	local function remove_fling_tool()
		if fling_act_conn then pcall(function() fling_act_conn:Disconnect() end) fling_act_conn = nil end
		if fling_tool then pcall(function() fling_tool:Destroy() end) fling_tool = nil end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then local t = bp:FindFirstChild("fling") if t then pcall(function() t:Destroy() end) end end
		local c = lp.Character
		if c then local t = c:FindFirstChild("fling") if t then pcall(function() t:Destroy() end) end end
	end


	local function in_lobby(obj)
		local p = obj.Parent
		while p and p ~= ws do
			if p.Name == "RegularLobby" or p.Name == "Lobby" then return true end
			p = p.Parent
		end
		return false
	end

	local function stable_tp(cf)
		tp_root(cf)
		if getgenv().FAKE_POS_ACTIVE then return end
		task.spawn(function()
			local hrp = my_hrp()
			if not hrp then return end
			local t = os.clock()
			while os.clock() - t < 0.25 and hrp.Parent do
				pcall(function()
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end)
				task.wait()
			end
		end)
	end

	local function teleport_to_map()
		local root = my_hrp()
		if not root then return end
		local spawnParts = {}
		for _, obj in ipairs(ws:GetDescendants()) do
			if (obj:IsA("SpawnLocation") or (obj:IsA("BasePart") and obj.Name == "Spawn")) and not in_lobby(obj) then
				spawnParts[#spawnParts + 1] = obj
			end
		end
		if #spawnParts > 0 then
			local rspawn = spawnParts[math.random(1, #spawnParts)]
			stable_tp(rspawn.CFrame + Vector3.new(0, 5, 0))
		end
	end

	local function teleport_to_lobby()
		local root = my_hrp()
		if not root then return end
		local lobby = ws:FindFirstChild("RegularLobby") or ws:FindFirstChild("Lobby")
		if not lobby then return end
		local locs = {}
		for _, obj in ipairs(lobby:GetDescendants()) do
			if obj:IsA("SpawnLocation") or (obj:IsA("BasePart") and obj.Name == "Spawn") then
				locs[#locs + 1] = obj
			end
		end
		if #locs > 0 then
			local rspawn = locs[math.random(1, #locs)]
			stable_tp(rspawn.CFrame + Vector3.new(0, 3, 0))
		else
			local ok, pivot = pcall(function() return lobby:GetPivot() end)
			if ok then stable_tp(pivot + Vector3.new(0, 5, 0)) end
		end
	end


	getgenv().MISC_TOOLS_UNLOAD = function()
		tp_on, fling_on = false, false
		if tp_add_conn then pcall(function() tp_add_conn:Disconnect() end) tp_add_conn = nil end
		if fling_add_conn then pcall(function() fling_add_conn:Disconnect() end) fling_add_conn = nil end
		remove_tp_tool()
		remove_fling_tool()
	end
	getgenv().TT = {
		setTpTool = function(v)
			tp_on = v
			if v then
				give_tp_tool()
				if not tp_add_conn then
					tp_add_conn = lp.CharacterAdded:Connect(function()
						task.wait(0.5)
						if tp_on then give_tp_tool() end
					end)
				end
			else
				if tp_add_conn then pcall(function() tp_add_conn:Disconnect() end) tp_add_conn = nil end
				remove_tp_tool()
			end
		end,
		setFlingTool = function(v)
			fling_on = v
			if v then
				give_fling_tool()
				if not fling_add_conn then
					fling_add_conn = lp.CharacterAdded:Connect(function()
						task.wait(0.5)
						if fling_on then give_fling_tool() end
					end)
				end
			else
				if fling_add_conn then pcall(function() fling_add_conn:Disconnect() end) fling_add_conn = nil end
				remove_fling_tool()
			end
		end,
		setBypassVel = function(v) fling_tool_bypass_velocity = v end,
		goLobby = function() teleport_to_lobby() end,
		goMap = function() teleport_to_map() end,
		unload = getgenv().MISC_TOOLS_UNLOAD,
	}
end
initTools()

------------------------------ NOTIFY ENGINE ------------------------------
function initNotify()
	local players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local lp = players.LocalPlayer

	local notify_on = false
	local miss_on, kill_on, roles_on = false, false, false

	local ICON_MISS = "rbxassetid://74115333842618"
	local ICON_KILL = "rbxassetid://86817768619372"
	local ICON_ROLE = "rbxassetid://84691420588185"

	local last_role = nil
	local gun_conn = nil
	local hooked_gun = nil
	local cur_murderer_name = nil
	local killed_flag = false
	local last_miss = 0

	local notify_round_mod = nil

	local function notify_require_round()
		return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
	end

	local function get_data()
		if not notify_round_mod then
			local ok, m = pcall(notify_require_round)
			if not ok or type(m) ~= "table" then return nil end
			notify_round_mod = m
		end
		return notify_round_mod.PlayerData
	end

	local function lp_has_gun()
		local char = lp.Character
		if char and char:FindFirstChild("Gun") then return true end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp and bp:FindFirstChild("Gun") then return true end
		return false
	end

	local function my_role()
		local d = get_data()
		local me = d and d[lp.Name]
		local role = me and me.Role
		if role == "Sheriff" or role == "Hero" then return role end
		if lp_has_gun() then return "Hero" end
		return role
	end

	local function murderer_player()
		local d = get_data()
		if type(d) ~= "table" then return nil end
		for name, info in pairs(d) do
			if type(info) == "table" and info.Role == "Murderer" then
				return players:FindFirstChild(name)
			end
		end
		return nil
	end

	local function push(text, icon)
		pcall(function() toast(text, icon, 4) end)
	end

	task.spawn(function()
		while task.wait(0.4) do
			if not (notify_on and roles_on) then
				continue
			end
			local r = my_role()
			if r and r ~= last_role then
				last_role = r
				push("You are now "..tostring(r), ICON_ROLE)
			elseif not r then
				last_role = nil
			end
		end
	end)

	task.spawn(function()
		while task.wait(0.5) do
			if not notify_on then
				continue
			end
			local mp = murderer_player()
			local name = mp and mp.Name
			if name ~= cur_murderer_name then
				cur_murderer_name = name
				killed_flag = false
			end
		end
	end)

	local function on_shot()
		if not (notify_on and (miss_on or kill_on)) then return end
		local role = my_role()
		if role ~= "Sheriff" and role ~= "Hero" then return end
		local mp = murderer_player()
		if not mp then return end
		local mname = mp.Name
		task.delay(0.7, function()
			if not notify_on then return end
			local d = get_data()
			local info = d and d[mname]
			local target = players:FindFirstChild(mname)
			local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			local killed = (info and info.Dead == true) or (hum ~= nil and hum.Health <= 0)
			local alive = (info and info.Dead == false) or (hum ~= nil and hum.Health > 0)
			if killed then
				if kill_on and not killed_flag then
					killed_flag = true
					push("Killed @"..mname, ICON_KILL)
				end
			elseif alive then
				if miss_on and getgenv().SILENT_AIM_ACTIVE and os.clock() - last_miss > 1.5 then
					last_miss = os.clock()
					push("Missed shot due to @"..mname, ICON_MISS)
				end
			end
		end)
	end

	local function ensure_gun_hook()
		if gun_conn and hooked_gun then return end
		local ok, remote = pcall(function()
			return rs:WaitForChild("ClientServices"):WaitForChild("WeaponService"):WaitForChild("GunFired")
		end)
		if not ok or not remote then return end
		if gun_conn then pcall(function() gun_conn:Disconnect() end) gun_conn = nil end
		hooked_gun = remote
		gun_conn = remote.OnClientEvent:Connect(function(gun)
			local char = lp.Character
			if typeof(gun) == "Instance" and char and gun:IsDescendantOf(char) then
				on_shot()
			end
		end)
	end

	task.spawn(function()
		while true do
			if notify_on and (miss_on or kill_on) then
				ensure_gun_hook()
			end
			task.wait(0.4)
		end
	end)

	getgenv().NOTIFY_UNLOAD = function()
		notify_on, miss_on, kill_on, roles_on = false, false, false, false
		if gun_conn then pcall(function() gun_conn:Disconnect() end) gun_conn = nil end
		hooked_gun = nil
	end
	getgenv().NT = {
		setOn = function(v)
			notify_on = v
			if v and (miss_on or kill_on) then task.spawn(ensure_gun_hook) end
		end,
		setMiss = function(v)
			miss_on = v
			if v and notify_on then task.spawn(ensure_gun_hook) end
		end,
		setKillM = function(v)
			kill_on = v
			if v and notify_on then task.spawn(ensure_gun_hook) end
		end,
		setRoles = function(v) roles_on = v end,
		unload = getgenv().NOTIFY_UNLOAD,
	}
end
initNotify()

------------------------------ SOUNDS ENGINE ------------------------------
function initSounds()
	local players = game:GetService("Players")
	local sound_service = game:GetService("SoundService")
	local lp = players.LocalPlayer

	local snd_cfg = {
		sheriff = { on = false, name = "mc bow", volume = 1 },
		murder = { on = false, name = "skeet", volume = 1 }
	}

	local SND_REMOTE_LIST = { "primordial", "neverlose", "sparkle", "mc bow", "skeet", "break", "rust" }
	local SND_LOCAL_LIST = { "applepay", "bubble", "combobreak", "killcard", "xp", "na naxuy", "stony", "hentai" }
	local SND_FILES = { hentai = "hentai1" }
	local SND_CACHE_DIR = "shitaro_sounds/"
	local SND_USER_DIR = "sounds/"
	local SND_USER_EXTS = { [".ogg"] = true, [".mp3"] = true, [".wav"] = true }
	local SND_DIRS = { "shitaroebet/", "assets/", "khen_juju/assets/", "khen_juju/custom/", SND_USER_DIR, "", SND_CACHE_DIR }
	local SND_EXTS = { ".ogg", ".mp3", ".wav", "" }
	local SND_BASE_URL = "https://github.com/khenn791/lmao/raw/refs/heads/main/"

	local SND_LIST = {}
	local snd_remote = {}

	for _, snd_name in ipairs(SND_REMOTE_LIST) do
		SND_LIST[#SND_LIST + 1] = snd_name
		snd_remote[snd_name] = true
	end

	for _, snd_name in ipairs(SND_LOCAL_LIST) do
		SND_LIST[#SND_LIST + 1] = snd_name
	end

	local SND_BASE_COUNT = #SND_LIST

	local snd_user = {}
	local snd_user_sig = nil
	local snd_drops = {}

	local snd_cache = {}
	local snd_source = {}
	local snd_fetched = {}
	local snd_warned = {}
	local snd_hooked = {}
	local snd_pool = {}
	local snd_tmp = {}
	local snd_alive = true
	local snd_last = { sheriff = 0, murder = 0 }

	local function snd_fs_ready()
		return type(isfile) == "function" and type(readfile) == "function"
			and type(writefile) == "function" and type(getcustomasset) == "function"
	end

	local function snd_load_path(path)
		local ok_is, has = pcall(isfile, path)
		if not (ok_is and has) then return nil end

		local ok_rd, data = pcall(readfile, path)
		if not (ok_rd and type(data) == "string" and #data > 0) then return nil end

		local ext = string.match(path, "(%.[^%./\\]+)$")
		local suffix = ext and string.lower(ext) or ".ogg"
		if not SND_USER_EXTS[suffix] then suffix = ".ogg" end

		local tmp = "shitaro_snd_" .. tostring(math.random(100000, 999999)) .. suffix
		if not pcall(writefile, tmp, data) then return nil end

		local ok_as, asset = pcall(getcustomasset, tmp)
		if not (ok_as and type(asset) == "string" and asset ~= "") then
			pcall(function() if type(delfile) == "function" then delfile(tmp) end end)
			return nil
		end

		local settle = getgenv().shitaro_volatile
		if type(settle) == "function" then
			local ok_v, res = pcall(settle, tmp, asset, "sound")
			if ok_v and type(res) == "string" and res ~= "" then
				asset = res
			end
		else
			snd_tmp[#snd_tmp + 1] = tmp
		end

		return asset
	end

	local function snd_scan(name)
		local direct = snd_user[name]
		if direct then
			local asset = snd_load_path(direct)
			if asset then return asset, direct end
		end

		local file = SND_FILES[name] or name
		for _, dir in ipairs(SND_DIRS) do
			for _, ext in ipairs(SND_EXTS) do
				local path = dir .. file .. ext
				local asset = snd_load_path(path)
				if asset then return asset, path end
			end
		end

		return nil, nil
	end

	local function snd_user_dir_ready()
		if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return false end

		local ok, has = pcall(isfolder, SND_USER_DIR)
		if not ok then return false end
		if has then return true end

		return pcall(makefolder, SND_USER_DIR) == true
	end

	local function snd_user_collect()
		local out = {}
		if type(listfiles) ~= "function" then return out end
		if not snd_user_dir_ready() then return out end

		local ok, rows = pcall(listfiles, SND_USER_DIR)
		if not ok or type(rows) ~= "table" then return out end

		local seen = {}
		for _, entry in ipairs(rows) do
			if type(entry) == "string" then
				local path = string.gsub(entry, "\\", "/")
				local stem, ext = string.match(path, "([^/]+)(%.[^%./]+)$")
				if stem and ext and SND_USER_EXTS[string.lower(ext)] and not seen[stem] then
					seen[stem] = true
					out[#out + 1] = { name = stem, path = path }
				end
			end
		end

		table.sort(out, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
		return out
	end

	local function snd_drop_sync(drop)
		if not drop then return end
		pcall(function()
			local cur = drop:GetValue()
			drop:SetValues(SND_LIST)
			drop:Generate()
			if type(cur) == "table" then cur = cur[1] end
			if type(cur) == "string" and cur ~= "" and drop:GetValue() ~= cur then
				for i = 1, #SND_LIST do
					if SND_LIST[i] == cur then
						drop:SetValue(cur)
						break
					end
				end
			end
		end)
	end

	local function snd_user_publish()
		local rows = snd_user_collect()
		local names = {}
		for i = 1, #rows do names[i] = rows[i].name end

		local sig = table.concat(names, "|")
		if sig == snd_user_sig then return end
		snd_user_sig = sig

		for old in pairs(snd_user) do
			snd_cache[old] = nil
			snd_warned[old] = nil
		end

		table.clear(snd_user)
		for i = 1, #rows do
			snd_user[rows[i].name] = rows[i].path
			snd_cache[rows[i].name] = nil
			snd_warned[rows[i].name] = nil
		end

		for i = #SND_LIST, SND_BASE_COUNT + 1, -1 do
			SND_LIST[i] = nil
		end

		local taken = {}
		for i = 1, SND_BASE_COUNT do taken[SND_LIST[i]] = true end
		for i = 1, #names do
			if not taken[names[i]] then
				taken[names[i]] = true
				SND_LIST[#SND_LIST + 1] = names[i]
			end
		end

		snd_drop_sync(snd_drops.sheriff)
		snd_drop_sync(snd_drops.murder)
	end

	local function snd_pull(name)
		local grab = getgenv().shitaro_asset

		if type(grab) ~= "function" then
			return nil
		end

		local file = SND_FILES[name] or name
		local names = getgenv().shitaro_assetlist

		if type(names) == "function" then
			local ok, rows = pcall(names, "")

			if ok and type(rows) == "table" then
				for _, entry in ipairs(rows) do
					local stem, ext = string.match(entry, "^([^/]+)(%.[^%.]+)$")

					if stem == file and (ext == ".mp3" or ext == ".wav" or ext == ".ogg") then
						local id = grab(entry)

						if id then
							return id
						end
					end
				end
			end

			return nil
		end

		for _, ext in ipairs({ ".mp3", ".wav", ".ogg" }) do
			local id = grab(file .. ext)

			if id then
				return id
			end
		end

		return nil
	end

	local function snd_download(name)
		if snd_fetched[name] ~= nil then
			return snd_fetched[name]
		end
		if not snd_remote[name] then
			snd_fetched[name] = false
			return false
		end
		local path = SND_CACHE_DIR .. name .. ".ogg"
		local ok_is, has = pcall(isfile, path)
		if ok_is and has then
			snd_fetched[name] = true
			return true
		end
		if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
			snd_fetched[name] = false
			return false
		end
		local ok_dir = pcall(function()
			if not isfolder(SND_CACHE_DIR) then
				makefolder(SND_CACHE_DIR)
			end
		end)
		if not ok_dir then
			snd_fetched[name] = false
			return false
		end
		local url = SND_BASE_URL .. (string.gsub(name, " ", "%%20")) .. ".ogg"
		local ok_dl, data = pcall(function()
			return game:HttpGet(url)
		end)
		if not ok_dl or type(data) ~= "string" or #data < 1024 then
			snd_fetched[name] = false
			return false
		end
		local ok_wr = pcall(writefile, path, data)
		snd_fetched[name] = ok_wr == true
		return snd_fetched[name]
	end

	local function snd_resolve(name)
		local cached = snd_cache[name]
		if cached ~= nil then
			if cached == false then return nil end
			return cached
		end
		if not snd_fs_ready() then
			snd_cache[name] = false
			return nil
		end
		local found, found_path = snd_scan(name)
		if not found then
			found = snd_pull(name)
			if found then
				found_path = name
			end
		end
		if not found and snd_download(name) then
			found, found_path = snd_scan(name)
		end
		snd_cache[name] = found or false
		snd_source[name] = found_path
		if not found and not snd_warned[name] then
			snd_warned[name] = true
			if event_notify then
				pcall(function()
					event_notify:Notify({ Title = "Sound file '" .. name .. "' not found", Icon = "clipboard", Duration = 5 })
				end)
			end
		end
		return found
	end

	local function snd_template(kind)
		local cfg = snd_cfg[kind]
		if not cfg then return nil end
		local id = snd_resolve(cfg.name)
		if not id then
			local old = snd_pool[kind]
			if old then
				pcall(function() old:Destroy() end)
				snd_pool[kind] = nil
			end
			return nil
		end
		local cur = snd_pool[kind]
		if cur and cur.Parent and cur.SoundId == id then
			pcall(function() cur.Volume = cfg.volume end)
			return cur
		end
		if cur then pcall(function() cur:Destroy() end) end
		local ok, s = pcall(function()
			local snd = Instance.new("Sound")
			snd.Name = "\0"
			snd.SoundId = id
			snd.Volume = cfg.volume
			snd.Looped = false
			snd.Parent = sound_service
			return snd
		end)
		if not ok or not s then
			snd_pool[kind] = nil
			return nil
		end
		snd_pool[kind] = s
		task.spawn(function()
			pcall(function() game:GetService("ContentProvider"):PreloadAsync({ s }) end)
		end)
		return s
	end

	local function snd_play(kind)
		local template = snd_pool[kind] or snd_template(kind)
		if not template then return false end
		local ok = pcall(function()
			local c = template:Clone()
			c.Volume = snd_cfg[kind].volume
			c.Looped = false
			c.PlayOnRemove = false
			c.TimePosition = 0
			c.Parent = sound_service
			c:Play()
			task.delay(0.3, function()
				if not c.Parent then return end
				if c.IsPlaying or c.TimePosition > 0 then return end
				pcall(function()
					c.PlayOnRemove = true
					c:Destroy()
				end)
			end)
			task.delay(8, function() pcall(function() c:Destroy() end) end)
		end)
		return ok
	end

	local function snd_kind_active(kind)
		local cfg = snd_cfg[kind]
		return cfg ~= nil and cfg.on
	end

	local function snd_any_active()
		return snd_cfg.sheriff.on or snd_cfg.murder.on
	end

	local function snd_should_mute(kind)
		local cfg = snd_cfg[kind]
		if not cfg or not cfg.on then return false end
		return snd_template(kind) ~= nil
	end

	local function snd_refresh()
		local mute = { sheriff = snd_should_mute("sheriff"), murder = snd_should_mute("murder") }
		for inst, entry in pairs(snd_hooked) do
			if inst.Parent then
				pcall(function()
					inst.Volume = mute[entry.kind] and 0 or entry.vol
				end)
			end
		end
	end

	local function snd_hook(inst, kind)
		if snd_hooked[inst] then return end
		local entry = { kind = kind, vol = inst.Volume, conns = {} }
		snd_hooked[inst] = entry

		local function fire()
			if not snd_kind_active(kind) then return end
			if not snd_pool[kind] and not snd_template(kind) then return end
			if os.clock() - snd_last[kind] < 0.15 then return end
			snd_last[kind] = os.clock()
			pcall(function() inst:Stop() end)
			snd_play(kind)
		end

		entry.conns[#entry.conns + 1] = inst.Played:Connect(fire)
		entry.conns[#entry.conns + 1] = inst:GetPropertyChangedSignal("Playing"):Connect(function()
			if inst.Playing then fire() end
		end)
		entry.conns[#entry.conns + 1] = inst.Destroying:Connect(function()
			snd_hooked[inst] = nil
		end)

		pcall(function()
			inst.Volume = snd_should_mute(kind) and 0 or entry.vol
		end)

		if inst.Playing or inst.IsPlaying then
			fire()
		end
	end

	local function snd_tool_kind(tool)
		if tool:FindFirstChild("GunClient") or tool:FindFirstChild("Shoot") or tool.Name == "Gun" then
			return "sheriff"
		end
		if tool:FindFirstChild("KnifeClient") or tool:FindFirstChild("Events") or tool.Name == "Knife" then
			return "murder"
		end
		return nil
	end

	local snd_watch_conns = {}
	local snd_watched_char = nil
	local snd_watched_bp = nil

	local function snd_consider(inst)
		if not inst:IsA("Sound") then return end
		if inst.Name ~= "GunKill" and inst.Name ~= "Kill" then return end
		local handle = inst.Parent
		if not handle or handle.Name ~= "Handle" then return end
		local tool = handle.Parent
		if not tool or not tool:IsA("Tool") then return end
		local kind = snd_tool_kind(tool)
		if kind then snd_hook(inst, kind) end
	end

	local function snd_clear_watch()
		for i = #snd_watch_conns, 1, -1 do
			pcall(function() snd_watch_conns[i]:Disconnect() end)
			snd_watch_conns[i] = nil
		end
		snd_watched_char, snd_watched_bp = nil, nil
	end

	local function snd_watch()
		local char = lp.Character
		local bp = lp:FindFirstChildOfClass("Backpack")
		if char == snd_watched_char and bp == snd_watched_bp then return end
		snd_clear_watch()
		snd_watched_char, snd_watched_bp = char, bp
		if char then
			snd_watch_conns[#snd_watch_conns + 1] = char.DescendantAdded:Connect(snd_consider)
		end
		if bp then
			snd_watch_conns[#snd_watch_conns + 1] = bp.DescendantAdded:Connect(snd_consider)
		end
	end

	local function snd_scan()
		snd_watch()
		local function scan(container)
			if not container then return end
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local kind = snd_tool_kind(tool)
					local handle = tool:FindFirstChild("Handle")
					if kind and handle then
						for _, child in ipairs(handle:GetChildren()) do
							if child:IsA("Sound") and (child.Name == "GunKill" or child.Name == "Kill") then
								snd_hook(child, kind)
							end
						end
					end
				end
			end
		end
		scan(lp.Character)
		scan(lp:FindFirstChildOfClass("Backpack"))
	end

	local function snd_unhook_all()
		for inst, entry in pairs(snd_hooked) do
			for i = 1, #entry.conns do
				pcall(function() entry.conns[i]:Disconnect() end)
			end
			if inst.Parent then
				pcall(function() inst.Volume = entry.vol end)
			end
		end
		table.clear(snd_hooked)
		for kind, s in pairs(snd_pool) do
			pcall(function() s:Destroy() end)
			snd_pool[kind] = nil
		end
		snd_clear_watch()
	end

	task.spawn(function()
		while snd_alive do
			task.wait(0.4)
			if snd_alive and snd_any_active() then
				pcall(snd_scan)
				pcall(snd_refresh)
			end
		end
	end)

	task.spawn(function()
		while snd_alive do
			if snd_user_dir_ready() then
				pcall(snd_user_publish)
			end
			task.wait(2)
		end
	end)

	local function snd_apply(kind, v)
		snd_cfg[kind].on = v
		if snd_any_active() then
			if v then pcall(snd_template, kind) end
			pcall(snd_scan)
			pcall(snd_refresh)
		else
			pcall(snd_unhook_all)
		end
	end

	local function snd_preview(name, volume)
		local id = snd_resolve(name)
		if not id then return end
		pcall(function()
			local snd = Instance.new("Sound")
			snd.SoundId = id
			snd.Volume = volume
			snd.Looped = false
			snd.Parent = sound_service
			snd:Play()
			task.delay(8, function() pcall(function() snd:Destroy() end) end)
		end)
	end

	local function snd_bulk_change()
		local sync = getgenv().UI_SYNC
		if not sync then return false end
		if os.clock() - sync.start < 3 then return true end
		return os.clock() - sync.stamp < 0.7 and sync.count >= 3
	end

	local snd_preview_token = 0

	local function snd_request_preview(name, volume)
		snd_preview_token = snd_preview_token + 1
		local token = snd_preview_token
		task.delay(0.3, function()
			if token ~= snd_preview_token then return end
			if not snd_alive then return end
			if snd_bulk_change() then return end
			snd_preview(name, volume)
		end)
	end

	local function snd_set_name(kind, v)
		if type(v) == "table" then v = v[1] end
		if type(v) ~= "string" or v == "" then return end
		snd_cfg[kind].name = v
		if snd_cfg[kind].on then pcall(snd_template, kind) end
		if snd_any_active() then pcall(snd_refresh) end
		snd_request_preview(v, snd_cfg[kind].volume)
	end

	local function snd_set_volume(kind, v)
		snd_cfg[kind].volume = v
		local s = snd_pool[kind]
		if s then pcall(function() s.Volume = v end) end
	end

	getgenv().SOUNDS_UNLOAD = function()
		snd_alive = false
		snd_cfg.sheriff.on = false
		snd_cfg.murder.on = false
		pcall(snd_unhook_all)
		if type(delfile) == "function" then
			for i = 1, #snd_tmp do
				pcall(delfile, snd_tmp[i])
			end
		end
		table.clear(snd_tmp)
		table.clear(snd_cache)
		table.clear(snd_warned)
		table.clear(snd_user)
		table.clear(snd_drops)
		snd_user_sig = nil
	end
	getgenv().SN = {
		apply = function(kind, v) snd_apply(kind, v) end,
		setName = function(kind, v) snd_set_name(kind, v) end,
		setVolume = function(kind, v) snd_set_volume(kind, v) end,
		names = function()
			local t = {}
			for i = 1, #SND_LIST do t[#t + 1] = SND_LIST[i] end
			if type(listfiles) == "function" then
				pcall(function()
					for _, e in ipairs(snd_user_collect()) do
						local f = false
						for _, n in ipairs(t) do if n == e.name then f = true break end end
						if not f then t[#t + 1] = e.name end
					end
				end)
			end
			return t
		end,
		unload = getgenv().SOUNDS_UNLOAD,
	}
end
initSounds()

------------------------------ FLINGROLES ENGINE ------------------------------
function initFlingRoles()
	local players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local ws = workspace
	local lp = players.LocalPlayer

	local fling_murder_on = false
	local fling_sheriff_on = false
	local fling_thread = nil
	local round_mod = nil
	local fling_roles_bypass_velocity = false

	local function my_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function get_data()
		if not round_mod then
			local ok, m = pcall(function()
				return require(rs:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
			end)
			if ok and type(m) == "table" then round_mod = m end
		end
		return round_mod and round_mod.PlayerData
	end

	local function role_player(role)
		local d = get_data()
		if type(d) ~= "table" then return nil end
		for name, info in pairs(d) do
			if type(info) == "table" and not info.Dead and (info.Role == role or (role == "Sheriff" and info.Role == "Hero")) then
				local p = players:FindFirstChild(name)
				if p and p ~= lp then return p end
			end
		end
		return nil
	end

	local function do_fling(tp)
		if not tp or not tp.Character then return end
		local hrp = my_hrp()
		local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if not hrp then return end
		local tc = tp.Character
		local thrp = tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Head")
		local th = tc:FindFirstChildOfClass("Humanoid")
		if not thrp then return end
		getgenv().FLING_ACTIVE = (getgenv().FLING_ACTIVE or 0) + 1
		if hrp.Velocity.Magnitude < 50 then
			getgenv().OldPos = hrp.CFrame
		end
		if th and th.Sit then
			getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
			return
		end
		local camera = ws.CurrentCamera
		local old_fdh = ws.FallenPartsDestroyHeight
		if thrp then
			camera.CameraSubject = thrp
		elseif th then
			camera.CameraSubject = th
		end
		pcall(function() ws.FallenPartsDestroyHeight = 0/0 end)
		local bv = Instance.new("BodyVelocity")
		bv.Parent = hrp
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		local se = hum and hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
		local tw = 2
		local tm = tick()
		local ang = 0
		repeat
			if hrp and th then
				local tv
				if fling_roles_bypass_velocity then
					tv = th.MoveDirection * th.WalkSpeed
				else
					tv = thrp.Velocity
				end
				if tv.Magnitude < 50 then
					ang = ang + 100
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection * tv.Magnitude / 1.25
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0) + th.MoveDirection
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(ang), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				else
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, -th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, 1.5, th.WalkSpeed)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
					hrp.CFrame = CFrame.new(thrp.Position) * CFrame.new(0, -1.5, 0)
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, 0)
					lp.Character:SetPrimaryPartCFrame(hrp.CFrame)
					hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
					hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
					task.wait()
				end
			end
		until tm + tw < tick() or not (fling_murder_on or fling_sheriff_on)
		if bv then bv:Destroy() end
		if hum and se ~= nil then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, se) end
		camera.CameraSubject = hum
		if getgenv().OldPos then
			repeat
				hrp.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
				lp.Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
				if hum then hum:ChangeState("GettingUp") end
				for _, part in pairs(lp.Character:GetChildren()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.new()
						part.RotVelocity = Vector3.new()
					end
				end
				task.wait()
			until (hrp.Position - getgenv().OldPos.p).Magnitude < 25
			pcall(function() ws.FallenPartsDestroyHeight = old_fdh end)
		end
		getgenv().FLING_ACTIVE = math.max(0, (getgenv().FLING_ACTIVE or 1) - 1)
	end

	local function start_loop()
		if fling_thread then return end
		fling_thread = task.spawn(function()
			while fling_murder_on or fling_sheriff_on do
				local target = nil
				if fling_murder_on then target = role_player("Murderer") end
				if not target and fling_sheriff_on then target = role_player("Sheriff") end
				if target and target.Character and my_hrp() then
					do_fling(target)
				else
					task.wait(0.3)
				end
				task.wait()
			end
			fling_thread = nil
		end)
	end


	getgenv().FLINGROLES_UNLOAD = function()
		fling_murder_on = false
		fling_sheriff_on = false
	end
	getgenv().FR = {
		setMurder = function(v)
			fling_murder_on = v
			if v then start_loop() end
		end,
		setSheriff = function(v)
			fling_sheriff_on = v
			if v then start_loop() end
		end,
		setBypass = function(v) fling_roles_bypass_velocity = v end,
		unload = getgenv().FLINGROLES_UNLOAD,
	}
end
initFlingRoles()

------------------------------ MAPS ENGINE ------------------------------
function initMaps()
	local players = game:GetService("Players")
	local run = game:GetService("RunService")
	local lp = players.LocalPlayer

	local vaultName = string.char(109, 97, 112, 115, 46, 98, 105, 110)

	local map_defs, map_rows, picked = {}, {}, {}
	local pads, pad_conns = {}, {}
	local root, lobby_conn, ws_conn = nil, nil, nil
	local hold_conn, tally_conn, spawn_conn = nil, nil, nil
	local vote_on, dupe_on, alive = false, false, true
	local dupe_cap, dupe_used = 3, 0
	local grid, spot, mark = nil, nil, 0
	local session, running, pending = 0, false, false
	local origin = nil

	local function sort_rows()
		table.sort(map_rows, function(a, b)
			return string.lower(a.name) < string.lower(b.name)
		end)
	end

	local function learn(name, image)
		if type(name) ~= "string" or name == "" or name == "MAP NAME" then return false end
		if type(image) ~= "string" or image == "" then return false end
		if map_defs[name] then return false end
		map_defs[name] = image
		map_rows[#map_rows + 1] = { name = name, label = name, image = image }
		return true
	end

	local function sync_picked()
		if not grid then return end
		local v = grid:GetValue()
		table.clear(picked)
		if type(v) == "table" then
			for _, name in ipairs(v) do
				if type(name) == "string" and name ~= "" then picked[name] = true end
			end
		elseif type(v) == "string" and v ~= "" then
			picked[v] = true
		end
	end


	local function tally_of(entry)
		return tonumber(string.match(entry.tally.Text, "%d+")) or 0
	end

	local function ready(entry)
		local name = entry.title.Text
		return entry.info.Enabled and name ~= "" and name ~= "MAP NAME"
	end

	local function window_open()
		for i = 1, #pads do
			if pads[i].info.Enabled then return true end
		end
		return false
	end

	local function drop_conns()
		for _, c in ipairs({ hold_conn, tally_conn, spawn_conn }) do
			if c then pcall(function() c:Disconnect() end) end
		end
		hold_conn, tally_conn, spawn_conn = nil, nil, nil
	end

	local function finish()
		drop_conns()
		running = false
		spot = nil
		dupe_used = 0
		origin = nil
	end

	local function stand_point(pad)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { lp.Character, root }

		local hit = workspace:Raycast(pad.Position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)
		local y = hit and (hit.Position.Y + 3.2) or pad.Position.Y

		return Vector3.new(pad.Position.X, y, pad.Position.Z)
	end

	local function plant(point)
		local char = lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		hrp.CFrame = CFrame.new(point)
		return true
	end

	local function kill_self()
		local char = lp.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Dead)
			pcall(function() hum.Health = 0 end)
		elseif char then
			pcall(function() char:BreakJoints() end)
		end
	end

	local function choices()
		local out = {}
		for i = 1, #pads do
			local entry = pads[i]
			if ready(entry) and picked[entry.title.Text] then out[#out + 1] = entry end
		end
		return out
	end

	local function begin(id)
		local list = choices()
		if #list == 0 then
			finish()
			return
		end

		local entry = list[math.random(1, #list)]
		spot = stand_point(entry.pad)
		dupe_used = 0
		mark = tally_of(entry)

		local char = lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then finish() return end

		origin = hrp.CFrame

		if not plant(spot) then
			finish()
			return
		end

		if not dupe_on then
			task.delay(0.15, function()
				if session ~= id then return end
				local c2 = lp.Character
				local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
				if h2 then
					local hum = c2:FindFirstChildWhichIsA("Humanoid")
					if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
					h2.CFrame = origin
					task.delay(0.05, function()
						local c3 = lp.Character
						local h3 = c3 and c3:FindFirstChildWhichIsA("Humanoid")
						if h3 then pcall(function() h3:ChangeState(Enum.HumanoidStateType.Running) end) end
					end)
				end
				finish()
			end)
			return
		end

		hold_conn = run.Heartbeat:Connect(function()
			if not alive or session ~= id or not spot then return end
			local c2 = lp.Character
			local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
			if not h2 then return end
			local flat = Vector3.new(h2.Position.X - spot.X, 0, h2.Position.Z - spot.Z)
			if flat.Magnitude > 2.5 then h2.CFrame = CFrame.new(spot) end
		end)

		tally_conn = entry.tally:GetPropertyChangedSignal("Text"):Connect(function()
			if session ~= id or not dupe_on or not entry.info.Enabled then return end
			local now = tally_of(entry)
			if now <= mark then
				mark = now
				return
			end
			mark = now
			if dupe_used >= dupe_cap then
				drop_conns()
				task.defer(function()
					if session ~= id then return end
					local c2 = lp.Character
					local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
					if h2 and origin then
						local hum = c2:FindFirstChildWhichIsA("Humanoid")
						if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
						h2.CFrame = origin
						task.delay(0.05, function()
							local c3 = lp.Character
							local h3 = c3 and c3:FindFirstChildWhichIsA("Humanoid")
							if h3 then pcall(function() h3:ChangeState(Enum.HumanoidStateType.Running) end) end
						end)
					end
					finish()
				end)
				return
			end
			dupe_used = dupe_used + 1
			kill_self()
		end)

		spawn_conn = lp.CharacterAdded:Connect(function(char)
			if session ~= id or not dupe_on then return end
			local h2 = char:WaitForChild("HumanoidRootPart", 6)
			if not h2 or session ~= id or not entry.info.Enabled or not spot then return end
			if dupe_used >= dupe_cap then
				if origin then
					local hum = char:FindFirstChildWhichIsA("Humanoid")
					if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
					h2.CFrame = origin
					task.delay(0.05, function()
						local c3 = lp.Character
						local h3 = c3 and c3:FindFirstChildWhichIsA("Humanoid")
						if h3 then pcall(function() h3:ChangeState(Enum.HumanoidStateType.Running) end) end
					end)
				end
				return
			end
			h2.CFrame = CFrame.new(spot)
		end)
	end

	local function settle()
		pending = false
		if not alive then return end

		local grew = false
		for i = 1, #pads do
			local entry = pads[i]
			if entry.info.Enabled and learn(entry.title.Text, entry.icon.Image) then grew = true end
		end

		if grew then
			sort_rows()
			if grid then pcall(function() grid:SetData(map_rows) end) end
			sync_picked()
		end

		if not window_open() then
			if running then finish() end
			return
		end

		if not vote_on or running then return end

		running = true
		session = session + 1
		begin(session)
	end

	local function schedule()
		if pending or not alive then return end
		pending = true
		task.delay(0.25, settle)
	end

	local function shape(model)
		local pad = model:FindFirstChild("Pad")
		local info = model:FindFirstChild("MapInfoGui")
		local vote = model:FindFirstChild("VoteInfoGui")
		local icon = info and info:FindFirstChild("MapIcon")
		local box = vote and vote:FindFirstChild("Container")
		local title = box and box:FindFirstChild("MapName")
		local tally = box and box:FindFirstChild("Votes")

		if not (pad and info and icon and title and tally) then return nil end

		return { pad = pad, info = info, icon = icon, title = title, tally = tally }
	end

	local function bind(model_root)
		for _, c in ipairs(pad_conns) do pcall(function() c:Disconnect() end) end
		table.clear(pad_conns)
		table.clear(pads)

		root = model_root
		if not root then return end

		for _, model in ipairs(root:GetChildren()) do
			local entry = shape(model)
			if entry then
				pads[#pads + 1] = entry
				pad_conns[#pad_conns + 1] = entry.info:GetPropertyChangedSignal("Enabled"):Connect(schedule)
				pad_conns[#pad_conns + 1] = entry.title:GetPropertyChangedSignal("Text"):Connect(schedule)
				pad_conns[#pad_conns + 1] = entry.icon:GetPropertyChangedSignal("Image"):Connect(schedule)
			end
		end

		schedule()
	end

	local function watch_lobby(lobby)
		if lobby_conn then
			pcall(function() lobby_conn:Disconnect() end)
			lobby_conn = nil
		end

		if not lobby then
			bind(nil)
			return
		end

		lobby_conn = lobby.ChildAdded:Connect(function(child)
			if child.Name == "VotePads" then
				task.defer(function() bind(child) end)
			end
		end)

		bind(lobby:FindFirstChild("VotePads"))
	end

	watch_lobby(workspace:FindFirstChild("SummerLobby"))

	ws_conn = workspace.ChildAdded:Connect(function(child)
		if child.Name == "Lobby" then
			task.defer(function() watch_lobby(child) end)
		end
	end)


	getgenv().MAPVOTE_UNLOAD = function()
		alive = false
		vote_on, dupe_on = false, false
		finish()

		for _, c in ipairs(pad_conns) do pcall(function() c:Disconnect() end) end
		table.clear(pad_conns)
		table.clear(pads)

		for _, c in ipairs({ lobby_conn, ws_conn }) do
			if c then pcall(function() c:Disconnect() end) end
		end

		lobby_conn, ws_conn, root = nil, nil, nil
	end
	getgenv().MP = {
		setAuto = function(v)
			vote_on = v
			if v then schedule() else finish() end
		end,
		setDupe = function(v)
			dupe_on = v
			if not v then
				for _, c in ipairs({ tally_conn, spawn_conn }) do
					if c then pcall(function() c:Disconnect() end) end
				end
				tally_conn, spawn_conn = nil, nil
			end
		end,
		setCount = function(v) dupe_cap = math.clamp(math.floor(tonumber(v) or 3), 1, 10) end,
		rows = function() return map_rows end,
		picked = function()
			local t = {}
			for name in pairs(picked) do t[#t + 1] = name end
			return t
		end,
		setPicked = function(names)
			table.clear(picked)
			if type(names) == "table" then
				for _, name in ipairs(names) do
					if type(name) == "string" and name ~= "" then picked[name] = true end
				end
			elseif type(names) == "string" and names ~= "" then
				picked[names] = true
			end
		end,
		setGrid = function(g) grid = g end,
		unload = getgenv().MAPVOTE_UNLOAD,
	}
end
initMaps()

------------------------------ SHOWVALUES ENGINE ------------------------------
function initSV()
	local players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local lp = players.LocalPlayer

	local show_on = false
	local conns = {}
	local gen = 0
	local sync = nil

	local env = getgenv()
	env.__SV_STORE = env.__SV_STORE or { pages = {}, items = {}, fails = {}, busy = {} }
	local store = env.__SV_STORE
	local prefetch_gen = 0
	local id_index = nil

	local BASE = "https://r.jina.ai/https://supremevalues.com/mm2/"
	local PAGES = {
		"godlies", "chromas", "ancients", "uniques", "vintages",
		"legendaries", "rares", "uncommons", "commons", "pets", "misc"
	}
	local RARITY_PAGE = {
		Common = "commons",
		Uncommon = "uncommons",
		Rare = "rares",
		Legendary = "legendaries",
		Godly = "godlies",
		Ancient = "ancients",
		Unique = "uniques",
		Classic = "vintages",
		Vintage = "vintages",
		Christmas = "misc",
		Halloween = "misc",
	}
	local SKIP = {
		"^Class %-", "^Range", "^Stability", "^Demand", "^Rarity", "^Change in Value",
		"^Inv%.", "^Value", "^Tier", "^Filter", "^Sort", "^Title:", "^URL Source",
		"^Published Time", "^Markdown Content", "^%*", "^!%[", "^%[", "^%-", "^Supreme",
		"^Trade your", "^The Supreme", "^Chance of"
	}

	local LOW = "<1"

	local function norm(s)
		return (string.gsub(string.lower(tostring(s)), "[^%w]", ""))
	end

	local function comma(n)
		local s = tostring(math.floor(n + 0.5))
		while true do
			local r
			s, r = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
			if r == 0 then break end
		end
		return s
	end

	local function skip_line(t)
		for _, p in ipairs(SKIP) do
			if string.match(t, p) then return true end
		end
		return string.find(t, "%]%(") ~= nil or #t > 44
	end

	local function parse_page(txt, slug)
		local out = {}
		local last = nil
		for line in string.gmatch(txt .. "\n", "([^\n]*)\n") do
			local t = string.match(line, "^%s*(.-)%s*$")
			if t ~= "" then
				local raw = string.match(t, "^Value %- %*%*(.-)%*%*")
				if raw then
					if last then
						local clean = string.gsub(raw, "[,%s]", "")
						local num = tonumber(clean)
						if not num and string.match(clean, "^x%d+T%d") then num = LOW end
						local key = norm(last)
						if num and key ~= "" then
							if out[key] == nil then out[key] = num end
							if slug == "chromas" then
								local cut = string.match(key, "^chroma(.+)") or string.match(key, "^c(.+)")
								if cut and cut ~= "" and out[cut] == nil then out[cut] = num end
							end
						end
					end
					last = nil
				elseif not skip_line(t) then
					last = t
				end
			end
		end
		return out
	end

	local function valid_body(s)
		if type(s) ~= "string" or #s < 512 then return false end
		if not string.find(s, "Markdown Content", 1, true) then return false end
		return true
	end

	local function http_get(url)
		local ok, res = pcall(function() return game:HttpGet(url, true) end)
		if ok and valid_body(res) then return res end
		local req = rawget(getfenv(), "request")
			or rawget(getfenv(), "http_request")
			or (syn and syn.request)
			or (http and http.request)
			or (fluxus and fluxus.request)
			or env.request
		if type(req) == "function" then
			local ok2, res2 = pcall(req, {
				Url = url,
				Method = "GET",
				Headers = { ["Accept"] = "text/plain", ["User-Agent"] = "Mozilla/5.0" }
			})
			if ok2 and type(res2) == "table" and valid_body(res2.Body) then return res2.Body end
		end
		return nil
	end

	local BACKOFF = { 2, 4, 6, 9 }
	local FAIL_COOLDOWN = 6

	local function get_page(slug)
		local cached = store.pages[slug]
		if cached then return cached end
		local waited = 0
		while store.busy[slug] do
			task.wait(0.2)
			waited = waited + 0.2
			if store.pages[slug] then return store.pages[slug] end
			if waited > 90 then
				store.busy[slug] = nil
				break
			end
		end
		if store.pages[slug] then return store.pages[slug] end
		local fail = store.fails[slug]
		if fail and os.clock() - fail < FAIL_COOLDOWN then return nil end
		store.busy[slug] = true
		local built = nil
		for attempt = 1, #BACKOFF + 1 do
			local txt = http_get(BASE .. slug)
			if txt then
				local ok, idx = pcall(parse_page, txt, slug)
				if ok and type(idx) == "table" and next(idx) ~= nil then
					built = idx
					break
				end
			end
			local nap = BACKOFF[attempt]
			if nap then task.wait(nap) end
		end
		store.busy[slug] = nil
		if built then
			store.pages[slug] = built
			store.fails[slug] = nil
			return built
		end
		store.fails[slug] = os.clock()
		return nil
	end

	local function item_keys(data)
		local base = norm(data.ItemName or data.Name or "")
		local keys, strict = {}, {}
		if base == "" then return keys, strict end
		local ty = data.ItemType and norm(tostring(data.ItemType)) or nil
		local yr = data.Year and norm(tostring(data.Year)) or nil
		local evo = data.EvoIndex and ("var" .. norm(tostring(data.EvoIndex))) or nil

		local seen = {}
		local function push(k, tight)
			if k == "" or seen[k] then return end
			seen[k] = true
			keys[#keys + 1] = k
			if tight then strict[#strict + 1] = k end
		end

		if evo then push(base .. evo, true) end
		if ty and yr then push(base .. ty .. yr, true) end
		if ty then push(base .. ty, true) end
		if yr then push(base .. yr, true) end
		push(base, false)
		return keys, strict
	end

	local function page_list(data, dtype)
		if dtype == "Pets" then return { "pets" } end
		if data.Chroma then return { "chromas" } end
		local p = RARITY_PAGE[data.Rarity or ""]
		if p then return { p } end
		return { "misc" }
	end

	local function match_index(idx, keys)
		for _, k in ipairs(keys) do
			local v = idx[k]
			if v ~= nil then return v end
		end
		return nil
	end

	local function resolve(dtype, id, data)
		local ck = tostring(dtype) .. "|" .. tostring(id) .. (data.Chroma and "|c" or "")
		local hit = store.items[ck]
		if hit ~= nil then return hit, true end

		local keys, strict = item_keys(data)
		if #keys == 0 then return false, true end

		local primary = page_list(data, dtype)
		local incomplete = false

		for _, slug in ipairs(primary) do
			local idx = get_page(slug)
			if idx then
				local v = match_index(idx, keys)
				if v ~= nil then
					store.items[ck] = v
					return v, true
				end
			else
				incomplete = true
			end
		end

		if #strict > 0 then
			for _, slug in ipairs(PAGES) do
				local skip = false
				for _, x in ipairs(primary) do
					if x == slug then skip = true break end
				end
				if not skip then
					local idx = store.pages[slug]
					if idx then
						local v = match_index(idx, strict)
						if v ~= nil then
							store.items[ck] = v
							return v, true
						end
					elseif not store.fails[slug] then
						incomplete = true
					end
				end
			end
		end

		if incomplete then return nil, false end
		store.items[ck] = false
		return false, true
	end

	local function prefetch()
		prefetch_gen = prefetch_gen + 1
		local my = prefetch_gen
		store.fails = {}
		task.spawn(function()
			for sweep = 1, 4 do
				local left = 0
				for _, slug in ipairs(PAGES) do
					if my ~= prefetch_gen or not show_on then return end
					if not store.pages[slug] then
						get_page(slug)
						if not store.pages[slug] then left = left + 1 end
						task.wait(0.4)
					end
				end
				if left == 0 then return end
				if my ~= prefetch_gen or not show_on then return end
				task.wait(sweep * 4)
			end
		end)
	end

	local function trade_root()
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		local gui = pg and pg:FindFirstChild("TradeGUI")
		local cont = gui and gui:FindFirstChild("Container")
		return cont and cont:FindFirstChild("Trade"), gui
	end

	local function make_label(parent, name, size, pos, anchor, maxtext, align)
		local l = parent:FindFirstChild(name)
		if l then
			l.AnchorPoint = anchor
			l.Position = pos
			l.Size = size
			l.TextXAlignment = align
			local c = l:FindFirstChildOfClass("UITextSizeConstraint")
			if c then c.MaxTextSize = maxtext end
			return l
		end
		l = Instance.new("TextLabel")
		l.Name = name
		l.AnchorPoint = anchor
		l.Position = pos
		l.Size = size
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = Color3.fromRGB(255, 216, 110)
		l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		l.TextStrokeTransparency = 0.15
		l.TextXAlignment = align
		l.TextScaled = true
		l.RichText = false
		l.ZIndex = 40
		l.Text = ""
		local con = Instance.new("UITextSizeConstraint")
		con.MaxTextSize = maxtext
		con.MinTextSize = 7
		con.Parent = l
		l.Parent = parent
		return l
	end

	local function total_label(offer)
		local l = make_label(offer, "SV_Total",
			UDim2.new(0.4, 0, 0, 22), UDim2.new(0.025, 0, 1, -137),
			Vector2.new(0, 1), 22, Enum.TextXAlignment.Left)

		local width = offer.AbsoluteSize.X
		local left = width * 0.025
		local title = offer:FindFirstChild("Title")
		if title and title.TextBounds.X > 4 then
			left = (title.AbsolutePosition.X - offer.AbsolutePosition.X) + title.TextBounds.X + 10
		end
		local limit = width - left - 8
		local user = offer:FindFirstChild("Username")
		if user and user.TextBounds.X > 4 then
			local edge = (user.AbsolutePosition.X - offer.AbsolutePosition.X) + user.AbsoluteSize.X - user.TextBounds.X
			limit = math.min(limit, edge - left - 8)
		end
		l.Position = UDim2.new(0, math.floor(left), 1, -137)
		l.Size = UDim2.new(0, math.max(60, math.floor(limit)), 0, 22)
		return l
	end

	local function card_label(card)
		local l = make_label(card, "SV_Value",
			UDim2.new(0.7, 0, 0.16, 0), UDim2.new(1, -6, 0, 4),
			Vector2.new(1, 0), 18, Enum.TextXAlignment.Right)

		local inner = card:FindFirstChild("Container")
		local amt = inner and inner:FindFirstChild("Amount")
		local stacked = amt and amt.Visible and string.match(amt.Text or "", "x%s*%d") ~= nil
		l.Position = UDim2.new(1, -6, 0, stacked and 32 or 4)
		return l
	end

	local function clear_side(offer)
		if not offer then return end
		local l = offer:FindFirstChild("SV_Total")
		if l then l.Visible = false end
		local cont = offer:FindFirstChild("Container")
		if not cont then return end
		for _, ch in ipairs(cont:GetChildren()) do
			local v = ch:FindFirstChild("SV_Value")
			if v then v.Visible = false end
		end
	end

	local function wipe_labels()
		local root = trade_root()
		if not root then return end
		for _, side in ipairs({ "YourOffer", "TheirOffer" }) do
			local offer = root:FindFirstChild(side)
			if offer then
				local l = offer:FindFirstChild("SV_Total")
				if l then l:Destroy() end
				local cont = offer:FindFirstChild("Container")
				if cont then
					for _, ch in ipairs(cont:GetChildren()) do
						local v = ch:FindFirstChild("SV_Value")
						if v then v:Destroy() end
					end
				end
			end
		end
	end

	local function ensure_sync()
		if sync then return sync end
		local ok, mod = pcall(function()
			return require(rs:WaitForChild("Database"):WaitForChild("Sync"))
		end)
		if ok and type(mod) == "table" then sync = mod end
		return sync
	end

	local function build_index()
		if id_index then return id_index end
		if not ensure_sync() then return nil end
		local byid, byname = {}, {}
		local function add(map, key, rec)
			if not key or key == "" then return end
			local bucket = map[key]
			if bucket then
				bucket[#bucket + 1] = rec
			else
				map[key] = { rec }
			end
		end
		for _, dtype in ipairs({ "Weapons", "Pets" }) do
			local db = sync[dtype]
			if type(db) == "table" then
				for id, d in pairs(db) do
					if type(d) == "table" then
						local rec = { dtype = dtype, id = id, data = d }
						if d.ItemID then add(byid, tostring(d.ItemID), rec) end
						if type(d.Image) == "string" then
							local dig = string.match(d.Image, "assetId=(%d+)")
								or string.match(d.Image, "id=(%d+)")
								or string.match(d.Image, "rbxassetid://(%d+)")
							if dig then add(byid, dig, rec) end
						end
						add(byname, tostring(d.ItemName or d.Name or ""), rec)
					end
				end
			end
		end
		id_index = { byid = byid, byname = byname }
		return id_index
	end

	local function icon_id(card)
		local inner = card:FindFirstChild("Container")
		local icon = inner and inner:FindFirstChild("Icon")
		local img = icon and icon.Image or ""
		if img == "" then return nil end
		return string.match(img, "assetId=(%d+)")
			or string.match(img, "id=(%d+)")
			or string.match(img, "rbxassetid://(%d+)")
	end

	local function card_entry(card, text, chroma)
		local ix = build_index()
		if not ix then return nil end
		local iid = icon_id(card)
		local pool = iid and ix.byid[iid] or nil
		if not pool then pool = ix.byname[text] end
		if not pool then return nil end

		local fallback = nil
		for _, rec in ipairs(pool) do
			local d = rec.data
			if (d.Chroma == true) == chroma then
				if tostring(d.ItemName or d.Name or "") == text then return rec.dtype, rec.id, d end
				if not fallback then fallback = rec end
			end
		end
		if fallback then return fallback.dtype, fallback.id, fallback.data end
		if iid and ix.byid[iid] == pool then
			local rec = pool[1]
			return rec.dtype, rec.id, rec.data
		end
		return nil
	end

	local function gui_items(offer)
		local out = {}
		local cont = offer and offer:FindFirstChild("Container")
		if not cont then return out end
		local i = 1
		while true do
			local card = cont:FindFirstChild("NewItem" .. i)
			if not card or not card.Visible then break end
			local nm = card:FindFirstChild("ItemName")
			local lbl = nm and nm:FindFirstChild("Label")
			local text = lbl and lbl.Text or ""
			if text == "" then break end
			local tags = card:FindFirstChild("Tags")
			local ch = tags and tags:FindFirstChild("Chroma")
			local inner = card:FindFirstChild("Container")
			local amt_l = inner and inner:FindFirstChild("Amount")
			local amt = amt_l and tonumber(string.match(amt_l.Text or "", "x%s*(%d+)")) or 1
			local chroma = ch ~= nil and ch.Visible == true
			local dtype, id, data = card_entry(card, text, chroma)
			out[i] = {
				id = id or norm(text),
				amount = amt,
				dtype = dtype or "Weapons",
				data = data or { ItemName = text, Chroma = chroma }
			}
			i = i + 1
		end
		return out
	end

	local function collect(offer_data)
		local out = {}
		if type(offer_data) ~= "table" then return out end
		ensure_sync()
		for i, v in ipairs(offer_data) do
			local id = v[1] or v.ItemID
			local amount = v[2] or v.Amount or 1
			local dtype = v[3] or v.ItemType
			local db = sync and dtype and sync[dtype]
			local data = db and db[id]
			out[i] = { id = id, amount = amount, dtype = dtype, data = data }
		end
		return out
	end

	local function render(offer, items, my_gen)
		if not offer then return end
		local cont = offer:FindFirstChild("Container")
		if not cont then return end
		clear_side(offer)
		local total = total_label(offer)
		if #items == 0 then
			total.Visible = false
			return
		end
		total.Visible = true
		total.Text = "..."
		for i in ipairs(items) do
			local card = cont:FindFirstChild("NewItem" .. i)
			if card then
				local l = card_label(card)
				l.Visible = true
				l.Text = "..."
			end
		end
		task.spawn(function()
			local done = {}
			local deadline = os.clock() + 150
			while true do
				local pending = false
				local sum = 0
				for i, it in ipairs(items) do
					if my_gen ~= gen or not show_on then return end
					if done[i] == nil then
						if it.data then
							local val, settled = resolve(it.dtype, it.id, it.data)
							if settled then done[i] = { v = val } else pending = true end
						else
							done[i] = { v = false }
						end
					end
					if my_gen ~= gen or not show_on then return end
					local card = cont:FindFirstChild("NewItem" .. i)
					local l = card and card:FindFirstChild("SV_Value")
					local rec = done[i]
					if rec then
						local val = rec.v
						local amt = tonumber(it.amount) or 1
						if type(val) == "number" then
							sum = sum + val * amt
							if l then l.Text = comma(val) end
						elseif val == LOW then
							if l then l.Text = LOW end
						elseif l then
							l.Text = "?"
						end
					elseif l then
						l.Text = "..."
					end
				end
				if total.Parent then
					total.Text = pending and (comma(sum) .. " ...") or comma(sum)
				end
				if not pending then return end
				if os.clock() > deadline then
					for i in ipairs(items) do
						if done[i] == nil then
							local card = cont:FindFirstChild("NewItem" .. i)
							local l = card and card:FindFirstChild("SV_Value")
							if l then l.Text = "?" end
						end
					end
					if total.Parent then total.Text = comma(sum) end
					return
				end
				task.wait(2)
			end
		end)
	end

	local function update(data)
		if not show_on or type(data) ~= "table" then return end
		local mine, theirs
		if data.Player1 and data.Player1.Player == lp then
			mine, theirs = data.Player1.Offer, data.Player2 and data.Player2.Offer
		elseif data.Player2 and data.Player2.Player == lp then
			mine, theirs = data.Player2.Offer, data.Player1 and data.Player1.Offer
		else
			return
		end
		gen = gen + 1
		local my_gen = gen
		local my_items, their_items = collect(mine), collect(theirs)
		task.delay(0.05, function()
			if my_gen ~= gen or not show_on then return end
			local root = trade_root()
			if not root then return end
			render(root:FindFirstChild("YourOffer"), my_items, my_gen)
			render(root:FindFirstChild("TheirOffer"), their_items, my_gen)
		end)
	end

	local function refresh_gui()
		if not show_on then return end
		local root, gui = trade_root()
		if not root or not gui or not gui.Enabled then return end
		gen = gen + 1
		local my_gen = gen
		local mine = root:FindFirstChild("YourOffer")
		local theirs = root:FindFirstChild("TheirOffer")
		render(mine, gui_items(mine), my_gen)
		render(theirs, gui_items(theirs), my_gen)
	end

	local function hook()
		local trade = rs:FindFirstChild("Trade")
		if not trade then return end
		local upd = trade:FindFirstChild("UpdateTrade")
		local start = trade:FindFirstChild("StartTrade")
		if upd then
			conns[#conns + 1] = upd.OnClientEvent:Connect(update)
		end
		if start then
			conns[#conns + 1] = start.OnClientEvent:Connect(function(data)
				update(data)
			end)
		end
		local _, gui = trade_root()
		if gui then
			conns[#conns + 1] = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not gui.Enabled then
					gen = gen + 1
					local root = trade_root()
					if root then
						clear_side(root:FindFirstChild("YourOffer"))
						clear_side(root:FindFirstChild("TheirOffer"))
					end
				end
			end)
		end
	end

	local function unhook()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		conns = {}
	end


	getgenv().SHOWVALUES_UNLOAD = function()
		show_on = false
		gen = gen + 1
		prefetch_gen = prefetch_gen + 1
		unhook()
		wipe_labels()
	end
	getgenv().SV = {
		setOn = function(v)
			show_on = v
			gen = gen + 1
			if v then
				unhook()
				hook()
				prefetch()
				refresh_gui()
			else
				prefetch_gen = prefetch_gen + 1
				unhook()
				wipe_labels()
			end
		end,
		unload = getgenv().SHOWVALUES_UNLOAD,
	}
end
initSV()

------------------------------ TOAST (native notify) ------------------------------
local toastGui, toastList = nil, nil
function toast(text, icon, dur)
	dur = dur or 4
	pcall(function()
		if not toastGui or not toastGui.Parent then
			toastGui = Instance.new("ScreenGui")
			toastGui.Name = "WorldToast"
			toastGui.ResetOnSpawn = false
			toastGui.IgnoreGuiInset = true
			toastGui.DisplayOrder = 600
			local ok, par = pcall(function() return gethui() end)
			if ok and typeof(par) == "Instance" then toastGui.Parent = par
			else
				pcall(function() toastGui.Parent = game:GetService("CoreGui") end)
				if not toastGui.Parent then toastGui.Parent = LP:FindFirstChildOfClass("PlayerGui") end
			end
			toastList = Instance.new("Frame")
			toastList.Position = UDim2.new(1, -250, 0, 40)
			toastList.Size = UDim2.new(0, 240, 0, 0)
			toastList.BackgroundTransparency = 1
			toastList.AutomaticSize = Enum.AutomaticSize.Y
			toastList.Parent = toastGui
			local ll = Instance.new("UIListLayout")
			ll.Padding = UDim.new(0, 6)
			ll.SortOrder = Enum.SortOrder.LayoutOrder
			ll.Parent = toastList
		end
		while #toastList:GetChildren() > 6 do
			local f = toastList:FindFirstChildOfClass("Frame")
			if f then f:Destroy() else break end
		end
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 40)
		f.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
		f.BorderSizePixel = 0
		f.Parent = toastList
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = f
		local ox = 8
		if type(icon) == "string" and #icon > 0 then
			local im = Instance.new("ImageLabel")
			im.Position = UDim2.new(0, 6, 0.5, -11)
			im.Size = UDim2.new(0, 22, 0, 22)
			im.BackgroundTransparency = 1
			im.Image = icon
			im.Parent = f
			ox = 32
		end
		local tx = Instance.new("TextLabel")
		tx.Position = UDim2.new(0, ox, 0, 0)
		tx.Size = UDim2.new(1, -ox - 4, 1, 0)
		tx.BackgroundTransparency = 1
		tx.Text = tostring(text or "")
		tx.Font = Enum.Font.Gotham
		tx.TextSize = 12
		tx.TextColor3 = Color3.fromRGB(235, 235, 240)
		tx.TextXAlignment = Enum.TextXAlignment.Left
		tx.TextTruncate = Enum.TextTruncate.AtEnd
		tx.Parent = f
		task.delay(dur, function()
			pcall(function() f:Destroy() end)
		end)
	end)
end
------------------------------ PREVIEW (native viewport) ------------------------------
local PV = { on = false, frame = nil, world = nil, cam = nil, timer = 0, conn = nil }
local function pvClear()
	if PV.world then pcall(function() PV.world:Destroy() end) end
	if PV.cam then pcall(function() PV.cam:Destroy() end) end
	PV.world, PV.cam = nil, nil
end
local function pvBuild()
	pvClear()
	if not PV.on then return end
	if not PV.frame or not PV.frame.Parent then return end
	local char = LP.Character
	if not char then return end
	local ok, clone = pcall(function() return char:Clone() end)
	if not ok or not clone then return end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Humanoid") then
			pcall(function() d:Destroy() end)
		end
	end
	local wm = Instance.new("WorldModel")
	wm.Parent = PV.frame
	PV.world = wm
	clone.Parent = wm
	local cam = Instance.new("Camera")
	cam.Parent = PV.frame
	PV.frame.CurrentCamera = cam
	PV.cam = cam
	local _, size = clone:GetBoundingBox()
	local dist = math.max(size.Y * 1.7, 6)
	cam.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.6, dist), Vector3.new(0, size.Y * 0.45, 0))
end
local function pvSet(on)
	PV.on = on
	if on then
		pvBuild()
		if PV.conn then pcall(function() PV.conn:Disconnect() end) PV.conn = nil end
		PV.conn = LP.CharacterAdded:Connect(function()
			task.wait(1)
			if PV.on then pvBuild() end
		end)
		task.spawn(function()
			while PV.on do
				task.wait(5)
				if PV.on then pcall(pvBuild) end
			end
		end)
	else
		if PV.conn then pcall(function() PV.conn:Disconnect() end) PV.conn = nil end
		pvClear()
	end
end
------------------------------ SKINS (simplified, user entries) ------------------------------
function initSkins()
	local players = game:GetService("Players")
	local lp = players.LocalPlayer

	local SK = {
		slot = "all", rarity = "all", records = "all", keep = false,
		list = {}, picked = {}, backups = {}, n = 0,
	}
	local RARITIES = { "Common", "Uncommon", "Rare", "Legendary", "Godly", "Ancient" }

	local function findTool(kind)
		local places = { lp.Character, lp:FindFirstChildOfClass("Backpack") }
		for _, cont in ipairs(places) do
			if cont then
				for _, t in ipairs(cont:GetChildren()) do
					if t:IsA("Tool") then
						if (kind == "knives" and t.Name == "Knife") or (kind == "guns" and t.Name == "Gun") then
							return t
						end
					end
				end
			end
		end
		return nil
	end

	local function paintTool(tool, meshId, texId)
		if not tool then return false end
		local painted = false
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("MeshPart") then
				if not SK.backups[d] then
					SK.backups[d] = { kind = "meshpart", mesh = d.MeshId }
				end
				pcall(function() d.MeshId = meshId end)
				painted = true
			elseif d:IsA("SpecialMesh") then
				if not SK.backups[d] then
					SK.backups[d] = { kind = "special", mesh = d.MeshId, tex = d.TextureId }
				end
				pcall(function()
					d.MeshId = meshId
					if texId and texId ~= "" then d.TextureId = texId end
				end)
				painted = true
			end
		end
		return painted
	end

	local function restoreTool(kind)
		for obj, b in pairs(SK.backups) do
			if obj and obj.Parent then
				local tool = obj
				while tool and tool.Parent and not tool:IsA("Tool") do
					tool = tool.Parent
				end
				local match = false
				if tool and tool:IsA("Tool") then
					if kind == "all" then match = true
					elseif kind == "knives" and tool.Name == "Knife" then match = true
					elseif kind == "guns" and tool.Name == "Gun" then match = true end
				end
				if match then
					pcall(function()
						if b.kind == "meshpart" then
							obj.MeshId = b.mesh
						else
							obj.MeshId = b.mesh
							obj.TextureId = b.tex
						end
					end)
					SK.backups[obj] = nil
				end
			else
				SK.backups[obj] = nil
			end
		end
	end

	local function applyEntry(entry)
		if not entry then return false end
		local tool = findTool(entry.Kind)
		if not tool then return false end
		local meshId = entry.Mesh
		if not meshId:find("://") then
			meshId = "rbxassetid://" .. meshId:gsub("%D", "")
		end
		local texId = entry.Tex or ""
		if texId ~= "" and not texId:find("://") then
			local digits = texId:gsub("%D", "")
			if digits ~= "" then texId = "rbxassetid://" .. digits end
		end
		local ok = paintTool(tool, meshId, texId)
		entry.Status = ok and "working" or "broken"
		return ok
	end

	local function applyPicked()
		for name in pairs(SK.picked) do
			for _, e in ipairs(SK.list) do
				if e.Name == name then
					applyEntry(e)
					break
				end
			end
		end
	end

	local refreshGrid = nil
	local charConn = lp.CharacterAdded:Connect(function()
		task.wait(1)
		if SK.keep then applyPicked() end
	end)

	getgenv().SKN = {
		rarities = RARITIES,
		setSlot = function(v) SK.slot = v end,
		setRarity = function(v) SK.rarity = v end,
		setRecords = function(v) SK.records = v end,
		setKeep = function(v) SK.keep = v end,
		add = function(mesh, tex, kind, rarity)
			mesh = tostring(mesh or "")
			local digits = mesh:gsub("%D", "")
			if digits == "" then return false end
			SK.n = SK.n + 1
			local e = {
				Name = (kind == "guns" and "Gun " or "Knife ") .. digits:sub(-6),
				Kind = (kind == "guns") and "guns" or "knives",
				Mesh = digits, Tex = tostring(tex or ""),
				Rarity = rarity or "Common", Status = "working",
			}
			SK.list[#SK.list + 1] = e
			if refreshGrid then pcall(refreshGrid) end
			return true
		end,
		remove = function(entry)
			for i = 1, #SK.list do
				if SK.list[i] == entry then
					table.remove(SK.list, i)
					break
				end
			end
			if SK.picked[entry.Name] then
				SK.picked[entry.Name] = nil
				restoreTool(entry.Kind)
			end
			if refreshGrid then pcall(refreshGrid) end
		end,
		entries = function() return SK.list end,
		pickedSet = function()
			local t = {}
			for n in pairs(SK.picked) do t[#t + 1] = n end
			return t
		end,
		toggle = function(name)
			if SK.picked[name] then
				SK.picked[name] = nil
				for _, e in ipairs(SK.list) do
					if e.Name == name then
						restoreTool(e.Kind)
						break
					end
				end
			else
				SK.picked[name] = true
				applyPicked()
			end
			if refreshGrid then pcall(refreshGrid) end
		end,
		restoreKnife = function() restoreTool("knives") end,
		restoreGun = function() restoreTool("guns") end,
		restoreAll = function() restoreTool("all") end,
		setRefresh = function(fn) refreshGrid = fn end,
		unload = function()
			restoreTool("all")
			if charConn then pcall(function() charConn:Disconnect() end) end
		end,
	}
end
initSkins()
------------------------------ BUILD: PREVIEW/TOOLS/ALERTS/MAPS/SKINS ------------------------------
pSkin = makePage("skins", "◈", "skin.changer")
local SV = getgenv().SV

do
	local sec = Section(pVis, "preview", "right")
	local opt = TRow(sec, "preview", false, function(v) pvSet(v) end, true)
	local vf = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C(8, 8, 12), BorderSizePixel = 0,
	}, opt)
	mk("UICorner", { CornerRadius = UDim.new(0, 5) }, vf)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Parent = vf
	PV.frame = vp
	TBtn(opt, "refresh", function() pvBuild() end)
end

do
	local TT, FR = getgenv().TT, getgenv().FR

	do
		local sec = Section(pMisc, "tools", "left")
		TRow(sec, "show values", false, function(v) SV.setOn(v) end, false)
		TRow(sec, "tp tool", false, function(v) TT.setTpTool(v) end, false)
		local fopt = TRow(sec, "fling tool", false, function(v) TT.setFlingTool(v) end, true)
		TRow(fopt, "bypass velocity", false, function(v) TT.setBypassVel(v) end, false)
		TRow(sec, "fling murder", false, function(v) FR.setMurder(v) end, false)
		TRow(sec, "fling sheriff", false, function(v) FR.setSheriff(v) end, false)
		TRow(sec, "bypass velocity", false, function(v) FR.setBypass(v) end, false)
		TBtn(sec, "lobby", function() TT.goLobby() end)
		TBtn(sec, "teleport to map", function() TT.goMap() end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		TT.unload()
		FR.unload()
	end)
end

do
	local NT, SN = getgenv().NT, getgenv().SN

	local function sndDrop(parent, name, cur, cb)
		local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
		mk("TextLabel", {
			Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1,
			Text = name, Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local b = mk("TextButton", {
			Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
			BackgroundTransparency = 1, Text = cur .. "  ▾",
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
			TextXAlignment = Enum.TextXAlignment.Right, AutoButtonColor = false,
		}, row)
		b.MouseButton1Click:Connect(function()
			local names = SN.names()
			if #names == 0 then return end
			local idx = 0
			for i, n in ipairs(names) do
				if n == cur then idx = i break end
			end
			idx = idx % #names + 1
			cur = names[idx]
			b.Text = cur .. "  ▾"
			pcall(cb, cur)
			playSnd()
		end)
	end

	do
		local sec = Section(pMisc, "alerts", "right")
		local nopt = TRow(sec, "notify", false, function(v) NT.setOn(v) end, true)
		TRow(nopt, "miss", false, function(v) NT.setMiss(v) end, false)
		TRow(nopt, "kill murder", false, function(v) NT.setKillM(v) end, false)
		TRow(nopt, "roles", false, function(v) NT.setRoles(v) end, false)
	end

	do
		local sec = Section(pMisc, "sheriff kill", "right")
		local sopt = TRow(sec, "sheriff kill", false, function(v) SN.apply("sheriff", v) end, true)
		sndDrop(sopt, "sound", "mc bow", function(v) SN.setName("sheriff", v) end)
		TSlider(sopt, "volume", 0.1, 5, 1, 1, function(v) SN.setVolume("sheriff", v) end)
	end

	do
		local sec = Section(pMisc, "murder kill", "right")
		local mopt = TRow(sec, "murder kill", false, function(v) SN.apply("murder", v) end, true)
		sndDrop(mopt, "sound", "skeet", function(v) SN.setName("murder", v) end)
		TSlider(mopt, "volume", 0.1, 5, 1, 1, function(v) SN.setVolume("murder", v) end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		NT.unload()
		SN.unload()
	end)
end

do
	local MP = getgenv().MP

	local sec = Section(pMisc, "maps", "left")
	local aopt = TRow(sec, "auto vote", false, function(v) MP.setAuto(v) end, true)
	TRow(aopt, "dupe", false, function(v) MP.setDupe(v) end, false)
	TSlider(aopt, "count", 1, 11, 3, 0, function(v) MP.setCount(v) end)
	local listHost = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, sec)
	mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)

	local function rebuildMaps()
		for _, ch in ipairs(listHost:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local sel = {}
		for _, n in ipairs(MP.picked()) do sel[n] = true end
		local rows = MP.rows()
		if #rows == 0 then
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
				Text = "no maps seen yet (join lobby)", Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
			}, listHost)
			return
		end
		table.sort(rows, function(a, b) return a.name < b.name end)
		for _, e in ipairs(rows) do
			local on = sel[e.name] and true or false
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, listHost)
			local im = mk("ImageLabel", {
				Position = UDim2.new(0, 22, 0.5, -16), Size = UDim2.new(0, 32, 0, 32),
				BackgroundColor3 = C(30, 30, 40), BorderSizePixel = 0,
				Image = e.image or "",
			}, row)
			mk("UICorner", { CornerRadius = UDim.new(0, 4) }, im)
			local box = mk("TextButton", {
				Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = on and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
				AutoButtonColor = false, Text = "",
			}, row)
			mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
			mk("UIStroke", { Color = on and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Text = on and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
				TextColor3 = C(255, 255, 255),
			}, box)
			local function toggleMap()
				local cur = MP.picked()
				local has = false
				local out = {}
				for _, n in ipairs(cur) do
					if n == e.name then has = true
					else out[#out + 1] = n end
				end
				if not has then out[#out + 1] = e.name end
				MP.setPicked(out)
				rebuildMaps()
			end
			mk("TextButton", {
				Position = UDim2.new(0, 58, 0, 0), Size = UDim2.new(1, -58, 1, 0),
				BackgroundTransparency = 1, Text = e.name,
				Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = on and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
			}, row).MouseButton1Click:Connect(toggleMap)
			box.MouseButton1Click:Connect(toggleMap)
		end
	end

	MP.setGrid({
		SetData = function(_) rebuildMaps() end,
		GetValue = function() return MP.picked() end,
	})
	rebuildMaps()

	unloadBtn.MouseButton1Click:Connect(function()
		MP.unload()
	end)
end
------------------------------ BUILD: SKINS ------------------------------
do
	local SKN = getgenv().SKN

	local sec = Section(pSkin, "filters", "left")
	local slotF, rarF, recF = "all", "all", "working"
	TDrop(sec, "slot", { "all", "knives", "guns" }, "all", function(v) SKN.setSlot(v) slotF = v rebuildSkins() end)
	TDrop(sec, "rarity", { "all", "Common", "Uncommon", "Rare", "Legendary", "Godly", "Ancient" }, "all", function(v) SKN.setRarity(v) rarF = v rebuildSkins() end)
	TDrop(sec, "records", { "working", "all", "broken" }, "working", function(v) SKN.setRecords(v) recF = v rebuildSkins() end)
	TRow(sec, "keep applied", false, function(v) SKN.setKeep(v) end, false)

	local fsec = Section(pSkin, "add skin", "left")
	local addMesh, addTex, addKind, addRar = "", "", "knives", "Common"
	TInput(fsec, "mesh id", "123456", "add", function(t)
		addMesh = t
		if addMesh ~= "" then
			SKN.add(addMesh, addTex, addKind, addRar)
			addMesh, addTex = "", ""
		end
	end)
	TInput(fsec, "texture id", "optional", "add", function(t)
		addTex = t
	end)
	TDrop(fsec, "kind", { "knives", "guns" }, "knives", function(v) addKind = v end)
	TDrop(fsec, "rarity", { "Common", "Uncommon", "Rare", "Legendary", "Godly", "Ancient" }, "Common", function(v) addRar = v end)
	TBtn(fsec, "add", function()
		if addMesh ~= "" then
			SKN.add(addMesh, addTex, addKind, addRar)
			addMesh, addTex = "", ""
		end
	end)

	local gsec = Section(pSkin, "skins", "right")
	local listHost = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, gsec)
	mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listHost)

	function rebuildSkins()
		for _, ch in ipairs(listHost:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local picked = {}
		for _, n in ipairs(SKN.pickedSet()) do picked[n] = true end
		if #SKN.entries() == 0 then
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
				Text = "no skins - add mesh ids above", Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
			}, listHost)
			return
		end
		for _, e in ipairs(SKN.entries()) do
			if slotF ~= "all" and e.Kind ~= slotF then continue end
			if rarF ~= "all" and e.Rarity ~= rarF then continue end
			if recF ~= "all" and e.Status ~= recF then continue end
			local on = picked[e.Name] and true or false
			local dot = e.Status == "working" and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 80, 80)
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, listHost)
			mk("Frame", {
				Position = UDim2.new(0, 2, 0.5, -3), Size = UDim2.new(0, 6, 0, 6),
				BackgroundColor3 = dot, BorderSizePixel = 0,
			}, row)
			local box = mk("TextButton", {
				Position = UDim2.new(0, 12, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = on and ACCENT or C(30, 30, 40), BorderSizePixel = 0,
				AutoButtonColor = false, Text = "",
			}, row)
			mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
			mk("UIStroke", { Color = on and ACCENT or C(85, 85, 105), Thickness = 1 }, box)
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Text = on and "✓" or "", Font = Enum.Font.GothamBold, TextSize = 12,
				TextColor3 = C(255, 255, 255),
			}, box)
			mk("TextButton", {
				Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -52, 1, 0),
				BackgroundTransparency = 1, Text = e.Name .. "  [" .. e.Kind .. "]",
				Font = Enum.Font.Gotham, TextSize = 12,
				TextColor3 = on and TXT or DIM, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
			}, row).MouseButton1Click:Connect(function()
				SKN.toggle(e.Name)
			end)
			box.MouseButton1Click:Connect(function()
				SKN.toggle(e.Name)
			end)
			mk("TextButton", {
				Position = UDim2.new(1, -18, 0, 0), Size = UDim2.new(0, 18, 1, 0),
				BackgroundTransparency = 1, Text = "x",
				Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM,
			}, row).MouseButton1Click:Connect(function()
				SKN.remove(e)
			end)
		end
	end
	SKN.setRefresh(rebuildSkins)
	rebuildSkins()

	do
		local rsec = Section(pSkin, "restore", "right")
		TBtn(rsec, "restore knife", function() SKN.restoreKnife() end)
		TBtn(rsec, "restore gun", function() SKN.restoreGun() end)
		TBtn(rsec, "restore all", function() SKN.restoreAll() end)
	end

	unloadBtn.MouseButton1Click:Connect(function()
		SKN.unload()
	end)
end
------------------------------ CONFIG SYSTEM (workspace/*.cfg) ------------------------------
local CFGDIR = "configs"
local cfgPick = nil

local function cfgCleanName(n)
	n = tostring(n or "")
	n = string.gsub(n, "[^%w_%- ]+", "")
	n = string.gsub(n, "^%s+", "")
	n = string.gsub(n, "%s+$", "")
	if n == "" then n = "config" end
	return n
end

local function cfgEnsureDir()
	if type(makefolder) ~= "function" or type(isfile) ~= "function" then return end
	local has = false
	pcall(function() has = isfile(CFGDIR) end)
	if not has then pcall(makefolder, CFGDIR) end
end

local function cfgSave(name)
	name = cfgCleanName(name)
	local data = { v = 1 }
	local n = 0
	for flag, h in pairs(CFGREG) do
		local ok, val = pcall(h.get)
		if ok and val ~= nil then
			data[flag] = val
			n = n + 1
		end
		if h.bindGet then
			local ok2, bk = pcall(h.bindGet)
			if ok2 and bk then
				data[flag .. "#bind"] = bk
				n = n + 1
			end
		end
	end
	local hs = game:GetService("HttpService")
	local ok, json = pcall(function() return hs:JSONEncode(data) end)
	if not ok or type(json) ~= "string" then
		toast("cfg encode failed")
		return
	end
	cfgEnsureDir()
	if type(writefile) ~= "function" then
		toast("writefile missing")
		return
	end
	local okw = pcall(writefile, CFGDIR .. "/" .. name .. ".cfg", json)
	toast(okw and ("saved " .. name .. " (" .. n .. ")") or "save failed")
	refreshCfgList()
end

local function cfgLoad(name)
	name = cfgCleanName(name)
	if type(readfile) ~= "function" then
		toast("readfile missing")
		return
	end
	local ok, raw = pcall(readfile, CFGDIR .. "/" .. name .. ".cfg")
	if not ok or type(raw) ~= "string" then
		toast("cfg not found")
		return
	end
	local hs = game:GetService("HttpService")
	local ok2, data = pcall(function() return hs:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then
		toast("bad cfg file")
		return
	end
	local okN, errN = 0, 0
	for flag, h in pairs(CFGREG) do
		if data[flag] ~= nil then
			if pcall(h.set, data[flag]) then okN = okN + 1 else errN = errN + 1 end
		end
		if h.bindSet and data[flag .. "#bind"] ~= nil then
			pcall(h.bindSet, data[flag .. "#bind"])
		end
	end
	toast("loaded " .. name .. " (" .. okN .. ")")
end

local function cfgFiles()
	local out = {}
	if type(listfiles) == "function" then
		local ok, rows = pcall(listfiles, CFGDIR)
		if ok and type(rows) == "table" then
			for _, f in ipairs(rows) do
				if type(f) == "string" then
					local nm = string.match(string.gsub(f, "\\", "/"), "([^/]+)%.cfg$")
					if nm then out[#out + 1] = nm end
				end
			end
		end
	end
	table.sort(out)
	return out
end

local function cfgDelete(name)
	name = cfgCleanName(name)
	if type(delfile) ~= "function" then
		toast("delfile missing")
		return
	end
	pcall(delfile, CFGDIR .. "/" .. name .. ".cfg")
	toast("deleted " .. name)
	refreshCfgList()
end

------------------------------ BUILD: CONFIG (misc tab) ------------------------------
do
	local sec = Section(pMisc, "config", "left")
	local cfgName = ""
	TInput(sec, "name", "my config", "save", function(t)
		cfgName = t
		cfgSave(t)
	end)
	local listRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, sec)
	mk("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0), BackgroundTransparency = 1,
		Text = "config", Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left,
	}, listRow)
	local pickBtn = mk("TextButton", {
		Position = UDim2.new(0.3, 0, 0, 0), Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1, Text = "none  ▾",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right, AutoButtonColor = false,
	}, listRow)
	pickBtn.MouseButton1Click:Connect(function()
		local files = cfgFiles()
		if #files == 0 then
			pickBtn.Text = "none  ▾"
			cfgPick = nil
			return
		end
		local idx = 0
		for i, f in ipairs(files) do
			if f == cfgPick then idx = i break end
		end
		idx = idx % #files + 1
		cfgPick = files[idx]
		pickBtn.Text = cfgPick .. "  ▾"
		playSnd()
	end)
	local brow = mk("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, sec)
	local loadB = mk("TextButton", {
		Size = UDim2.new(0.48, 0, 1, 0),
		BackgroundColor3 = C(45, 45, 60), BorderSizePixel = 0,
		Text = "load", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT,
	}, brow)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, loadB)
	local delB = mk("TextButton", {
		Position = UDim2.new(0.52, 0, 0, 0), Size = UDim2.new(0.48, 0, 1, 0),
		BackgroundColor3 = C(60, 35, 40), BorderSizePixel = 0,
		Text = "delete", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TXT,
	}, brow)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, delB)
	loadB.MouseButton1Click:Connect(function()
		playSnd()
		if cfgPick then cfgLoad(cfgPick) else toast("pick a config first") end
	end)
	delB.MouseButton1Click:Connect(function()
		playSnd()
		if cfgPick then cfgDelete(cfgPick) cfgPick = nil end
	end)
	function refreshCfgList()
		local files = cfgFiles()
		local keep = false
		for _, f in ipairs(files) do
			if f == cfgPick then keep = true break end
		end
		if not keep then cfgPick = #files > 0 and files[1] or nil end
		pickBtn.Text = (cfgPick or "none") .. "  ▾"
	end
	refreshCfgList()
end
