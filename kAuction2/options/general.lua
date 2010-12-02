local _G = _G
local kAuction2 = _G.kAuction2
local L = kAuction2.L

function kAuction2.Options.get_general_options()
	
	return
		'movement', {
			type = 'select',
			name = L["Frame movement"],
			desc = L["Limit how frames may be moved."],
			values = {
				["locked"] = L["Locked"],
				["unlocked"] = L["Unlocked with snap"],
				["unlocked-snap"] = L["Unlocked without snap"],
			},
			get = function(info)
				local db = kAuction2.db.profile
				if db.lock_movement then
					return "locked"
				elseif db.frame_snap then
					return "unlocked"
				else
					return "unlocked-snap"
				end
			end,
			set = function(info, value)
				local db = kAuction2.db.profile
				if value == "locked" then
					db.lock_movement = true
				elseif value == "unlocked" then
					db.lock_movement = false
					db.frame_snap = true
				else
					db.lock_movement = false
					db.frame_snap = false
				end
			end,
		},
		'minimap_icon', {
			type = 'toggle',
			name = L["Minimap icon"],
			desc = L["Show an icon on the minimap to open the kAuction config."],
			get = function(info)
				return not kAuction2.db.profile.minimap_icon.hide
			end,
			set = function(info, value)
				kAuction2.db.profile.minimap_icon.hide = not value
				
				if value then
					LibStub("LibDBIcon-1.0"):Show("kAuction2")
				else
					LibStub("LibDBIcon-1.0"):Hide("kAuction2")
				end
			end,
			hidden = function()
				return not LibStub("LibDataBroker-1.1", true) or not LibStub("LibDBIcon-1.0", true) or IsAddOnLoaded("Broker2FuBar")
			end,
		},
		'version', {
			name = L["Version: %s"]:format(kAuction2.version),
			type = 'description',
			order = -1,
			width = 'normal',
		}
end
