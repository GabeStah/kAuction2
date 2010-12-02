local kAuction2 = _G.kAuction2
if not kAuction2 then
  error("kAuction2_Wishlist requires kAuction2")
end
local L = kAuction2.L

local kAuction2_Wishlist = kAuction2:NewModule("Wishlist", "AceEvent-3.0", "AceHook-3.0")
kAuction2_Wishlist:SetModuleType("custom")
kAuction2_Wishlist:SetName(L["Wishlist"])
kAuction2_Wishlist:SetDescription(L["Allow player to create and manage Wishlists."])
kAuction2_Wishlist:SetDefaults({
	kind = "HealthBar",
},{aggro_color = {1, 0, 0, 1}})

local kAuction2_Server

local function callback(aggro, name, unit)
	for frame in kAuction2:IterateFramesForGUID(UnitGUID(unit)) do
		local db = kAuction2_Wishlist:GetLayoutDB(frame)
		if db.enabled then
			if db.kind == "Server" then
				if kAuction2_Server and kAuction2_Server:IsEnabled() then
					kAuction2:Debug('Wishlist.callback', 'Server found and enabled.', 1);
					kAuction2_Server:UpdateFrame(frame)
				end
			end
		end
	end
end

local function set_hooks()
	if not kAuction2_Server then
		kAuction2_Server = kAuction2:GetModule("Server", true)
		if kAuction2_Server then
			kAuction2_Wishlist:RawHook(kAuction2_Server, "Server_Test", "Test_Function")
		end
	end
end

function kAuction2_Wishlist:OnModuleLoaded(module)
	if not self.db.profile.global.enabled then return end
	local id = module.id
	if id == "Server" then
		set_hooks()
	end
end

function kAuction2_Wishlist:OnEnable()
	set_hooks()
end

function kAuction2_Wishlist:OnDisable()
	
end

function kAuction2_Wishlist:Test_Function(module,frame,other)
	kAuction2:Debug('kAuction2_Wishlist:Test_Function', 'This thing fired!', 1)
end

function kAuction2_Wishlist:Test_Function2(module,frame,other)
	kAuction2:Debug('kAuction2_Wishlist:Test_Function2', 'This thing fired!', 1)
end


-- Author      : Gabe
-- Create Date : 2/19/2009 12:42:59 AM
function kAuction2_Wishlist:AddItem(wishlistId, name, itemId)
	local iIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	-- Ensure proper wishlist is manipulated
	if kAuction2.db.profile.wishlists[iIndex] then
		if not kAuction2.db.profile.wishlists[iIndex].items then
			kAuction2.db.profile.wishlists[iIndex].items = {};
		end
		local bidType = "normal";
		if strlower(kAuction2.db.profile.wishlists[iIndex].name) == "normal" then
			bidType = strlower(kAuction2.db.profile.wishlists[iIndex].name);
		elseif strlower(kAuction2.db.profile.wishlists[iIndex].name) == "offspec" then
			bidType = strlower(kAuction2.db.profile.wishlists[iIndex].name);
		elseif strlower(kAuction2.db.profile.wishlists[iIndex].name) == "rot" then
			bidType = strlower(kAuction2.db.profile.wishlists[iIndex].name);
		end 
		local itemLevel = nil;
		local itemSlot = nil;
		if GetItemInfo(itemId) then
			itemLevel = select(4, GetItemInfo(itemId));
			itemSlot = kAuction2:Item_GetEquipSlotNumberOfItem(select(2, GetItemInfo(itemId)), 'formattedName');
		end
		tinsert(kAuction2.db.profile.wishlists[iIndex].items, {
			alert = true,
			autoBid = true,
			autoRemove = true,
			bestInSlot = false,
			bidType = bidType,
			id = itemId,
			level = itemLevel,
			name = name,
			setBonus = false,
			slot = itemSlot,
		});
	end
