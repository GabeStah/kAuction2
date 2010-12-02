--Locale
local L = LibStub("AceLocale-3.0"):GetLocale("kAuction2")

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local _G = _G
local db
local kAuction2 = LibStub("AceAddon-3.0"):NewAddon("kAuction2", "AceComm-3.0", "AceEvent-3.0", "AceHook-3.0", "AceSerializer-3.0", "LibShefkiTimer-1.0")
_G.kAuction2 = kAuction2
kAuction2.L = L
-- VERSION
kAuction2.version = '2.005'

local INVTYPE_BAG = INVTYPE_BAG
local ITEM_BIND_QUEST = ITEM_BIND_QUEST
local ITEM_SOULBOUND = ITEM_SOULBOUND
local ITEM_STARTS_QUEST = ITEM_STARTS_QUEST
local DATABASE_DEFAULTS = {
	profile = {
		debug = {
			enabled = false,
			threshold = 1,
		},
		minimap_icon = {
			hide = false,
			minimapPos = 200,
			radius = 80,
		},
		bidding = {
			auctionReceivedEffect = 3,
			auctionReceivedSound = "Info",
			auctionReceivedTextAlert = 2,
			auctionWinnerReceivedEffect = 1,
			auctionWinnerReceivedSound = "Sonar",
			auctionWinnerReceivedTextAlert = 2,
			auctionWonEffect = 3,
			auctionWonSound = "Victory",
			auctionWonTextAlert = 2,
			autoPopulateCurrentItem = true,
		},
		gui = {
			frames = {
				bids = {
					font = "ABF",
					fontSize = 12,
					itemPopoutDuration = 1,					
					minimized = false,
					visible = true,
					width = 325,
				},
				main = {
					autoRemoveAuctions = false,
					autoRemoveAuctionsDelay = 20,
					barBackgroundColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5},
					barColor = {r = 1, g = 0, b = 0, a = 1},
					barTexture = "BantoBar",
					font = "ABF",
					fontSize = 12,
					height = 152,
					itemPopoutDuration = 1,					
					minimized = false,
					name = "kAuctionMainFrame",
					scale = 1,
					selectedBarBackgroundColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5},
					selectedBarColor = {r = 0, g = 1, b = 0, a = 0.3},
					selectedBarTexture = "BantoBar",
					visible = true,
					width = 325,
					tabs = {
						selectedColor = {r = 0.1, g = 0, b = 0.9, a = 0.25},
						highlightColor = {r = 0.05, g = 0, b = 0.85, a = 0.15},
						inactiveColor = {r = 0, g = 0, b = 0, a = 0},
					},
				},
			},
		},
		items = {
			-- @usage Insert item IDs
			blackList = { -- Items
			},	
			blackListSelected = 1,
			itemTypeWhiteList = {
				{name = "INVTYPE_BAG", auctionType = 1, pattern = INVTYPE_BAG}, -- Random
				{name = "ITEM_BIND_QUEST", auctionType = false, pattern = ITEM_BIND_QUEST},
				{name = "ITEM_SOULBOUND", auctionType = false, pattern = ITEM_SOULBOUND},
				{name = "ITEM_STARTS_QUEST", auctionType = 1, pattern = ITEM_STARTS_QUEST}, -- Random
			},
			itemTypeWhiteListSelected = 1,
			-- @usage Insert item IDs
			whiteList = { -- Items
				{id=45506, auctionType = 1}, --Random, Archivum Data Disc
				{id=44577, auctionType = 1, currentItemSlot = 2}, -- Random, Neck, Heroic Key to the Focusing Iris
				{id=44569, auctionType = 1, currentItemSlot = 2}, -- Random, Neck, Key to the Focusing Iris
				{id=43346, auctionType = 1}, -- Random, Large Satchel of Spoils
				{id=43954, auctionType = 1}, -- Random, Reins of the Twilight Drake
				{id=46052, auctionType = 1}, -- Random, Reply-Code Alpha
				{id=46053, auctionType = 1}, -- Random, Reply-Code Alpha
				{id=43347, auctionType = 1}, -- Random, Satchel of Spoils
				{id=47242, auctionType = 2}, -- Vote, Trophy of the Crusade
			},	
			whiteListConfig = {
				add = {
					auctionTypeSelected = 0,
					itemSlotSelected = 0,
					name = false,
				},
			},			
			whiteListSelected = 1,
		},
		looting = {
			auctionWhisperBidEnabled = true,
			auctionWhisperBidSuppressionEnabled = true,
			auctionWhisperBidSuppressionDelay = 60,
			auctionCloseDelay = 3,
			auctionDuration = 25,
			auctionCloseVoteDuration = 20,
			auctionType = 2, -- 1: Random, 2: Council
			autoAwardRandomAuctions = true,
			autoAssignIfMasterLoot = true,
			councilMembers = {
				"Pohx",
				"Kulldam",
				"Khrashdin",
				"Kilwenn",
				"Huggeybear",
				"Ugra",
				"Kheelan",
			},
			councilMemberSelected = 1,
			disenchanters = { -- Disenchanters
				"Khrashdin",
				"Thawfore",
				"Wakamii",
			},	
			disenchanterSelected = 1,
			displayFirstOpenAuction = false,
			isAutoAuction = true,
			rarityThreshold = 4, -- Epic
			lootManager = nil,
			rollMaximum = 100,
			visiblePublicBidCurrentItems = true,
			visiblePublicBidRolls = true,
			visiblePublicBidVoters = true,
			visiblePublicDetails = true,
		},
		wishlist = {
			enabled = true,
			autoUpdate = true,
			config = {
				selectedSection = 'search',
				searchReturnLimit = 50,
				searchMinRarity = 4,
				searchMinItemLevel = 226,
				searchSortKey = 'name',
				searchSortOrderNormal = true,
				searchThrottleLevel = 10,
				searchThrottleEquipmentLevel = 8,
				spellSearchReturnLimit = 50,
				spellSearchSortKey = 'name',
				spellSearchSortOrderNormal = true,
				listSortKey = 'name',
				listSortOrderNormal = true,
				weightSortKey = 'stat',
				weightSortOrderNormal = true,
				gemMinRarity = 4,
				gemMinItemLevel = 80,
				font = "Arial Narrow",
				fontSize = 10,
				iconSize = 15,
				searchFilters = {
					
				},
			},
		},
		wishlists = {
		},
		zones = {
			validZones = {
				"Baradin Hold",
				"Blackwing Descent",
				"The Bastion of Twilight",
				"Throne of the Four Winds",
			},
			zoneSelected = 1,
		}
	},
};

