-- Author      : Gabe
-- Create Date : 2/11/2009 7:04:13 AM
kAuction2.regex = {};
kAuction2.regex.patterns = {
	DURABILITY_PATTERN = string.match(DURABILITY_TEMPLATE,"(.+) .+/.+") or "",
	ITEM_BIND_QUEST = ITEM_BIND_QUEST,
	ITEM_STARTS_QUEST = ITEM_STARTS_QUEST,
	ITEM_CLASSES_ALLOWED = ITEM_CLASSES_ALLOWED,
	REQUIRES_PATTERN = string.gsub(ITEM_MIN_SKILL,"%%.",".+"),
};
function kAuction2:Item_CleanupWhitelistDropdownValues()
	local booPlayerFound = false;
	local tempCouncilMembers = {};
	for iItem,vItem in pairs(kAuction2.db.profile.items.whiteList) do
		local matchFound = false;
		for iTemp,vTemp in pairs(tempCouncilMembers) do
			if vTemp == vCouncil then
				matchFound = true;
			end
		end
		if matchFound == false then
			tinsert(tempCouncilMembers, vCouncil);
		end
		if vCouncil == UnitName("player") then
			booPlayerFound = true;
		end
	end
	kAuction2.db.profile.looting.councilMembers = tempCouncilMembers;
	if booPlayerFound == false then
		local playerName = UnitName("player");
		tinsert(kAuction2.db.profile.looting.councilMembers, playerName);
	end
	table.sort(kAuction2.db.profile.looting.councilMembers);
end
function kAuction2:Item_GetRGBColorByRarity(rarity)
	if rarity == 4 then
		return 176/255, 72/255, 248/255;
	elseif rarity == 5 then
		return 255/255, 128/255, 0;
	elseif rarity == 6 then
		return 230/255, 204/255, 128/255;
	elseif rarity == 7 then
		return 230/255, 204/255, 128/255;
	end
	return nil;
end
function kAuction2:Item_GetWhitelistDropdownValues()
	local slotList = {};
	for i,val in pairs(kAuction2.db.profile.items.whiteList) do
		tinsert(slotList, val.name);
	end
	return slotList;
end
function kAuction2:Item_GetItemSlotDropdownValues()
	local slotList = {};
	slotList[0] = "None";
	for i,val in pairs(kAuction2.const.items.ItemEquipLocs) do
		local booExists = false;
		for iList,vList in pairs(slotList) do
			if vList == val.formattedName then
				booExists = true;
			end
		end
		if booExists == false then
			slotList[i] = val.formattedName;
		end
	end
	return slotList;
end
function kAuction2:Item_GetItemSlotByDropdownIndex(index)
	local list = kAuction2:Item_GetItemSlotDropdownValues();
	for i,val in pairs(kAuction2.const.items.ItemEquipLocs) do
		if val.formattedName == list[index] then
			return val.slotNumber;
		end
	end
	return nil;
end
function kAuction2:Item_CanPlayerEquip(itemId)
	local itemLink = select(2, GetItemInfo(itemId));
	if not itemLink then return end;
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		txt = _G["kAuction2TooltipTextLeft"..i]:GetText()
		if kAuction2:Gui_IsTooltipTextRed("Right"..i) and not string.find(txt,kAuction2.regex.patterns.DURABILITY_PATTERN) and not string.match(txt,kAuction2.regex.patterns.REQUIRES_PATTERN) then
			return nil
		end
	end
	return true;
end
function kAuction2:Item_CanPlayerEquipItem(invslot,bag,slot)
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetBagItem(bag,slot)
	for i=2,tooltip:NumLines() do
		txt = _G["kAuction2TooltipTextLeft"..i]:GetText()
		if (kAuction2:Gui_IsTooltipTextRed("Left"..i) or kAuction2:Gui_IsTooltipTextRed("Right"..i)) and not string.find(txt,kAuction2.regex.patterns.DURABILITY_PATTERN) and not string.match(txt,kAuction2.regex.patterns.REQUIRES_PATTERN) then
			return nil
		end
	end
	return true;