end
function kAuction2_Wishlist:CreateOptionTable()
	kAuction2.options.args.wishlist.args = {};
	kAuction2.options.args.wishlist.args.header = {
		name = 'General Settings',
		type = 'header',
		order = 1,
	};		
	kAuction2.options.args.wishlist.args.enabled = {
		name = 'Enabled',
		type = 'toggle',
		desc = 'Enable Wishlist functionality.',
		set = function(info,value) kAuction2.db.profile.wishlist.enabled = value end,
		get = function(info) return kAuction2.db.profile.wishlist.enabled end,
		order = 2,
	};
	kAuction2.options.args.wishlist.args.autoUpdate = {
		name = 'Auto-Update',
		type = 'toggle',
		desc = 'Allow kAuction2 to automatically update your Wishlist data from AtlasLoot Wishlist data.',
		set = function(info,value)
			kAuction2.db.profile.wishlist.autoUpdate = value;
		end,
		get = function(info) return kAuction2.db.profile.wishlist.autoUpdate end,
		order = 3,
	};
	kAuction2.options.args.wishlist.args.forceUpdate = {
		name = 'Force Update',
		type = 'execute',
		desc = 'Manually force kAuction2 to update wishlist data from AtlasLoot Wishlists.',
		func = function() kAuction2_Wishlist:UpdateFromAtlasLoot() end,
		order = 4,
	};
	if kAuction2.db.profile.wishlists and #kAuction2.db.profile.wishlists > 0 then
		for iList, vList in pairs(kAuction2.db.profile.wishlists) do
			kAuction2.options.args.wishlist.args[tostring(vList.id)] = {
				name = vList.name,
				type = 'group',
				cmdHidden = true,
				args = {
					items = {
						name = 'Items',
						type = 'group',
						guiInline = true,
						childGroups = 'tab',
						args = {},
					},
				},
			};			
			for iItem, vItem in pairs(vList.items) do
				kAuction2.options.args.wishlist.args[tostring(vList.id)].args.items.args[tostring(vItem.id)] = {
					name = vItem.name,
					type = 'group',
					args = {
						removeItem = {
							name = 'Remove Item',
							type = 'execute',
							desc = 'Remove this item from the Wishlist.',
							func = function()
								kAuction2_Wishlist:RemoveItem(vList.id, vItem.id);
								kAuction2_Wishlist:CreateOptionTable(); -- Refresh options
							end,
							order = 1,
						},			
						alert = {
							name = 'Alert',
							type = 'toggle',
							desc = 'Determines if kAuction2 will alert you when this item drops.  If Auto-bid is enabled, Alert will make kAuction2 provide a popup window alerting you that the item dropped and you auto-bid.  If auto-bid is not enabled, Alert will create a popup informing you the item dropped and asking if you want to bid.',
							set = function(info,value)
								kAuction2_Wishlist:SetItemFlag(vList.id, vItem.id, 'alert', value);
							end,
							get = function(info)
								return kAuction2_Wishlist:GetItemFlag(vList.id, vItem.id, 'alert');
							end,
							order = 2,
						},	
						autoBid = {
							name = 'Auto-bid',
							type = 'toggle',
							desc = 'Determines if kAuction2 will automatically bid for you when this item drops, using the Bid Type specified for the item.',
							set = function(info,value)
								kAuction2_Wishlist:SetItemFlag(vList.id, vItem.id, 'autoBid', value);
							end,
							get = function(info)
								return kAuction2_Wishlist:GetItemFlag(vList.id, vItem.id, 'autoBid');
							end,
							order = 3,
						},	
						bestInSlot = {
							name = 'Best In Slot',
							type = 'toggle',
							desc = 'Determines if this item is a Best in Slot drop for this wishlist.  The Best in Slot flag is transmitted to the raid during bidding to assist in decision making during Loot Council voting.',
							set = function(info,value)
								kAuction2_Wishlist:SetItemFlag(vList.id, vItem.id, 'bestInSlot', value);
							end,
							get = function(info)
								return kAuction2_Wishlist:GetItemFlag(vList.id, vItem.id, 'bestInSlot');
							end,
							order = 4,
						},
						bidType = {
							name = 'Auto-Bid Type',
							desc = 'Type of bid that will be used for this item.',
							type = 'select',
							values = {
								normal = 'Normal',
								offspec = 'Offspec',
								rot = 'Rot',
							},
							style = 'dropdown',
							set = function(info,value)
								kAuction2:Debug("set bidtype: " .. value, 3);
								kAuction2_Wishlist:SetItemFlag(vList.id, vItem.id, 'bidType', value);
							end,
							get = function(info)
								return kAuction2_Wishlist:GetItemFlag(vList.id, vItem.id, 'bidType');
							end,
							order = 5,
						},
						setBonus = {
							name = 'Set Bonus',
							type = 'toggle',
							desc = 'Determines if this item will complete a set bonus for you.',
							set = function(info,value)
								kAuction2_Wishlist:SetItemFlag(vList.id, vItem.id, 'setBonus', value);
							end,
							get = function(info)
								return kAuction2_Wishlist:GetItemFlag(vList.id, vItem.id, 'setBonus');
							end,
							order = 6,
						},
					},
				};
			end
			--[[
			alert = true,
			autoBid = true,
			bestInSlot = false,
			bidType = bidType,
			id = id,
			name = name,
			setBonus = false,
			]]
		end
	end
	-- Check if AtlasLoot loaded
	if (IsAddOnLoaded("AtlasLoot")) then
		
	else
	--[[
		StaticPopupDialogs["kAuction2Popup_EnableAtlasLoot"] = {
			text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|nWishlists are currently disabled as the AtlasLoot addon is not enabled.  Would you like to enable AtlasLoot now (Warning: Clicking 'Yes' will reload your User Interface)?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				EnableAddOn("AtlasLoot");
				ReloadUI();
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1
		};
		StaticPopup_Show("kAuction2Popup_EnableAtlasLoot");
		]]
	end