local do_nothing = function() end

local new, del = kAuction2.new, kAuction2.del

-- A set of all unit frames
local all_frames = {}
kAuction2.all_frames = all_frames

--- Iterate through a set of frames and return those that are shown
local function iterate_shown_frames(set, frame)
	frame = next(set, frame)
	if frame == nil then
		return
	end
	if frame:IsShown() then
		return frame
	end
	return iterate_shown_frames(set, frame)
end

-- iterate through and return only the keys of a table
local function half_next(set, key)
	key = next(set, key)
	if key == nil then
		return nil
	end
	return key
end

-- iterate through and return only the keys of a table. Once exhausted, recycle the table.
local function half_next_with_del(set, key)
	key = next(set, key)
	if key == nil then
		del(set)
		return nil
	end
	return key
end

--- Iterate over all frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in kAuction2:IterateFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in kAuction2:IterateFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function kAuction2:IterateFrames(also_hidden)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end
	
	return not also_hidden and iterate_shown_frames or half_next, all_frames
end

--- Initializes all basic data structures, such as database and addon loaders
function kAuction2:OnInitialize()
	db = LibStub("AceDB-3.0"):New("kAuction2DB", DATABASE_DEFAULTS, 'Default')
	DATABASE_DEFAULTS = nil
	self.db = db
	
	db.RegisterCallback(self, "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	--LibStub("LibDualSpec-1.0"):EnhanceDatabase(db, "PitBull4")
	
	-- used for run-once-only initialization
	self:RegisterEvent("ADDON_LOADED")
	self:ADDON_LOADED()
	
	LoadAddOn("LibDataBroker-1.1")
	LoadAddOn("LibDBIcon-1.0")
end

function kAuction2:OnEnable()
	-- show initial frames
	self:OnProfileChanged()
end

local db_icon_done
--- Create LDB broker and load child modules
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

--- Outputs a debug message to the console.
-- @param func The function calling the debug command
-- @param msg String message to output
-- @param priority The priority debug level threshold; higher is better chance to output.
-- @usage kAuction2:Debug("kAuction2:MyFunction", "Output Message", 3)
function kAuction2:Debug(func,msg,priority)
	if self.db.profile.debug.enabled then
		if priority == nil then
			self:Print(ChatFrame1, "DEBUG: " .. msg)		
		elseif priority <= self.db.profile.debug.threshold then
			self:Print(ChatFrame1, "DEBUG: " .. msg)		
		end
	end		
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

--- Updates all loaded modules with current profile data
function kAuction2:OnProfileChanged()
	-- Notify modules that the profile has changed.
	for _, module in kAuction2:IterateEnabledModules() do
		if module.OnProfileChanged then
			module:OnProfileChanged()
		end
	end

	local db = self.db
	
	for frame in kAuction2:IterateFrames(true) do
		frame:RefreshLayout()
	end
	
	self:LoadModules()

	-- Enable/Disable modules to match the new profile.
	for _,module in self:IterateModules() do
		if module.db.profile.global.enabled then
			self:EnableModule(module)
		else
			self:DisableModule(module)
		end
	end

	if db_icon_done then
		local LibDBIcon = LibStub("LibDBIcon-1.0")
		local minimap_icon_db = db.profile.minimap_icon
		LibDBIcon:Refresh("kAuction2", minimap_icon_db)
		if minimap_icon_db.hide then
			LibDBIcon:Hide("kAuction2")
		else
			LibDBIcon:Show("kAuction2")
		end
	end
end

--- Call a given method on all modules if those modules have the method.
-- This will iterate over disabled modules.
-- @param method_name name of the method
-- @param ... arguments that will pass in to the module
function kAuction2:CallMethodOnModules(method_name, ...)
	for id, module in self:IterateModules() do
		if module[method_name] then
			module[method_name](module, ...)
		end
	end
end