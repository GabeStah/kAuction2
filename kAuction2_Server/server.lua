if select(6, GetAddOnInfo("kAuction2_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local kAuction2 = _G.kAuction2
if not kAuction2 then
  error("kAuction2_Server requires kAuction2")
end
local L = kAuction2.L

local LibBanzai

local kAuction2_Server = kAuction2:NewModule("Server", "AceEvent-3.0", "AceHook-3.0")
kAuction2_Server:SetModuleType("custom")
kAuction2_Server:SetName(L["Aggro"])
kAuction2_Server:SetDescription(L["Allow player to host/create kAuction2 raids and auctions"])
kAuction2_Server:SetDefaults({
	kind = "HealthBar",
},{aggro_color = {1, 0, 0, 1}})

local kAuction2_HealthBar
local kAuction2_Border
local kAuction2_Background

local function callback(aggro, name, unit)
	for frame in kAuction2:IterateFramesForGUID(UnitGUID(unit)) do
		local db = kAuction2_Server:GetLayoutDB(frame)
		if db.enabled then
			if db.kind == "HealthBar" then
				if kAuction2_HealthBar and kAuction2_HealthBar:IsEnabled() then
					kAuction2_HealthBar:UpdateFrame(frame)
				end
			elseif db.kind == "Border" then
				if kAuction2_Border and kAuction2_Border:IsEnabled() then
					kAuction2_Border:UpdateFrame(frame)
				end
			elseif db.kind == "Background" then
				if kAuction2_Background and kAuction2_Background:IsEnabled() then
					kAuction2_Background:UpdateFrame(frame)
				end
			end
		end
	end
end

local function set_hooks()
	if not kAuction2_HealthBar then
		kAuction2_HealthBar = kAuction2:GetModule("HealthBar", true)
		if kAuction2_HealthBar then
			kAuction2_Server:RawHook(kAuction2_HealthBar, "GetColor", "HealthBar_GetColor")
		end
	end

	if not kAuction2_Border then
		kAuction2_Border = kAuction2:GetModule("Border", true)
		if kAuction2_Border then
			kAuction2_Server:RawHook(kAuction2_Border, "GetTextureAndColor", "Border_GetTextureAndColor")
		end
	end

	if not kAuction2_Background then
		kAuction2_Background = kAuction2:GetModule("Background", true)
		if kAuction2_Background then
			kAuction2_Server:RawHook(kAuction2_Background, "GetColor", "Background_GetColor")
		end
	end
end

function kAuction2_Server:OnModuleLoaded(module)
	if not self.db.profile.global.enabled then return end
	local id = module.id
	if id == "HealthBar" or id == "Border" or id == "Background" then
		set_hooks()
	end
end

function kAuction2_Server:OnEnable()
	if not LibBanzai then
		LoadAddOn("LibBanzai-2.0")
		LibBanzai = LibStub("LibBanzai-2.0", true)
	end
	if not LibBanzai then
		error(L["kAuction2_Server requires the library LibBanzai-2.0 to be available."])
	end

	LibBanzai:RegisterCallback(callback)

	set_hooks()
end

function kAuction2_Server:OnDisable()
	LibBanzai:UnregisterCallback(callback)
end

function kAuction2_Server:HealthBar_GetColor(module, frame, value)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	if unit and db.enabled and db.kind == "HealthBar" and UnitIsFriend("player", unit) and LibBanzai and LibBanzai:GetUnitAggroByUnitId(unit) then
		local aggro_color = self.db.profile.global.aggro_color
		return aggro_color[1], aggro_color[2], aggro_color[3], nil, true
	end
	
	return self.hooks[module].GetColor(module, frame, value)
end

function kAuction2_Server:Border_GetTextureAndColor(module, frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)

	local texture, r, g, b, a
	if module:GetLayoutDB(frame).enabled then
		-- Only call GetTextureAndColor if the Border is enabled for the layout already.
		-- This allows the border to enable for the aggro display and then disable back
		-- to the normal settings
		texture, r, g, b, a = self.hooks[module].GetTextureAndColor(module, frame)
	end
	
	if unit and db.enabled and db.kind == "Border" and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		r, g, b, a = unpack(self.db.profile.global.aggro_color)
		if not texture or texture == "None" then
			texture = "Blizzard Tooltip"
		end
	end
	
	return texture, r, g, b, a
end

function kAuction2_Server:Background_GetColor(module, frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)

	local r, g, b, a
	if module:GetLayoutDB(frame).enabled then
		-- Only call GetColor if the Background is enabled for the layout already.
		-- This allows the background to enable for the aggro display and then disable back
		-- to the normal settings
		r, g, b, a = self.hooks[module].GetColor(module, frame)
	end
	
	if unit and db.enabled and db.kind == "Background" and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		local a2
		r, g, b, a2 = unpack(self.db.profile.global.aggro_color)
		if a then
			a = a * a2
		else
			a = a2
		end
	end
	
	return r, g, b, a
end

kAuction2_Server:SetLayoutOptionsFunction(function(self)
	local function is_kind_allowed(kind)
		if kind == "HealthBar" then
			return kAuction2_HealthBar and kAuction2_HealthBar:IsEnabled() and kAuction2.Options.GetLayoutDB(kAuction2_HealthBar.id).enabled
		elseif kind == "Border" then
			return kAuction2_Border and kAuction2_Border:IsEnabled()
		elseif kind == "Background" then
			return kAuction2_Background and kAuction2_Background:IsEnabled()
		elseif kind == "" then
			return true
		else
			return false
		end
	end

	return 'kind', {
		type = 'select',
		name = L["Display"],
		desc = L["How to display the aggro indication."],
		get = function(info)
			local kind = kAuction2.Options.GetLayoutDB(self).kind
			if not is_kind_allowed(kind) then
				return ""
			end
			return kind
		end,
		set = function(info, value)
			kAuction2.Options.GetLayoutDB(self).kind = value
			
			kAuction2.Options.UpdateFrames()
		end,
		values = function(info)
			local t = {}
			t[""] = L["None"]
			if is_kind_allowed("HealthBar") then 
				t.HealthBar = L["Health bar"]
			end
			if is_kind_allowed("Border") then 
				t.Border = L["Border"]
			end
			if is_kind_allowed("Background") then 
				t.Background = L["Background"]
			end
			return t
		end
	}
end)

kAuction2_Server:SetColorOptionsFunction(function(self)
	return 'aggro_color', {
		type = 'color',
		name = L['Aggro'],
		desc = L['Sets which color to use on the health bar of units that have aggro.'],
		get = function(info)
			return unpack(self.db.profile.global.aggro_color)
		end,
		set = function(info, r, g, b, a)
			self.db.profile.global.aggro_color = {r, g, b, a}
			self:UpdateAll()
		end,
	},
	function(info)
		self.db.profile.global.aggro_color = {1, 0, 0, 1}
	end
end)