end
-- PURPOSE: Creates a new Wishlist, else if wishlist exists by name, returns that list
function kAuction2_Wishlist:Create(name, enabled, icon)
	-- Check if exists
	local iId = kAuction2_Wishlist:GetIdByName(name);
	local iIndex = kAuction2_Wishlist:GetIndexById(iId);
	if kAuction2.db.profile.wishlists[iIndex] then -- Exists, return id
		return iId;	
	else -- Doesn't exist, create
		local id = kAuction2_Wishlist:GetUniqueWishlistId();
		tinsert(kAuction2.db.profile.wishlists, {
			id = id,
			name = name,
			enabled = true,
			icon = icon,
		});
		return id;		
	end
end
function kAuction2_Wishlist:DoesWishlistExistInAtlas(wishlistId)
	local iIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	-- Ensure proper wishlist is manipulated
	if kAuction2.db.profile.wishlists[iIndex] then
		local oAtlas = _G[kAuction2.const.wishlist.atlasLootTableName];
		if oAtlas then
			if oAtlas.Own[UnitName("player")] then
				for iList, vList in pairs(oAtlas.Own[UnitName("player")]) do
					if strlower(vList.info[1]) == strlower(kAuction2.db.profile.wishlists[iIndex].name) then
						return true;
					end
				end				
			end
		end
	end
	return false;
end
function kAuction2_Wishlist:DoesWishlistItemExistInAtlas(wishlistId, itemId)
	local iIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	-- Ensure proper wishlist is manipulated
	if kAuction2.db.profile.wishlists[iIndex] then
		local oAtlas = _G[kAuction2.const.wishlist.atlasLootTableName];
		if oAtlas then
			if oAtlas.Own[UnitName("player")] then
				for iList, vList in pairs(oAtlas.Own[UnitName("player")]) do
					if strlower(vList.info[1]) == strlower(kAuction2.db.profile.wishlists[iIndex].name) then
						-- Matching list, check for item
						for iItem, vItem in pairs(vList) do
							if iItem ~= "info" then
								if tonumber(vItem[2]) == tonumber(itemId) then
									return true;
								end
							end
						end
					end
				end				
			end
		end
	end
	return false;
