local kAuction2 = _G.kAuction2
if not kAuction2 then
  error("kAuction2_Server requires kAuction2")
end
local L = kAuction2.L

local kAuction2_Server = kAuction2:NewModule("Server", "AceEvent-3.0", "AceHook-3.0")
kAuction2_Server:SetModuleType("custom")
kAuction2_Server:SetName(L["Server"])
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
--[[
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
]]











--- Add bid to existing auction.
-- @param sender Player name sending the bid
-- @localAuctionData Local auction data
-- @usage kAuction2_Server:AddBidToAuction("Kulldam", {{id=1234,item=123456}})
function kAuction2_Server:AddBidToAuction(sender, localAuctionData)
	if not kAuction2:IsServer() then
		return;
	end
	local auction = kAuction2:Client_GetAuctionById(localAuctionData.id);
	if auction then -- Matchin Auction found on server
		local bid = kAuction2:Client_GetBidOfAuctionFromName(auction, sender);
		if bid then -- Bid already exists, update
			bid.bestInSlot = localAuctionData.bestInSlot;
			bid.bidType = localAuctionData.bidType;
			bid.currentItemLink = localAuctionData.currentItemLink;
			bid.setBonus = localAuctionData.setBonus;
		else -- No bid exists for sender, create
			bid = {
				bestInSlot = localAuctionData.bestInSlot,
				bidType = localAuctionData.bidType,
				currentItemLink = localAuctionData.currentItemLink, 
				id = kAuction2_Server:GetUniqueBidId(),
				lootCouncilVoters = {},
				name = sender, 
				roll = math.random(1,kAuction2.db.profile.looting.rollMaximum),
				setBonus = localAuctionData.setBonus,
			};
			tinsert(auction.bids, bid);
		end
		kAuction2:SendCommunication("DataUpdate", kAuction2:Serialize("auction", auction))
	end
	auction = nil;
end
function kAuction2_Server:AddBidVote(sender, auction, bid)
	if not kAuction2:IsServer() then
		return;
	end
	local iAuction, iBid = kAuction2:Client_GetAuctionBidIndexByBidId(bid.id);
	if kAuction2.auctions[iAuction].bids[iBid] then
		if kAuction2:IsLootCouncilMember(kAuction2.auctions[iAuction], sender) then
			kAuction2:ClearLootCouncilVoteFromAuction(kAuction2.auctions[iAuction], sender);
			tinsert(kAuction2.auctions[iAuction].bids[iBid].lootCouncilVoters, sender);
		end
		kAuction2:SendCommunication("DataUpdate", kAuction2:Serialize("auction", kAuction2.auctions[iAuction]))
	end
