local _G = _G
local kAuction2 = _G.kAuction2
local L = kAuction2.L

local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
if not AceConfig then
	LoadAddOn("Ace3")
	AceConfig = LibStub and LibStub("AceConfig-3.0", true)
	if not LibSimpleOptions then
		message(("kAuction2 requires the library %q and will not work without it."):format("AceConfig-3.0"))
		error(("kAuction2 requires the library %q and will not work without it."):format("AceConfig-3.0"))
	end
end
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

AceConfig:RegisterOptionsTable("kAuction2_Bliz", {
	name = L["kAuction2"],
	handler = kAuction2,
	type = 'group',
	args = {
		config = {
			name = L["Standalone config"],
			desc = L["Open a standlone config window, allowing you to actually configure PitBull Unit Frames 4.0."],
			type = 'execute',
			func = function()
				kAuction2.Options.OpenConfig()
			end
		}
	},
})
AceConfigDialog:AddToBlizOptions("kAuction2_Bliz", "kAuction2")

do
	for i, cmd in ipairs { "/kAuction2", "/kAuction", "/ka2", "/ka" } do
		_G["SLASH_KAUCTIONTWO" .. (i*2 - 1)] = cmd
		_G["SLASH_KAUCTIONTWO" .. (i*2)] = cmd:lower()
	end

	_G.hash_SlashCmdList["KAUCTIONTWO"] = nil
	_G.SlashCmdList["KAUCTIONTWO"] = function()
		return kAuction2.Options.OpenConfig()
	end
end

kAuction2.Options = {}

local options

function kAuction2.Options.HandleModuleLoad(module)
	if not options then
		-- doesn't matter yet, it'll be caught in the real config opening.
		return
	end
	
	kAuction2.Options.modules_handle_module_load(module)
	kAuction2.Options.colors_handle_module_load(module)
	
	kAuction2.Options["layout_editor_" .. module.module_type .. "_handle_module_load"](module)
end

function kAuction2.Options.OpenConfig()
	-- redefine it so that we just open up the pane next time
	function kAuction2.Options.OpenConfig()
		AceConfigDialog:Open("kAuction2")
	end
	
	options = {
		name = L["kAuction"],
		handler = kAuction2,
		type = 'group',
		args = {
		},
	}
	
	local new_order
	do
		local current = 0
		function new_order()
			current = current + 1
			return current
		end
	end
	
	local t = { kAuction2.Options.get_general_options() }
	kAuction2.Options.get_general_options = nil
	
	for i = 1, #t, 2 do
		local k, v = t[i], t[i+1]
		
		options.args[k] = v
		v.order = new_order()
	end
	
	options.args.modules = kAuction2.Options.get_module_options()
	kAuction2.Options.get_module_options = nil
	options.args.modules.order = new_order()
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(kAuction2.db)
	options.args.profile.order = new_order()
	local old_disabled = options.args.profile.disabled
	options.args.profile.disabled = function(info)
		return InCombatLockdown() or (old_disabled and old_disabled(info))
	end
	
	AceConfig:RegisterOptionsTable("kAuction2", options)
	AceConfigDialog:SetDefaultSize("kAuction2", 835, 550)
	
	LibStub("AceEvent-3.0").RegisterEvent("kAuction2.Options", "PLAYER_REGEN_ENABLED", function()
		LibStub("AceConfigRegistry-3.0"):NotifyChange("kAuction2")
	end)
	
	LibStub("AceEvent-3.0").RegisterEvent("kAuction2.Options", "PLAYER_REGEN_DISABLED", function()
		LibStub("AceConfigRegistry-3.0"):NotifyChange("kAuction2")
	end)
	
	return kAuction2.Options.OpenConfig()
end