end
function kAuction2:Item_GetItemTypeWhitelistData(itemLink)
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		textLeft = _G["kAuction2TooltipTextLeft"..i]:GetText()
		textRight = _G["kAuction2TooltipTextRight"..i]:GetText()
		for iList,vList in pairs(kAuction2.db.profile.items.itemTypeWhiteList) do
			if textLeft then
				if string.find(textLeft,vList.pattern) then
					return vList;
				end
			end
			if textRight then
				if string.find(textRight,vList.pattern) then
					return vList;
				end
			end
		end
	end
	return nil;
end
function kAuction2:Item_GetItemWhitelistData(item)
	local _
	-- Check item
	if (type(item) == "string") or (type(item) == "number") then -- common case first
	elseif type(item) == "table" and type(item.GetItem) == "function" then
		-- Get the link
		_, item = item:GetItem()
		if type(item) ~= "string" then return end
	else
		return
	end
	-- Check if item is in local cache
	local name = GetItemInfo(item);
	for iList,vList in pairs(kAuction2.db.profile.items.whiteList) do
		if vList.name == name then
			return vList;
		end
	end
	return nil;
end
function kAuction2:Item_GetEquipSlotNumberOfItem(item, returnType)
	local _
	-- Check item
	if (type(item) == "string") or (type(item) == "number") then -- common case first
	elseif type(item) == "table" and type(item.GetItem) == "function" then
		-- Get the link
		_, item = item:GetItem()
		if type(item) ~= "string" then return end
	else
		return
	end
	-- Check if item is in local cache
	local name, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(item);
	if not name then return end
	for i,loc in pairs(kAuction2.const.items.ItemEquipLocs) do
		if loc.name == itemEquipLoc then
			kAuction2:Debug("FUNC: Item_GetItemEquipSlotNumber, loc.name: " .. loc.name .. ", loc.SlotNumber: " .. loc.slotNumber, 3);
			if returnType then
				return loc[returnType];
			else
				return loc.slotNumber;
			end
		end
	end
	return nil;
end
function kAuction2:Item_GetEmptyPaperdollTextureOfItem(item)
	local _
	-- Check item
	if (type(item) == "string") or (type(item) == "number") then -- common case first
	elseif type(item) == "table" and type(item.GetItem) == "function" then
		-- Get the link
		_, item = item:GetItem()
		if type(item) ~= "string" then return end
	else
		return
	end
	-- Check if item is in local cache
	local name, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(item);
	if not name then return end
	for i,loc in pairs(kAuction2.const.items.ItemEquipLocs) do
		if loc.name == itemEquipLoc then
			kAuction2:Debug("FUNC: Item_GetItemEmptyPaperdollTexture, loc.name: " .. loc.name .. ", loc.slotName: " .. loc.slotName, 3);
			_,texture = GetInventorySlotInfo(loc.slotName)
			return texture;
		end
	end
	return nil;
end
function kAuction2:Item_GetEmptyPaperdollTextureOfItemSlot(slot)
	for i,loc in pairs(kAuction2.const.items.ItemEquipLocs) do
		if loc.slotNumber == slot then
			_,texture = GetInventorySlotInfo(loc.slotName)
			return texture;
		end
	end
	return nil;
end
function kAuction2:Item_GetTextureOfItem(item)
	local _
	-- Check item
	if (type(item) == "string") or (type(item) == "number") then -- common case first
	elseif type(item) == "table" and type(item.GetItem) == "function" then
		-- Get the link
		_, item = item:GetItem()
		if type(item) ~= "string" then return end
	else
		return
	end
	-- Check if item is in local cache
	local name,_,_,_,_,_,_,_,_,itemTexture = GetItemInfo(item);
	if not name then return end
	if itemTexture then
		return itemTexture;
	end
	return nil;
end
function kAuction2:Item_GetItemNameFromItemId(itemId)
	local name = GetItemInfo(itemId)
	if name then
		return name
	end
	return nil
end
function kAuction2:Item_GetItemIdFromItemName(name)
	kAuction2:Debug("FUNC: Item_GetItemIdFromItemName, RUN, Name: " .. name, 3)
	local _, itemLink = GetItemInfo(name)
	local itemId = kAuction2:Item_GetItemIdFromItemLink(itemLink)
	kAuction2:Debug("FUNC: Item_GetItemIdFromItemName, Return Nil", 3)
	return nil