end
function kAuction2_Wishlist:FindItemByFlags(itemList, flags)
	for iItem, vItem in pairs(itemList) do
		local booMatchAllFlags = true;
		for iFlag, vFlag in pairs(flags) do
			if vItem[iFlag] ~= vFlag then
				booMatchAllFlags = false;				
			end
		end
		if booMatchAllFlags == true then
			return vItem;
		end
	end
end
function kAuction2_Wishlist:GetHighestPriorityItemFromSet(itemList)
	local oPriorities = {
		{autoBid = true, bidType = 'normal', bestInSlot = true, setBonus = true},
		{alert = true, bidType = 'normal', bestInSlot = true, setBonus = true},
		{autoBid = true, bidType = 'normal', bestInSlot = true},
		{alert = true, bidType = 'normal', bestInSlot = true},
		{autoBid = true, bidType = 'normal', setBonus = true},
		{alert = true, bidType = 'normal', setBonus = true},
		{autoBid = true, bidType = 'normal'},
		{alert = true, bidType = 'normal'},
		{bidType = 'normal'},
		{autoBid = true, bidType = 'offspec', bestInSlot = true, setBonus = true},
		{alert = true, bidType = 'offspec', bestInSlot = true, setBonus = true},
		{autoBid = true, bidType = 'offspec', bestInSlot = true},
		{alert = true, bidType = 'offspec', bestInSlot = true},
		{autoBid = true, bidType = 'offspec', setBonus = true},
		{alert = true, bidType = 'offspec', setBonus = true},
		{autoBid = true, bidType = 'offspec'},
		{alert = true, bidType = 'offspec'},
		{bidType = 'offspec'},
		{autoBid = true, bidType = 'rot', bestInSlot = true, setBonus = true},
		{alert = true, bidType = 'rot', bestInSlot = true, setBonus = true},
		{autoBid = true, bidType = 'rot', bestInSlot = true},
		{alert = true, bidType = 'rot', bestInSlot = true},
		{autoBid = true, bidType = 'rot', setBonus = true},
		{alert = true, bidType = 'rot', setBonus = true},
		{autoBid = true, bidType = 'rot'},
		{alert = true, bidType = 'rot'},
		{bidType = 'rot'},
	};
	for i, v in pairs(oPriorities) do
		if kAuction2_Wishlist:FindItemByFlags(itemList, v) then
			kAuction2:Debug("Wishlist_GetHighestPriorityItemFromSet - priority match index " .. i, 1);
			return kAuction2_Wishlist:FindItemByFlags(itemList, v);
		end
	end
end
function kAuction2_Wishlist:GetIdByName(name)
	for i,wishlist in pairs(kAuction2.db.profile.wishlists) do
		if strlower(wishlist.name) == strlower(name) then
			-- Item exists already
			return wishlist.id;
		end
	end	
	return nil;
end
function kAuction2_Wishlist:GetIndexById(id)
	for i,wishlist in pairs(kAuction2.db.profile.wishlists) do
		if tonumber(wishlist.id) == tonumber(id) then
			-- Item exists already
			return i;
		end
	end	
	return nil;
end
function kAuction2_Wishlist:GetItemFlag(wishlistId, itemId, flagType)
	local listIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	local itemIndex = kAuction2_Wishlist:IsItemInList(wishlistId, itemId);
	if itemIndex then
		return kAuction2.db.profile.wishlists[listIndex].items[itemIndex][flagType];
	end
	return false;
end
function kAuction2_Wishlist:GetLists()
	return kAuction2.db.profile.wishlists;
end
function kAuction2_Wishlist:GetListById(id)
	if kAuction2.db.profile.wishlists and id then
		for i,v in pairs(kAuction2.db.profile.wishlists) do
			if id == v.id then
				return v;
			end
		end
	end
	return nil;
end
function kAuction2_Wishlist:GetNameById(id)
	for i,wishlist in pairs(kAuction2.db.profile.wishlists) do
		if wishlist.id == id then
			-- Item exists already
			return wishlist.name;
		end
	end	
	return nil;