end
function kAuction2_Server:AwardAuction(auction, winner)
	if not kAuction2:IsServer() then
		return;
	end
	if not auction.closed then
		return;
	end
	if winner then -- Assigned winner
		auction.winner = winner;
	end
	if auction.winner or auction.disenchant then
		-- Auto-assign via master loot
		local unit = kAuction2.roster:GetUnitObjectFromName(UnitName("player"))
		local corpseGuid = UnitGUID("target") -- NPC Looted
		if not corpseGuid then -- Else Container Looted
			corpseGuid = kAuction2.guids.lastObjectOpened;
		end	
		-- Check if autoML enabled, player is raid leader, player is ML, player is looting a corpse/object of matching corpseGuid of auction, 
		-- and auction has not been looted (ensures duplicate named items don't get autoassigned)
		if kAuction2.db.profile.looting.autoAssignIfMasterLoot and IsRaidLeader() and unit.ML and kAuction2.isLooting and corpseGuid == auction.corpseGuid and auction.looted == false then
			if #(auction.bids) == 0 then -- Disenchant
				auction.disenchant = true;
			end
			kAuction2:Debug("Server_AwardAuction, Activate MasterLoot", 1);
			-- Assign to winner
			if auction.winner then
				local booAwarded = false;
				for ci = 1, GetNumRaidMembers() do
					if (GetMasterLootCandidate(ci) == auction.winner) then
						for li = 1, GetNumLootItems() do
							if (LootSlotIsItem(li)) then
								local itemLink = GetLootSlotLink(li);
								if itemLink == auction.itemLink then
									GiveMasterLoot(li, ci);
									booAwarded = true;		
									auction.awarded = true;		
									auction.looted = true;				
								end
							end
						end
					end
				end
				if booAwarded == false then
					kAuction2:Print(ChatFrame1, "Master Loot Auto-Assignment failed for " .. auction.winner .. " for item " .. auction.itemLink ..".  Not in range or valid candidate.")
				end
			elseif auction.disenchant then
				local disenchanterUnit = kAuction2:GetEnchanterInRaidRosterObject();
				if disenchanterUnit then -- DEer found in raid
					-- Assign to Disenchanter
					local booAwarded = false;
					for ci = 1, GetNumRaidMembers() do
						if (GetMasterLootCandidate(ci) == disenchanterUnit.name) then
							for li = 1, GetNumLootItems() do
								if (LootSlotIsItem(li)) then
									local itemLink = GetLootSlotLink(li);
									if itemLink == auction.itemLink then
										GiveMasterLoot(li, ci);		
										auction.awarded = true;		
										auction.looted = true;						
									end
								end
							end
						end
					end	
					if booAwarded == false then
						kAuction2:Print(ChatFrame1, "Master Loot Auto-Assignment Disenchantment failed for " .. disenchanterUnit.name .. " for item " .. auction.itemLink ..".  Not in range or valid candidate.")
					end
				else	
					kAuction2:Print(ChatFrame1, "Master Loot Auto-Assignment Disenchantment failed, no valid disenchanter found in raid.")
				end
			end
		end
		auction.awarded = true;
		auction.looted = true;
		kAuction2:SendCommunication("DataUpdate", kAuction2:Serialize("auction", auction));
		if auction.winner then
			kAuction2:Debug("auctionwinner: " .. auction.winner, 1);
			SendChatMessage(kAuction2.const.chatPrefix.."Auto-Response: Congratulations, you are the auction winner for " .. auction.itemLink .. "!", "WHISPER", nil, auction.winner);
			kAuction2:SendCommunication("AuctionWinner", auction);
		end
	end
end
function kAuction2_Server:WhisperAuctionToRaidRoster(itemLink)
	kAuction2.roster:ScanFullRoster();
	for i = 1, GetNumRaidMembers() do
		local objMember = kAuction2.roster:GetUnitObjectFromName(GetRaidRosterInfo(i));
		if objMember then
			if objMember.online then
				if not (objMember.name == (UnitName("player"))) then
					SendChatMessage(kAuction2.const.chatPrefix.."Auto-Generated: An auction has been created for "..itemLink ..".  To bid, /whisper "..UnitName("player").." with the itemlink and appropriate keywords.  For keyword help, /whisper "..UnitName("player").." ka help.", "WHISPER", nil, objMember.name);
				end
			end
		end
	end
end
function kAuction2_Server:AuctionItem(id, corpseGuid, corpseName)
	if not kAuction2:IsServer() or not kAuction2.isActiveRaid then
		kAuction2:Debug("Not active raid.", 1);
		return;
	end
	local _, itemLink = GetItemInfo(id);
	-- Check if rarity requirements are met
	local _, _, rarity = GetItemInfo(itemLink);
	if not rarity then return end
	if rarity < kAuction2.db.profile.looting.rarityThreshold then
		return;
	end
	-- Is item in blacklist?
	local booItemInBlacklist = false
	local strItemName = GetItemInfo(itemLink)
	for i,val in pairs(kAuction2.db.profile.items.blackList) do
		if strItemName == val then
			booItemInBlacklist = true
		end
	end
	if booItemInBlacklist then
		kAuction2:Debug("FUNC: Server_AuctionItem, Item in blacklist: " .. strItemName, 3)
		return; 
	end
	local currentItemLink = false;
	local whitelistData = kAuction2:Item_GetItemWhitelistData(itemLink) or kAuction2:Item_GetItemTypeWhitelistData(itemLink) or {};
	if whitelistData.name then
		kAuction2:Debug("FUNC: Create auction, whitelist Data found, name: " .. whitelistData.name, 1);
	end
	if IsEquippableItem(itemLink) or whitelistData.currentItemSlot then
		if kAuction2.db.profile.bidding.autoPopulateCurrentItem then
			local slotItemLink = GetInventoryItemLink("player", whitelistData.currentItemSlot or kAuction2:Item_GetEquipSlotNumberOfItem(itemLink));
			if slotItemLink then
				currentItemLink = slotItemLink;
				kAuction2:Debug("FUNC: Create auction, slotItemLink: " .. slotItemLink, 1);
			end
		end
	end
	local id = kAuction2_Server:GetUniqueAuctionId();
	local councilMembers = {};
	for iCouncil,vCouncil in pairs(kAuction2.db.profile.looting.councilMembers) do
		if kAuction2.roster:GetUnitIDFromName(vCouncil) then
			tinsert(councilMembers, vCouncil);
		end
	end
	tinsert(kAuction2.auctions, {
		auctionType = whitelistData.auctionType or kAuction2.db.profile.looting.auctionType,
		auctionCloseDelay = kAuction2.db.profile.looting.auctionCloseDelay,
		auctionCloseVoteDuration = kAuction2.db.profile.looting.auctionCloseVoteDuration,
		awarded = false,
		bids = {},
		closed = false, 
		councilMembers = councilMembers,
		corpseGuid = corpseGuid,
		corpseName = corpseName,
		currentItemSlot = whitelistData.currentItemSlot or kAuction2:Item_GetEquipSlotNumberOfItem(itemLink),
		dateTime = date("%m/%d/%y %H:%M:%S"),
		duration = kAuction2.db.profile.looting.auctionDuration, 
		id = id, 
		itemLink = itemLink, 
		looted = false,
		seedTime = time(), 
		visiblePublicBidCurrentItems = kAuction2.db.profile.looting.visiblePublicBidCurrentItems,
		visiblePublicBidRolls = kAuction2.db.profile.looting.visiblePublicBidRolls,
		visiblePublicBidVoters = kAuction2.db.profile.looting.visiblePublicBidVoters,
		visiblePublicDetails = kAuction2.db.profile.looting.visiblePublicDetails,
		winner = false});
	tinsert(kAuction2.localAuctionData, {
		bestInSlot = false,
		bid = false, 
		bidType = false, 
		currentItemLink = currentItemLink, 
		id = id,
		localStartTime = time(), 
		setBonus = false,
	});		
	-- Send out auction Whisper Bid messages
	if kAuction2.db.profile.looting.auctionWhisperBidEnabled then
		kAuction2_Server:WhisperAuctionToRaidRoster(itemLink);
	end
	if #(kAuction2.auctions) > 0 and kAuction2.db.profile.looting.displayFirstOpenAuction == true then
		FauxScrollFrame_SetOffset(kAuction2MainFrameMainScrollContainerScrollFrame, kAuction2:GetFirstOpenAuctionIndex()-1);
	end
	-- Visible main frame
	kAuction2.db.profile.gui.frames.main.visible = true;
	kAuction2.db.profile.gui.frames.bids.visible = true;
	kAuction2:Gui_HookFrameRefreshUpdate();
	-- SendComm
	kAuction2:SendCommunication("Auction", kAuction2.auctions[#(kAuction2.auctions)])
	kAuction2:ScheduleTimer(Server_OnAuctionExpire, kAuction2.auctions[#(kAuction2.auctions)].duration + kAuction2.db.profile.looting.auctionCloseDelay, #(kAuction2.auctions));
	kAuction2:ScheduleTimer("Gui_HookFrameRefreshUpdate", kAuction2.db.profile.looting.auctionDuration + kAuction2.db.profile.looting.auctionCloseVoteDuration + kAuction2.db.profile.looting.auctionCloseDelay);
	kAuction2:Debug("FUNC: Server_AuctionItem: Item: " .. itemLink .. ", corpse: " .. corpseGuid, 1);
	-- Check if wishlist requires auto-bid
	if kAuction2:Wishlist_IsEnabled() then
		local oMatches = kAuction2:Wishlist_GetWishlistItemMatches(kAuction2:Item_GetItemIdFromItemLink(itemLink));
		if oMatches then
			-- Check for priority item
			local wishlistItem = kAuction2:Wishlist_GetHighestPriorityItemFromSet(oMatches);
			if wishlistItem then
				if wishlistItem.autoBid == true then
					kAuction2:Gui_AuctionBidButtonOnClick(kAuction2.auctions[#kAuction2.auctions], wishlistItem.bidType, wishlistItem.bestInSlot, wishlistItem.setBonus);				
					-- Auto bid, check if alert
					if wishlistItem.alert == true then
						local sBidType;
						local sBestInSlot;
						local sSetBonus;
						if wishlistItem.bestInSlot then
							sBestInSlot = "|cFF"..kAuction2:RGBToHex(0,255,0) .. "Yes|r";
						else
							sBestInSlot = "|cFF"..kAuction2:RGBToHex(200,00,0) .. "No|r";
						end
						if wishlistItem.setBonus then
							sSetBonus = "|cFF"..kAuction2:RGBToHex(0,255,0) .. "Yes|r";
						else
							sSetBonus = "|cFF"..kAuction2:RGBToHex(200,00,0) .. "No|r";
						end
						if wishlistItem.bidType == 'normal' then
							sBidType = "|cFF"..kAuction2:RGBToHex(0,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
						elseif wishlistItem.bidType == 'offspec' then
							sBidType = "|cFF"..kAuction2:RGBToHex(255,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
						elseif wishlistItem.bidType == 'rot' then
							sBidType = "|cFF"..kAuction2:RGBToHex(210,0,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
						end
						StaticPopupDialogs["kAuction2Popup_PromptAutoBid_"..wishlistItem.wishlistId] = {
							text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|n|n"..
							"An automatic " .. sBidType .. " bid has been entered for the recently created auction of ".. itemLink .. " due to your wishlist of this item with the following settings:|n|n" ..
							"Wishlist: |cFF"..kAuction2:RGBToHex(255,150,0) .. kAuction2:Wishlist_GetNameById(wishlistItem.wishlistId) .. "|r|n" ..
							"Bid Type: " .. sBidType .. "|n" ..
							"Best in Slot: " .. sBestInSlot .. "|n" ..
							"Set Bonus: " .. sSetBonus .. "|n|n",
							"Would you like to keep or cancel your bid?",
							OnAccept = function()
								return;
							end,
							button1 = "Keep Bid",
							button2 = "Cancel Bid",
							OnCancel = function()
								kAuction2:Gui_AuctionBidButtonOnClick(kAuction2.auctions[#kAuction2.auctions], 'none');				
							end,
							timeout = kAuction2.auctions[#(kAuction2.auctions)].duration,
							whileDead = 1,
							hideOnEscape = 1,
							hasEditBox = false,
							showAlert = true,
						};	
						StaticPopup_Show("kAuction2Popup_PromptAutoBid_"..wishlistItem.wishlistId);
					end
				elseif wishlistItem.alert == true then
					local sBidType;
					local sBestInSlot;
					local sSetBonus;
					if wishlistItem.bestInSlot then
						sBestInSlot = "|cFF"..kAuction2:RGBToHex(0,255,0) .. "Yes|r";
					else
						sBestInSlot = "|cFF"..kAuction2:RGBToHex(200,00,0) .. "No|r";
					end
					if wishlistItem.setBonus then
						sSetBonus = "|cFF"..kAuction2:RGBToHex(0,255,0) .. "Yes|r";
					else
						sSetBonus = "|cFF"..kAuction2:RGBToHex(200,00,0) .. "No|r";
					end
					if wishlistItem.bidType == 'normal' then
						sBidType = "|cFF"..kAuction2:RGBToHex(0,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
					elseif wishlistItem.bidType == 'offspec' then
						sBidType = "|cFF"..kAuction2:RGBToHex(255,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
					elseif wishlistItem.bidType == 'rot' then
						sBidType = "|cFF"..kAuction2:RGBToHex(210,0,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
					end
					StaticPopupDialogs["kAuction2Popup_PromptAutoBid_"..wishlistItem.wishlistId] = {
						text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|n|n"..
						"An auction has been detected for the following item found in your wishlists:|n" ..
						itemLink ..
						"|n|nWould you like to enter a bid based on your wishlist settings as seen below?|n|n" ..
						"Wishlist: |cFF"..kAuction2:RGBToHex(255,150,0) .. kAuction2:Wishlist_GetNameById(wishlistItem.wishlistId) .. "|r|n" ..
						"Bid Type: " .. sBidType .. "|n" ..
						"Best in Slot: " .. sBestInSlot .. "|n" ..
						"Set Bonus: " .. sSetBonus .. "|n",
						OnAccept = function()
							kAuction2:Gui_AuctionBidButtonOnClick(kAuction2.auctions[#kAuction2.auctions], wishlistItem.bidType, wishlistItem.bestInSlot, wishlistItem.setBonus);
						end,
						button1 = "Bid",
						button2 = "No Thanks",
						OnCancel = function()
							return;
						end,
						timeout = kAuction2.auctions[#(kAuction2.auctions)].duration,
						whileDead = 1,
						hideOnEscape = 1,
						hasEditBox = false,
						showAlert = true,
					};	
					StaticPopup_Show("kAuction2Popup_PromptAutoBid_"..wishlistItem.wishlistId);
				end
			end
		end
	end
end
function kAuction2_Server:GetRandomItemId()
	local id;
	local itemLink;	
	local itemId = nil;
	local iCounter = 0;
	local COUNTER_MAX = 5000;
	while itemId == nil do
		matchFound = false;
		local iSlot = random(1,19);
		itemId = kAuction2:Item_GetItemIdFromItemLink(GetInventoryItemLink("player",iSlot));
		iCounter = iCounter + 1;
		if iCounter >= COUNTER_MAX then
			return nil;
		end
	end
	return itemId;
end
function kAuction2_Server:CreateTestAuction()
	if not kAuction2:IsServer() then
		return;
	end
	-- Create test auction
	kAuction2_Server:AuctionItem(kAuction2_Server:GetRandomItemId(), kAuction2_Server:GetUniqueAuctionId(), "test corpse");
end
function kAuction2_Server:IsPreviousRaidClosed() -- Not finished
	if not kAuction2:IsServer() then
		return;
	end
	local sXml = kAuction2_Server:GetRaidXmlString();
	if kAuction2.raidStartTime and kAuction2.currentZone then
		local booFound = false;
		if #(kAuction2.raidDb.global.raids) > 0 then
			if not kAuction2.raidDb.global.raids[#kAuction2.raidDb.global.raids].endTime then
				-- Previous raid has no closure date, prompt to continue
				
			end
		end
		for i,raid in pairs(kAuction2.raidDb.global.raids) do
			-- Check for existing entry matching this zone without end datetime
			if raid.startTime == kAuction2.raidStartTime then
				-- Update existing entry
				kAuction2.raidDb.global.raids[i].xml = sXml;
				booFound = true;
			end
		end
		if booFound == false then
			tinsert(kAuction2.raidDb.global.raids, {startTime = kAuction2.raidStartTime, xml = sXml});
		end
	end
end
function kAuction2_Server:GetLootCouncilMemberCount()
	local iCount = 0;
	local booRaidLeaderInList = false;
	for i,member in pairs(kAuction2.db.profile.looting.councilMembers) do
		local objMember = kAuction2.roster:GetUnitObjectFromName(member);
		if objMember then
			iCount = iCount + 1;
			if objMember.rank == 2 then
				booRaidLeaderInList = true;
			end
		end
	end
	if booRaidLeaderInList == false then
		iCount = iCount + 1;
	end
	if iCount > 0 then
		return iCount;
	else
		return nil;
	end
end
function kAuction2_Server:GetAuctionByItem(item,checkWinner)
	if not kAuction2:IsServer() then
		return;
	end
	local itemLink = item;
	if type(tonumber(item)) == "number" then -- ItemId
		if GetItemInfo(tonumber(item)) then
			itemLink = kAuction2:Item_GetItemLinkFromItemId(item);
		end
	end
	local rAuction = nil;
	for i,auction in pairs(kAuction2.auctions) do
		kAuction2:Debug("FUNC: Server_GetAuctionIdByItem, Auction Link: " .. auction.itemLink .. ", searchlink: " .. itemLink, 3);		
		if tonumber(kAuction2:Item_GetItemIdFromItemLink(auction.itemLink)) == tonumber(kAuction2:Item_GetItemIdFromItemLink(itemLink)) then
			if checkWinner then
				if not auction.winner then
					kAuction2:Debug("FUNC: Server_GetAuctionIdByItem, Auction Id Found: " .. auction.id, 3);
					rAuction = auction;
				end
			else
				kAuction2:Debug("FUNC: Server_GetAuctionIdByItem, Auction Id Found: " .. auction.id, 3);
				rAuction = auction;
			end
		end
	end	
	return rAuction;
end
function kAuction2_Server:GetRaidRoster()
	if not kAuction2:IsServer() then
		return;
	end
	local roster = {};
	kAuction2.roster:ScanFullRoster();
	for i = 1, GetNumRaidMembers() do
		local objMember = kAuction2.roster:GetUnitObjectFromName(GetRaidRosterInfo(i));
		if objMember then
			if objMember.online then
				local class;
				local s1, s2 = strsplit(" ", objMember.class);
				class = strupper(strsub(s1, 1, 1)) .. strlower(strsub(s1, 2));
				if s2 then
					class = class .. " " .. strupper(strsub(s2, 1, 1)) .. strlower(strsub(s2, 2));
				end
				tinsert(roster, {name = objMember.name, class = class});
			end
		end
	end
	return roster;
end
function kAuction2_Server:GetUniqueAuctionId()
	local newId
	local isValidId = false;
	while isValidId == false do
		matchFound = false;
		newId = (math.random(0,2147483647) * -1);
		for i,val in pairs(kAuction2.auctions) do
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
function kAuction2_Server:GetUniqueBidId()
	local newId
	local isValidId = false;
	while isValidId == false do
		matchFound = false;
		newId = (math.random(0,2147483647) * -1);
		for iAuction,vAuction in pairs(kAuction2.auctions) do
			for iBid,vBid in pairs(vAuction.bids) do
				if vBid.id == newId then
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
function kAuction2_Server:HasCorpseBeenAuctioned(guid)
	local booWasAuctioned = false;
	for i,val in pairs(kAuction2.guids.wasAuctioned) do
		if val == guid then
			booWasAuctioned = true;
		end
	end
	if booWasAuctioned then
		kAuction2:Debug("FUNC: Server_HasCorpseBeenAuctioned, TRUE", 3)		
	else
		kAuction2:Debug("FUNC: Server_HasCorpseBeenAuctioned, FALSE", 3)			
	end
	return booWasAuctioned;
end
function kAuction2_Server:InitializeCouncilMemberList()
	local booPlayerFound = false;
	local tempCouncilMembers = {};
	for iCouncil,vCouncil in pairs(kAuction2.db.profile.looting.councilMembers) do
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
-- Fires when auction timer ends, 
function Server_OnAuctionExpire(iAuction)
	if not kAuction2:IsServer() then
		return;
	end
	if kAuction2.auctions[iAuction] then
		kAuction2:ScheduleTimer(kAuction2:MainFrameScrollUpdate(), 0.5);
		kAuction2:ScheduleTimer(kAuction2:BidsFrameScrollUpdate(), 0.5);
		kAuction2.auctions[iAuction].closed = true;
		-- No bids, auto DE
		if #kAuction2.auctions[iAuction].bids == 0 then
			kAuction2.auctions[iAuction].disenchant = true;
			kAuction2_Server:AwardAuction(kAuction2.auctions[iAuction]);
		elseif #kAuction2.auctions[iAuction].bids == 1 then
			for i,v in pairs(kAuction2.auctions[iAuction].bids) do
				kAuction2_Server:AwardAuction(kAuction2.auctions[iAuction], v.name);				
			end
		elseif kAuction2.db.profile.looting.autoAwardRandomAuctions then
			kAuction2:ScheduleTimer("DetermineRandomAuctionWinner", kAuction2.db.profile.looting.auctionCloseDelay, iAuction);	
			kAuction2:ScheduleTimer("Server_AwardAuction", kAuction2.db.profile.looting.auctionCloseDelay + 1, kAuction2.auctions[iAuction]);	
		end
	end
end
function kAuction2_Server:RaidHasServerReceived(sender)
	if not kAuction2:IsServer() then
		return;
	end
	kAuction2:Debug("FUNC: Server_RaidHasServerReceived, request sender = "..sender..", SendComm(RaidServer).", 1);
	kAuction2:SendCommunication("RaidServer", nil);
end
function kAuction2_Server:RemoveBidFromAuction(sender, auction)
	if not kAuction2:IsServer() then
		return;
	end
	local iAuction = kAuction2:Client_GetAuctionIndexByAuctionId(auction.id);
	if kAuction2.auctions[iAuction] then
		for i,bid in pairs(kAuction2.auctions[iAuction].bids) do
			if bid.name == sender then
				kAuction2:Debug("FUNC: Server_RemoveBidFromAuction, REMOVING BID: " .. sender, 1);
				tremove(kAuction2.auctions[iAuction].bids, i);
				kAuction2:SendCommunication("DataUpdate", kAuction2:Serialize("auction", kAuction2.auctions[iAuction]))
			end
		end
	end
end
function kAuction2_Server:RemoveBidVote(sender, auction, bid)
	if not kAuction2:IsServer() then
		return;
	end
	local localBid = kAuction2:Client_GetBidById(bid.id);
	local localAuction = kAuction2:Client_GetAuctionById(auction.id);
	if localBid then -- Matching Auction found on server
		if kAuction2:IsLootCouncilMember(localAuction, sender) then
			kAuction2:ClearLootCouncilVoteFromAuction(localAuction, sender);
		end
		kAuction2:SendCommunication("DataUpdate", kAuction2:Serialize("auction", localAuction))
	end
end
function kAuction2_Server:SetCorpseAsAuctioned(guid)
	if kAuction2_Server:HasCorpseBeenAuctioned(guid) == false then
		tinsert(kAuction2.guids.wasAuctioned, guid);
		return true;		
	end
	return nil;
end
function kAuction2_Server:ConfirmStartRaidTracking()
	if not kAuction2:IsServer() then
		kAuction2:Print("Not registered as Server, cannot start raid tracking.");
		return;
	end
	StaticPopup_Show("kAuction2Popup_StartRaidTracking");							
end
function kAuction2_Server:ConfirmStopRaidTracking()
	if not kAuction2:IsServer() then
		kAuction2:Print("Not registered as Server, cannot stop raid tracking.");
		return;
	end
	StaticPopup_Show("kAuction2Popup_StopRaidTracking");							
end
function kAuction2_Server:IsInValidRaidZone()
	if not kAuction2:IsServer() then
		return;
	end
	kAuction2.currentZone = GetRealZoneText();
	for iZone,vZone in pairs(kAuction2.db.profile.zones.validZones) do
		if kAuction2.currentZone == vZone then
			return true;
		end
	end
	return false;
end
function kAuction2_Server:RequestRaidAuraCancel(id)
	if not kAuction2:IsServer() then
		return;
	end
	if not type(id) == "number" then return end
	if not GetSpellInfo(tonumber(id)) then return end
	-- Valid, send request
	kAuction2:SendCommunication("RequestAuraCancel", tonumber(id));
end
function kAuction2_Server:StartRaidTracking()
	if not kAuction2:IsServer() then
		return;
	end
	kAuction2.enabled = true;
	kAuction2.isActiveRaid = true;
	kAuction2.actors = {};
	kAuction2.raidStartTime = date("%m/%d/%y %H:%M:%S");
	kAuction2.raidStartTick = time();
	kAuction2.raidZone = GetRealZoneText();
	kAuction2.rosterUpdateTimer = kAuction2:ScheduleRepeatingTimer("Server_UpdateRaidRoster", kAuction2.const.raid.presenceTick);
	-- Check if previous raid exists for this zone
	
	-- Create raid entry
	kAuction2:Debug("FUNC: Server_StartRaidtracking", 1);
end
function kAuction2_Server:StopRaidTracking()
	if not kAuction2:IsServer() then
		return;
	end
	kAuction2.enabled = false;
	kAuction2.isActiveRaid = false;
	kAuction2.raidEndTime = date("%m/%d/%y %H:%M:%S");
	kAuction2.raidDuration = time() - kAuction2.raidStartTick;
	-- Final Xml DB Update
	kAuction2_Server:UpdateRaidDb();
	-- Create raid xml
	StaticPopupDialogs["kAuction2Popup_GetRaidXmlString"] = {
		text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|nCopy raid Xml export string below.",
		OnAccept = function()
			return
		end,
		button1 = "Done",
		button2 = "Cancel",
		OnCancel = function()
			return
		end,
		OnShow = function(self)
			self.editBox:SetText(kAuction2_Server:GetRaidXmlString())
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		hasEditBox = 1,
	};	
	StaticPopup_Show("kAuction2Popup_GetRaidXmlString");
	kAuction2:CancelTimer(kAuction2.rosterUpdateTimer);
	kAuction2.actors = {};
	kAuction2:SendCommunication("RaidEnd");
	kAuction2:Debug("FUNC: Server_StopRaidtracking", 1);
end
function kAuction2_Server:UpdateRaidDb()
	if not kAuction2:IsServer() then
		return;
	end
	-- Update raid Duration
	kAuction2.raidDuration = time() - kAuction2.raidStartTick;
	local sXml = kAuction2_Server:GetRaidXmlString();
	if sXml and kAuction2.raidStartTime then
		local booFound = false;
		if kAuction2.raidDb.global.raids then
			for i,raid in pairs(kAuction2.raidDb.global.raids) do
				-- Check for existing entry
				if raid.startTime == kAuction2.raidStartTime then
					-- Update existing entry
					kAuction2.raidDb.global.raids[i].xml = sXml;
					booFound = true;
				end
			end
		end
		if booFound == false then
			local tInsert = {startTime = kAuction2.raidStartTime, xml = sXml};
			if kAuction2.raidEndTime then
				tInsert.endTime = kAuction2.raidEndTime;
			end
			if not kAuction2.raidDb.global.raids then
				kAuction2.raidDb.global.raids = {};
			end
			tinsert(kAuction2.raidDb.global.raids, tInsert);
		end
	end
end
function kAuction2_Server:GetRaidXmlString()
	if not kAuction2:IsServer() then
		return;
	end
	local xFull = '<kAuction2><raid>';
	local xStartDate = '<startDate>'..kAuction2.raidStartTime..'</startDate>';
	local xEndDate = '<endDate>';	
	if kAuction2.raidEndTime then
		xEndDate = xEndDate .. kAuction2.raidEndTime;
	end
	xEndDate = xEndDate .. '</endDate>';
	local xDuration = '<duration>'
	if kAuction2.raidDuration then
		xDuration = xDuration .. kAuction2.raidDuration;
	end
	xDuration = xDuration .. '</duration>';
	local xZone = '<zone>'..kAuction2.raidZone..'</zone>';
	local xItem = "";
	local xItems = "";
	local xBids = "";
	if #kAuction2.auctions > 0 then
		-- START <items>
		xItems = '<items>';
		for i,auction in pairs(kAuction2.auctions) do
			local found, _, itemString = string.find(auction.itemLink, '^|c%x+|H(.+)|h%[.*%]')
			local _,itemId = strsplit(':', itemString);
			local itemName = GetItemInfo(auction.itemLink);
			xItem = '<item>';
			if auction.corpseName then
				xItem = xItem .. '<corpseName>' .. auction.corpseName .. '</corpseName>';
			end
			xItem = xItem .. '<dateTime>' .. auction.dateTime .. '</dateTime>';
			if auction.disenchant then
				xItem = xItem .. '<disenchant>True</disenchant>';
			end
			if auction.auctionType then
				if auction.auctionType == 1 then
					xItem = xItem .. '<auctionType>random</auctionType>';					
				elseif auction.auctionType == 2 then
					xItem = xItem .. '<auctionType>council</auctionType>';					
				end
			end
			xItem = xItem .. '<itemId>' .. itemId .. '</itemId>';
			xItem = xItem .. '<name>' .. itemName .. '</name>';
			if auction.bids and #auction.bids > 0 then
				xBids = '<bids>';
				for iBid,vBid in pairs(auction.bids) do
					xBid = '<bid>';
					if vBid.bidType then 
						xBid = xBid .. '<bidType>' .. vBid.bidType .. '</bidType>';
					end
					if vBid.currentItemLink then
						local bFound, _, bItemString = string.find(vBid.currentItemLink, '^|c%x+|H(.+)|h%[.*%]');
						local _,bItemId = strsplit(':', bItemString);
						local bItemName = GetItemInfo(vBid.currentItemLink);					
						xBid = xBid .. '<currentItemId>' .. bItemId .. '</currentItemId>';
						if bItemName then
							xBid = xBid .. '<currentItemName>' .. bItemName .. '</currentItemName>';
						end
					end
					if vBid.id then 
						xBid = xBid .. '<id>' .. vBid.id .. '</id>';
					end
					if vBid.name then 
						xBid = xBid .. '<name>' .. vBid.name .. '</name>';
					end
					if vBid.roll then
						xBid = xBid .. '<roll>' .. vBid.roll .. '</roll>';
					end
					if vBid.lootCouncilVoters and #vBid.lootCouncilVoters  > 0 then
						local xBidVoters = '<voters>';						
						for iVoters,vName in pairs(vBid.lootCouncilVoters) do
							xBidVoters = xBidVoters .. '<name>' .. vName .. '</name>';			
						end
						xBidVoters = xBidVoters .. '</voters>';
						xBid = xBid .. xBidVoters;
					end
					-- Add <bid> to <bids>
					xBids = xBids .. xBid .. '</bid>';
				end
				-- Add <bids> to <item>
				xItem = xItem .. xBids .. '</bids>';				
			end
			if auction.winner then 
				xItem = xItem .. '<winner>' .. auction.winner .. '</winner>';
				local bidType = nil;
				for ibid,vBid in pairs(auction.bids) do
					if vBid.name == auction.winner then
						bidType = vBid.bidType;
					end
				end
				if bidType then
					xItem = xItem .. '<bidType>' .. bidType .. '</bidType>';	
				end
			end
			-- Loot council member list
			if auction.councilMembers and #auction.councilMembers  > 0 then
				local xCouncilMembers = '<councilMembers>';						
				for iCouncil,vName in pairs(auction.councilMembers) do
					xCouncilMembers = xCouncilMembers .. '<name>' .. vName .. '</name>';			
				end
				xCouncilMembers = xCouncilMembers .. '</councilMembers>';
				-- Add <councilMembers> to <item>
				xItem = xItem .. xCouncilMembers;
			end
			xItem = xItem .. '</item>';
			-- Add item to Items list
			xItems = xItems .. xItem;
		end
		xItems = xItems .. '</items>';
		-- END <items>
	end
	-- START <actors>
	local xActor, xActors;
	xActors = '<actors>';
	for name,actor in pairs(kAuction2.actors) do
		local presence = 1;
		if actor.presence + kAuction2.const.raid.presenceTick < kAuction2.raidDuration then
			presence = actor.presence / kAuction2.raidDuration;
		end
		xActor = '<actor>';
		xActor = xActor .. '<class>' .. actor.class .. '</class>';
		xActor = xActor .. '<name>' .. name .. '</name>';
		xActor = xActor .. '<presence>' .. presence .. '</presence>';
		xActor = xActor .. '</actor>';
		-- Add actor to Items list
		xActors = xActors .. xActor;
	end
	xActors = xActors .. '</actors>';
	-- END <actors>
	xFull = xFull .. xStartDate .. xEndDate .. xZone .. xDuration .. xActors .. xItems .. '</raid></kAuction2>';
	return xFull;
end
function kAuction2_Server:UpdateRaidRoster()
	kAuction2.roster:ScanFullRoster();
	for i = 1, GetNumRaidMembers() do
		local objMember = kAuction2.roster:GetUnitObjectFromName(GetRaidRosterInfo(i));
		if objMember then
			if objMember.online then
				local class;
				local s1, s2 = strsplit(" ", objMember.class);
				class = strupper(strsub(s1, 1, 1)) .. strlower(strsub(s1, 2));
				if s2 then
					class = class .. " " .. strupper(strsub(s2, 1, 1)) .. strlower(strsub(s2, 2));
				end
				if kAuction2.actors[objMember.name] then
					kAuction2.actors[objMember.name].presence = kAuction2.actors[objMember.name].presence + kAuction2.const.raid.presenceTick;
				else -- new
					kAuction2.actors[objMember.name] = {class = class, presence = kAuction2.const.raid.presenceTick};
				end
			end
		end
	end
end
function kAuction2_Server:VersionCheck(outputResult)
	if not kAuction2:IsServer() then
		return;
	end
	for i=1,GetNumRaidMembers() do
		kAuction2.versions[GetRaidRosterInfo(i)] = false;
	end
	if outputResult then
		kAuction2:ScheduleTimer("Server_VerifyVersions", 6, outputResult);
	else
		kAuction2:ScheduleTimer("Server_VerifyVersions", 6);
	end
	kAuction2:SendCommunication("VersionRequest", kAuction2.version)
end
function kAuction2_Server:VersionReceived(sender, version)
	if not kAuction2:IsServer() then
		return;
	end
	kAuction2.versions[sender] = version;
	kAuction2:Debug("FUNC: Server_VersionReceived sender: "..sender.. ", version: " .. version,1);
	kAuction2_Server:VerifyVersions();
end
function kAuction2_Server:VerifyVersions(outputResult)
	if not kAuction2:IsServer() then
		return;
	end
	local booIncompatibleFound = false;
	for name,version in pairs(kAuction2.versions) do
		if version == false then
			if outputResult then
				kAuction2:Print("|cFF"..kAuction2:RGBToHex(255,0,0).."No kAuction2 Install Found|r: " .. name);
			end
			booIncompatibleFound = true;
		elseif version < kAuction2.version then
			booIncompatibleFound = true;
			if version < kAuction2.minRequiredVersion then
				if outputResult then
					kAuction2:Print("|cFF"..kAuction2:RGBToHex(255,0,0).."Incompatible Version|r: " .. name .. " [" .. version .. "]");
				end
				kAuction2:SendCommunication("VersionInvalid", kAuction2:Serialize(name, kAuction2.minRequiredVersion, kAuction2.version));
			else
				if outputResult then
					kAuction2:Print("|cFF"..kAuction2:RGBToHex(255,255,0).."Out of Date Version|r: " .. name .. " [" .. version .. "]");
				end
			end
		end
	end
	if booIncompatibleFound == false then
		if outputResult then
			kAuction2:Print("|cFF"..kAuction2:RGBToHex(0,255,0).."All Users Compatible|r");
		end
	end
end