end
function kAuction2:Item_GetItemIdFromItemLink(link)
	if link then
		kAuction2:Debug("FUNC: Item_GetItemIdFromItemLink, ItemLink: " .. link, 3)
		local found, _, itemString = string.find(link, "^|c%x+|H(.+)|h%[.*%]")
		local _, itemId = strsplit(":", itemString)	
		if itemId then
			kAuction2:Debug("FUNC: Item_GetItemIdFromItemLink, ItemId: " .. itemId, 3)
			return itemId
		end
	end
	return nil
end
function kAuction2:Item_GetItemLinkFromItemId(id)
	if id and GetItemInfo(id) then
		kAuction2:Debug("FUNC: Item_GetItemLinkFromItemId, ItemId: " .. id, 3)
		local _, itemLink = GetItemInfo(id) 
		if itemLink then
			kAuction2:Debug("FUNC: Item_GetItemLinkFromItemId, itemLink: " .. itemLink, 3)
			return itemLink
		end
	end
	return nil
end
function kAuction2:Item_GetInventoryItemMatchTable(matchItem)
	local id = kAuction2:Item_GetEquipSlotNumberOfItem(matchItem) or matchItem;
	local itemLink,itemID,itemName,equipSlot,itemTexture
	-- Clear menu
	local matchTable = {};
	
	-- Loop through bags and add items
	if type(id) == "number" and id<20 then
		for i=0,4 do
			for j=1,GetContainerNumSlots(i) do
				itemLink = GetContainerItemLink(i,j);
				if itemLink then
					itemTexture = kAuction2:Item_GetTextureOfItem(itemLink);
					equipSlot = kAuction2:Item_GetEquipSlotNumberOfItem(itemLink);
					if id == equipSlot and kAuction2:Item_CanPlayerEquipItem(id,i,j) then
						if not kAuction2:Gui_AlreadyInPopoutMenu(itemLink) then
							kAuction2:Debug("FUNC: Item_GetInventoryItemMatchTable, Add bag item: " .. itemLink, 3);
							tinsert(matchTable, itemLink);
						end
					end
				end
			end
		end
		-- Add inventory equipped item
		kAuction2:Debug("FUNC: Item_GetInventoryItemMatchTable, id: " .. id, 3);
		if kAuction2.popout.SlotInfo[id].other then
			equippedItemLink = GetInventoryItemLink("player", kAuction2.popout.SlotInfo[id].other);
			if equippedItemLink and not kAuction2:Gui_AlreadyInPopoutMenu(equippedItemLink) then
				tinsert(matchTable, equippedItemLink);
			end
		end
		local equippedItemLink2 = GetInventoryItemLink("player", id);
		if equippedItemLink2 and not kAuction2:Gui_AlreadyInPopoutMenu(equippedItemLink2) then
			kAuction2:Debug("FUNC: Item_GetInventoryItemMatchTable, Add inventory item: " .. equippedItemLink2, 3);
			tinsert(matchTable, equippedItemLink2);
		end
	elseif type(id) == "number" and id == 20 then
		for i=0,3 do
			local slot = "Bag"..i.."Slot";
			kAuction2:Debug("FUnC: GetInventorySlotInfo : " .. slot, 1);
			local itemLink = GetInventoryItemLink("player",GetInventorySlotInfo(slot))
			if itemLink then
				tinsert(matchTable, itemLink);	
			end
		end
	end
	if matchTable then
		return matchTable;
	else
		return nil;
	end
end
function kAuction2:Item_GetPlayerWonItemList(player, bidType)
	local objItems = {};
	for iAuction,vAuction in pairs(kAuction2.auctions) do
		if vAuction.winner and vAuction.winner == player then
			for iBid,vBid in pairs(vAuction.bids) do
				if bidType then
					if vBid.bidType == bidType and vBid.name == player then
						tinsert(objItems, {itemLink = vAuction.itemLink, bidType = vBid.bidType});
					end
				else
					if vBid.name == player then
						tinsert(objItems, {itemLink = vAuction.itemLink, bidType = vBid.bidType});
					end
				end
			end
		end
	end
	return objItems;