end
function kAuction2_Wishlist:GetFilterIndexById(id)
	for i,v in pairs(kAuction2.db.profile.wishlist.config.searchFilters) do
		if v.id == id then
			return i;		
		end
	end
	return nil;
end
function kAuction2_Wishlist:GetFilterIndexByKey(key)
	for i,v in pairs(kAuction2.db.profile.wishlist.config.searchFilters) do
		if v.key == key then
			return i;		
		end
	end
	return nil;
end
function kAuction2_Wishlist:GetFilterValueIndexByValueAndType(filterId, value, type)
	local iFilter = kAuction2_Wishlist:GetFilterIndexById(filterId);
	if iFilter then -- Exists
		for i,v in pairs(kAuction2.db.profile.wishlist.config.searchFilters[iFilter].values) do
			if v.type == type and v.value == value then
				return i;		
			end
		end
	end
	return nil;
end
function kAuction2_Wishlist:GetFilterValueIndexById(id)
	for i,v in pairs(kAuction2.db.profile.wishlist.config.searchFilters) do
		if v.values then
			for iVal, vVal in pairs(v.values) do
				if vVal.id == id then
					return i;		
				end
			end
		end
	end
	return nil;
end
function kAuction2_Wishlist:AddValidSearchFilter(key, value, type, name)
	-- TODO: Allow column hide/show in search results
	--[[
		-- Type: match
		-- Type: equation
		{
			id = 1, key = 'equipSlot', values = {
				{id = 1, type = 'match', name = 'Back', value = 'Back'}
			},
		},	
	]]
	-- Check if key exists
	local iFilter = kAuction2_Wishlist:GetFilterIndexByKey(key);
	if iFilter then -- Exists
		-- Check if value and type exists
		local iValue = kAuction2_Wishlist:GetFilterValueIndexByValueAndType(kAuction2.db.profile.wishlist.config.searchFilters[iFilter].id, value, type);
		if not iValue then -- Doesn't exist, create
			if type == 'match' then
				tinsert(kAuction2.db.profile.wishlist.config.searchFilters[iFilter].values, {
					id = kAuction2_Wishlist:GetUniqueSearchFilterId(),
					type = type,
					name = name,
					value = value,
					enabled = true,
				});
			else
				tinsert(kAuction2.db.profile.wishlist.config.searchFilters[iFilter].values, {
					id = kAuction2_Wishlist:GetUniqueSearchFilterId(),
					type = type,
					name = name,
					value = value,
				});
			end
			-- Sort
			table.sort(kAuction2.db.profile.wishlist.config.searchFilters[iFilter].values, function(a,b)
				if a.name and b.name then
					if tostring(a.name) < tostring(b.name) then
						return true;
					else
						return false;
					end
				elseif a.name then
					return true
				elseif b.name then
					return false;
				end
			end);
		end
	else -- Create
		tinsert(kAuction2.db.profile.wishlist.config.searchFilters, {
			id = kAuction2_Wishlist:GetUniqueSearchFilterId(),
			key = key,
			values = {},
		});
	end
end
function kAuction2_Wishlist:GetUniqueSearchFilterId()
	local newId
	local isValidId = false;
	while isValidId == false do
		matchFound = false;
		newId = (math.random(0,2147483647) * -1);
		for i,val in pairs(kAuction2.db.profile.wishlist.config.searchFilters) do
			if val.id == newId then
				matchFound = true;
			end
			for iVal, vVal in pairs(val.values) do
				if vVal.id == newId then
					matchFound = true;
				end
			end
		end
		if matchFound == false then
			isValidId = true;
		end
	end
	return newId;
end
function kAuction2_Wishlist:GetUniqueWishlistId()
	local newId
	local isValidId = false;
	while isValidId == false do
		matchFound = false;
		newId = (math.random(0,2147483647) * -1);
		for i,val in pairs(kAuction2.db.profile.wishlists) do
			if val.id == newId then
				matchFound = true;
			end
		end
		if matchFound == false then
			isValidId = true;
		end
	end
	return newId;
