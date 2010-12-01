--Locale
local L = LibStub("AceLocale-3.0"):GetLocale("kAuction2")

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local _G = _G
local kAuction2 = LibStub("AceAddon-3.0"):NewAddon("kAuction2", "AceComm-3.0", "AceEvent-3.0", "AceHook-3.0", "AceSerializer-3.0", "LibShefkiTimer-1.0")
_G.kAuction2 = kAuction2
kAuction2.L = L

function kAuction2:ADDON_LOADED()
	if not kAuction2.LibDataBrokerLauncher then
		local LibDataBroker = LibStub("LibDataBroker-1.1", true)
		if LibDataBroker then
			kAuction2.LibDataBrokerLauncher = LibDataBroker:NewDataObject("kAuction2", {
				type = "launcher",
				icon = [[Interface\Icons\Spell_Nature_StormReach]],
				OnClick = function(clickedframe, button)
					return kAuction2.Options.OpenConfig() 
				end,
				OnTooltipShow = function(tt)
					tt:AddLine(L["kAuction2"])
					tt:AddLine("|cffffff00" .. L["%s|r to open the options menu"]:format(L["Click"]), 1, 1, 1)
				end,
			})
		end
	end

	if not db_icon_done and kAuction2.LibDataBrokerLauncher then
		local LibDBIcon = LibStub("LibDBIcon-1.0", true)
		if LibDBIcon and not IsAddOnLoaded("Broker2FuBar") then
			LibDBIcon:Register("kAuction2", kAuction2.LibDataBrokerLauncher, kAuction2.db.profile.minimap_icon)
			db_icon_done = true
		end
	end
	
	-- Initialize Modules
	self:LoadModules()
end

do
	local function find_kAuction2(...)
		for i = 1, select('#', ...) do
			if (select(i, ...)) == "kAuction2" then
				return true
			end
		end
		return false
	end
	
	local function iter(num_addons, i)
		i = i + 1
		if i >= num_addons then
			-- and we're done
			return nil
		end
		
		-- must be Load-on-demand (obviously)
		if not IsAddOnLoadOnDemand(i) then
			return iter(num_addons, i)
		end
		
		local name = GetAddOnInfo(i)
		
		-- must start with kAuction2_
		local module_name = name:match("^kAuction2_(.*)$")
		if not module_name then
			return iter(num_addons, i)
		end
		
		-- kAuction2 must be in the Dependency list
		if not find_kAuction2(GetAddOnDependencies(i)) then
			return iter(num_addons, i)
		end
		
		local condition = GetAddOnMetadata(name, "X-kAuction2-Condition")
		if condition then
			local func, err = loadstring(condition)
			if func then
				-- function created successfully
				local success, ret = pcall(func)
				if success then
					-- function called and returned successfully
					if not ret then
						-- shouldn't load, e.g. DruidManaBar when you're not a druid
						return iter(num_addons, i)
					end
				end
			end
		end
		
		-- passes all tests
		return i, name, module_name
	end
	
	--- Return a iterator of addon ID, addon name that are modules that kAuction2 can load.
	-- module_name is the same as name without the "kAuction2_" prefix.
	-- @usage for i, name, module_name in kAuction2:IterateLoadOnDemandModules() do
	--     print(i, name, module_name)
	-- end
	-- @return an iterator which returns id, name, module_name
	function kAuction2:IterateLoadOnDemandModules()
		return iter, GetNumAddOns(), 0
	end
end

local modules_not_loaded = {}
kAuction2.modules_not_loaded = modules_not_loaded

--- Load Load-on-demand modules if they are enabled and exist.
-- @usage kAuction2:LoadModules()
function kAuction2:LoadModules()
	-- NOTE: this assumes that module profiles are the same as kAuction2's profile.
	local current_profile = self.db:GetCurrentProfile()
	
	local sv = self.db.sv
	local sv_namespaces = sv and sv.namespaces
	for i, name, module_name in self:IterateLoadOnDemandModules() do
		local module_sv = sv_namespaces and sv_namespaces[module_name]
		local module_profile_db = module_sv and module_sv.profiles and module_sv.profiles[current_profile]
		local enabled = module_profile_db and module_profile_db.global and module_profile_db.global.enabled
		
		if enabled == nil then
			-- we have to figure out the default state
			local default_state = GetAddOnMetadata(name, "X-kAuction2-DefaultState")
			enabled = (default_state ~= "disabled")
		end

		local loaded
		if enabled then
			-- print(("Found module '%s', attempting to load."):format(module_name))
			loaded = LoadAddOn(name)
		end
	
		if not loaded then
			-- print(("Found module '%s', not loaded."):format(module_name))
			modules_not_loaded[module_name] = true
		end
	end
end

--- Load the module with the given id and enable it
function kAuction2:LoadAndEnableModule(id)
	local loaded, reason = LoadAddOn('kAuction2_' .. id)
	if loaded then
		local module = self:GetModule(id)
		assert(module)
		self:EnableModule(module)
	else
		if reason then
			reason = _G["ADDON_"..reason]
		end
		if not reason then
			reason = UNKNOWN
		end
		DEFAULT_CHAT_FRAME:AddMessage(format(L["%s: Could not load module '%s': %s"],"kAuction2",id,reason))
	end
end