end
function kAuction2:Item_GetItemDataValueById(id, flag)
	if id and flag then
		if flag == 'mobName' then
			for i,v in pairs(kAuction2.itemData.mobs) do
				if v.id == id then
					return v.name;
				end
			end
		elseif flag == 'zoneName' then
			for i,v in pairs(kAuction2.itemData.zones) do
				if v.id == id then
					return v.name;
				end
			end
		end
	end
end
function kAuction2:Item_IsQuestItem(itemLink)
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		textLeft = _G["kAuction2TooltipTextLeft"..i]:GetText()
		textRight = _G["kAuction2TooltipTextRight"..i]:GetText()
		if textLeft then
			if string.find(textLeft,kAuction2.regex.patterns.ITEM_BIND_QUEST) then
				return true;
			end
		end
		if textRight then
			if string.find(textRight,kAuction2.regex.patterns.ITEM_BIND_QUEST) then
				return true;
			end
		end
	end
	return false;
end
function kAuction2:Item_IsStartQuestItem(itemLink)
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		textLeft = _G["kAuction2TooltipTextLeft"..i]:GetText()
		textRight = _G["kAuction2TooltipTextRight"..i]:GetText()
		if textLeft then
			if string.find(textLeft,kAuction2.regex.patterns.ITEM_STARTS_QUEST) then
				return true;
			end
		end
		if textRight then
			if string.find(textRight,kAuction2.regex.patterns.ITEM_STARTS_QUEST) then
				return true;
			end
		end
	end
	return false;
end
function kAuction2:Item_IsItemClassSpecific(itemId)
	local itemLink = select(2, GetItemInfo(itemId));
	if not itemLink then return end;
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		textLeft = _G["kAuction2TooltipTextLeft"..i]:GetText()
		textRight = _G["kAuction2TooltipTextRight"..i]:GetText()
		if textLeft then
			if string.find(textLeft,"Classes: ") then
				return true;
			end
		end
		if textRight then
			if string.find(textRight,"Classes: ") then
				return true;
			end
		end
	end
	return false;
end
function kAuction2:Item_IsPlayerInClassSpecificList(itemId)
	local itemLink = select(2, GetItemInfo(itemId));
	if not itemLink then return end;
	local found,lines,txt = false
	local tooltip = _G["kAuction2Tooltip"];
	local i=1
	while _G["kAuction2TooltipTextLeft"..i] do
		_G["kAuction2TooltipTextLeft"..i]:SetTextColor(0,0,0)
		_G["kAuction2TooltipTextRight"..i]:SetTextColor(0,0,0)
		i=i+1
	end
	tooltip:ClearLines();
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	for i=2,tooltip:NumLines() do
		textLeft = _G["kAuction2TooltipTextLeft"..i]:GetText();
		textRight = _G["kAuction2TooltipTextRight"..i]:GetText();
		if textLeft then
			textLeft = strtrim(textLeft);
			if string.find(textLeft,"Classes: (%a+)") then
				local sub = string.sub(textLeft, 9);
				if string.find(sub, ",") then
					local tbl = { strsplit(",", sub) }
					for i,v in pairs(tbl) do
						if strtrim(v) == UnitClass("player") then
							return true;
						end
					end
				else
					if strtrim(sub) == UnitClass("player") then
						return true;
					end
				end
			end
		end
		if textRight then
			textRight = strtrim(textRight);
			if string.find(textRight,"Classes: (%a+)") then
				local sub = string.sub(textRight, 9);
				if string.find(sub, ",") then
					local tbl = { strsplit(",", sub) }
					for i,v in pairs(tbl) do
						if strtrim(v) == UnitClass("player") then
							return true;
						end
					end
				else
					if strtrim(sub) == UnitClass("player") then
						return true;
					end
				end
			end
		end
	end
	return false;	