end
function kAuction2_Wishlist:GetWishlistItemMatches(itemId)
	local items = {};
	if kAuction2.db.profile.wishlists then
		-- Loop through lists
		for iList, vList in pairs(kAuction2.db.profile.wishlists) do
			-- Loop through items
			if vList.items then
				for iItem, vItem in pairs(vList.items) do
					if tonumber(vItem.id) == tonumber(itemId) then
						vItem.wishlistId = vList.id;
						tinsert(items, vItem);
					end	
				end
			end			
		end
	end	
	if #items > 0 then
		return items;
	else
		return nil;	
	end
end
function kAuction2_Wishlist:GetWishlistsWithItem(itemId)
	local lists = {};
	if kAuction2.db.profile.wishlists then
		-- Loop through lists
		for iList, vList in pairs(kAuction2.db.profile.wishlists) do
			-- Loop through items
			if vList.items then
				for iItem, vItem in pairs(vList.items) do
					if tonumber(vItem.id) == tonumber(itemId) then
						tinsert(lists, vList);
					end	
				end
			end			
		end
	end	
	if #lists > 0 then
		return lists;
	else
		return nil;	
	end
end
function kAuction2_Wishlist:GetWishlistsWithoutItem(itemId)
	local lists = {};
	if kAuction2.db.profile.wishlists then
		-- Loop through lists
		for iList, vList in pairs(kAuction2.db.profile.wishlists) do
			local booFound = false;
			-- Loop through items
			if vList.items then
				for iItem, vItem in pairs(vList.items) do
					if tonumber(vItem.id) == tonumber(itemId) then
						booFound = true;
					end	
				end
			end		
			if booFound == false then
				tinsert(lists, vList);				
			end	
		end
	end	
	if #lists > 0 then
		return lists;
	else
		return nil;	
	end
end
function kAuction2_Wishlist:IsEnabled()
	return kAuction2.db.profile.wishlist.enabled;
end
function kAuction2_Wishlist:IsItemInList(wishlistId, itemId)
	local iIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	-- Ensure proper wishlist is manipulated
	if kAuction2.db.profile.wishlists[iIndex] then
		-- Loop through items
		if kAuction2.db.profile.wishlists[iIndex].items then
			for iItem, vItem in pairs(kAuction2.db.profile.wishlists[iIndex].items) do
				if tonumber(vItem.id) == tonumber(itemId) then
					return iItem;
				end	
			end
		end
		return false;
	end	
end
function kAuction2_Wishlist:RemoveItem(wishlistId, itemId)
	kAuction2:Debug("FUNC: kAuction2_Wishlist:RemoveItem, list id: " .. wishlistId .. ", item id: " .. itemId, 1);
	local index = kAuction2_Wishlist:GetIndexById(wishlistId);
	local itemIndex = kAuction2_Wishlist:IsItemInList(wishlistId, itemId);
	if itemIndex then
		kAuction2:Debug("FUNC: kAuction2_Wishlist:RemoveItem, index found " .. itemIndex, 3);
		if kAuction2.db.profile.wishlists[index].items[itemIndex] then
			kAuction2:Debug("FUNC: kAuction2_Wishlist:RemoveItem, list ("..index..") and item found " .. itemIndex, 1);
			-- Remove item from local
			tremove(kAuction2.db.profile.wishlists[index].items, itemIndex);
		end
	end	
end
function kAuction2_Wishlist:RemoveList(wishlistId)
	local index = kAuction2_Wishlist:GetIndexById(wishlistId);
	if index then
		-- Remove item from local
		tremove(kAuction2.db.profile.wishlists, index);
	end	
end
function kAuction2_Wishlist:SetItemFlag(wishlistId, itemId, flagType, value)
	local listIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	local itemIndex = kAuction2_Wishlist:IsItemInList(wishlistId, itemId);
	if itemIndex then
		kAuction2.db.profile.wishlists[listIndex].items[itemIndex][flagType] = value;
		return true;
	end
	return false;
end
function kAuction2_Wishlist:SetListFlag(wishlistId, flagType, value)
	local listIndex = kAuction2_Wishlist:GetIndexById(wishlistId);
	if listIndex then
		kAuction2.db.profile.wishlists[listIndex][flagType] = value;
		return true;
	end
	return false;