end
function kAuction2:Item_PopulateItemData(dataSet)
	if dataSet then
		for i,v in pairs(dataSet) do
			-- Loop through ItemData
			for iItem,vItem in pairs(kAuction2.itemData.items) do
				if v.id == vItem.id then
					-- Match, populate
					dataSet[i].mobId = vItem.mobId;
					dataSet[i].mobName = kAuction2:Item_GetItemDataValueById(vItem.mobId, 'mobName');
					if dataSet[i].mobName ~= nil then
						kAuction2:Wishlist_AddValidSearchFilter('mobName', dataSet[i].mobName, 'match', dataSet[i].mobName);
					else
						kAuction2:Wishlist_AddValidSearchFilter('mobName', nil, 'match', 'Empty');
					end
					dataSet[i].zoneId = vItem.zoneId;
					dataSet[i].zoneName = kAuction2:Item_GetItemDataValueById(vItem.zoneId, 'zoneName');
					if dataSet[i].zoneName ~= nil then
						kAuction2:Wishlist_AddValidSearchFilter('zoneName', dataSet[i].zoneName, 'match', dataSet[i].zoneName);
					else
						kAuction2:Wishlist_AddValidSearchFilter('zoneName', nil, 'match', 'Empty');
					end
					dataSet[i].playerCount = vItem.playerCount;
					if not vItem.difficulty then
						dataSet[i].difficulty = vItem.difficulty;
					else
						if type(vItem.difficulty) == 'number' then
							if vItem.difficulty <= 4 then
								dataSet[i].difficulty = vItem.difficulty;
							end
						end
					end
					if dataSet[i].difficulty ~= nil then
						kAuction2:Wishlist_AddValidSearchFilter('difficulty', dataSet[i].difficulty, 'match', dataSet[i].difficulty);
					else
						kAuction2:Wishlist_AddValidSearchFilter('difficulty', nil, 'match', 'Empty');
					end
				end
			end
			local slot = kAuction2:Item_GetEquipSlotNumberOfItem(v.id, 'formattedName');
			if slot then
				dataSet[i].equipSlot = slot;
				kAuction2:Wishlist_AddValidSearchFilter('equipSlot', dataSet[i].equipSlot, 'match', dataSet[i].equipSlot);
			else
				kAuction2:Wishlist_AddValidSearchFilter('equipSlot', nil, 'match', 'Empty');
			end
			-- Loop through Enabled Weight Scales
			for iWeight,vWeight in pairs(kAuction2.db.profile.weights) do
				if vWeight.enabled then -- Enabled
					if vWeight.defaultClass then
						if UnitClass("player") == vWeight.defaultClass then
							if vWeight.comparison then -- Compare to current slot item
								local iScore = kAuction2:Weight_GetItemScore(vWeight.id, v.id, true);
								if iScore then
									dataSet[i][vWeight.id] = iScore;
								end
							else -- Aggregate value					
								local iScore = kAuction2:Weight_GetItemScore(vWeight.id, v.id);
								if iScore then
									dataSet[i][vWeight.id] = iScore;
								end
							end
						end
					else
						if vWeight.comparison then -- Compare to current slot item
							local iScore = kAuction2:Weight_GetItemScore(vWeight.id, v.id, true);
							if iScore then
								dataSet[i][vWeight.id] = iScore;
							end
						else -- Aggregate value					
							local iScore = kAuction2:Weight_GetItemScore(vWeight.id, v.id);
							if iScore then
								dataSet[i][vWeight.id] = iScore;
							end
						end
					end
				end
			end
		end
	end
end
function kAuction2:Wishlist_UpdateFromCacheData(dataSet)
	if dataSet then
		for i,v in pairs(dataSet) do
			for iList,vList in pairs(kAuction2.db.profile.wishlists) do
				if vList.items then
					for iItem,vItem in pairs(vList.items) do
						if not vItem.level then
							if vItem.id == v.id and GetItemInfo(vItem.id) then
								local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(vItem.id);
								vItem.level = itemLevel;
								vItem.slot = kAuction2:Item_GetEquipSlotNumberOfItem(itemLink, 'formattedName');
							end
						end
					end
				end
			end
		end
	end
end
function kAuction2:Item_SendHyperlinkToChat(link)
	local activeWindow = ChatEdit_GetActiveWindow(); 
	if activeWindow then
		activeWindow:Insert(link); 
	else
		DEFAULT_CHAT_FRAME:AddMessage(link)
	end
end