end
function kAuction2_Wishlist:SetFilterValueFlag(valueId, flagType, value)
	local iValue = kAuction2_Wishlist:GetFilterValueIndexById(valueId);
	for iF, vF in pairs(kAuction2.db.profile.wishlist.config.searchFilters) do
		for iV, vV in pairs(vF.values) do
			if vV.id == valueId then
				vV[flagType] = value;
			end
		end
	end
	return false;
end
function kAuction2_Wishlist:SortList(listId, sortKey)
	local index = kAuction2_Wishlist:GetIndexById(listId);
	if index then
		if kAuction2.db.profile.wishlists[index].items and #kAuction2.db.profile.wishlists[index].items > 0 then
			-- Verify key exists
			--if kAuction2.db.profile.wishlists[index].items[1][sortKey] then
				-- Check if current sort key matches this sort key, if so, reverse the sort order, if not, set order normal
				if kAuction2.db.profile.wishlist.config.listSortKey == sortKey then
					-- Reverse current sort flag due to click
					if kAuction2.db.profile.wishlist.config.listSortOrderNormal then
						kAuction2.db.profile.wishlist.config.listSortOrderNormal = false
					else
						kAuction2.db.profile.wishlist.config.listSortOrderNormal = true;
					end
				else
					kAuction2.db.profile.wishlist.config.listSortOrderNormal = true;
				end
				-- Set key
				kAuction2.db.profile.wishlist.config.listSortKey = sortKey;
				table.sort(kAuction2.db.profile.wishlists[index].items, function(a,b)
					if a[kAuction2.db.profile.wishlist.config.listSortKey] and b[kAuction2.db.profile.wishlist.config.listSortKey] then
						if kAuction2.db.profile.wishlist.config.listSortOrderNormal then
							if a[kAuction2.db.profile.wishlist.config.listSortKey] < b[kAuction2.db.profile.wishlist.config.listSortKey] then
								return true;
							else
								return false;
							end
						else
							if a[kAuction2.db.profile.wishlist.config.listSortKey] > b[kAuction2.db.profile.wishlist.config.listSortKey] then
								return true;
							else
								return false;
							end
						end
					elseif a[kAuction2.db.profile.wishlist.config.listSortKey] then
						return true
					elseif b[kAuction2.db.profile.wishlist.config.listSortKey] then
						return false;
					end
				end);		
			--end
		end
	end
end
--[[ DEPRECATED
function kAuction2_Wishlist:UpdateFromAtlasLoot()
	if kAuction2_Wishlist:IsEnabled() then -- Check if enabled
		local oAtlas = _G[kAuction2.const.wishlist.atlasLootTableName];
		if oAtlas then
			if oAtlas.Own[UnitName("player")] then
				-- Loop through each list
				for iList, vList in pairs(oAtlas.Own[UnitName("player")]) do
					-- Add wishlist
					local iListId = kAuction2_Wishlist:Create(vList.info[1], true, vList.info[3]);
					local iListIndex = kAuction2_Wishlist:GetIndexById(iListId);
					-- Ensure proper wishlist is manipulated
					if kAuction2.db.profile.wishlists[iListIndex] then
						for iItem, vItem in pairs(vList) do
							-- Check for actual item entry
							if iItem ~= "info" then
								local itemId = vItem[2];
								local itemName = '';
								if GetItemInfo(itemId) then
									itemName = GetItemInfo(itemId);
								else
									itemName = strsub(vItem[4], 11);
								end
								-- Ensure item doesn't exist, then add
								if kAuction2_Wishlist:IsItemInList(kAuction2.db.profile.wishlists[iListIndex].id, itemId) == false then
									kAuction2_Wishlist:AddItem(kAuction2.db.profile.wishlists[iListIndex].id, itemName, itemId);
								end
							end
						end												
					end
				end
			end
		end
	end
	-- Create options table
	kAuction2_Wishlist:CreateOptionTable();
end
]]