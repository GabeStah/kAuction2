-- Author      : Gabe
-- Create Date : 2/15/2009 6:53:22 PM
-- Purpose: New auction sent by Server, add to client auction list
function kAuction2:Client_AuctionReceived(auction)
	if not kAuction2:Client_DoesAuctionExist(auction.id) then
		local currentItemLink = false;
		if auction.currentItemSlot then
			if kAuction2.db.profile.bidding.autoPopulateCurrentItem then
				local slotItemLink = GetInventoryItemLink("player", auction.currentItemSlot);
				if slotItemLink then
					currentItemLink = slotItemLink;
				end
			end
		end
		tinsert(kAuction2.auctions, auction); -- Add to global auction list
		tinsert(kAuction2.localAuctionData, { -- Update local Auction data
			bestInSlot = false,
			bid = false, 
			bidType = false,
			currentItemLink = currentItemLink, 
			id = auction.id,
			localStartTime = time(), 
			setBonus = false,
		});
		kAuction2:Gui_HookFrameRefreshUpdate();
		kAuction2:Gui_TriggerEffectsAuctionReceived();
		if kAuction2.db.profile.bidding.auctionReceivedTextAlert == 2 then
			kAuction2:Print("|cFF"..kAuction2:RGBToHex(100,255,0).."New Auction Received|r -- Item "..auction.itemLink);
		end
		if #(kAuction2.auctions) > 0 and kAuction2.db.profile.looting.displayFirstOpenAuction == true then
			FauxScrollFrame_SetOffset(kAuction2MainFrameMainScrollContainerScrollFrame, kAuction2:GetFirstOpenAuctionIndex()-1);
		end
		kAuction2.db.profile.gui.frames.bids.visible = true;
		kAuction2.db.profile.gui.frames.main.visible = true;
		kAuction2:Gui_HookFrameRefreshUpdate();
		kAuction2:ScheduleTimer("Gui_HookFrameRefreshUpdate", auction.duration + auction.auctionCloseVoteDuration + auction.auctionCloseDelay);
		-- Check if auto-remove auction is enabled and NOT server
		if kAuction2:IsServer() then
			return;
		else
			if kAuction2.db.profile.gui.frames.main.autoRemoveAuctions then
				kAuction2:Threading_CreateTimer("autoRemoveAuction_"..auction.id,function()
					kAuction2:Gui_AuctionCloseButtonOnClick(auction);
					kAuction2:Threading_StopTimer("autoRemoveAuction_"..auction.id);
				end, auction.duration + auction.auctionCloseVoteDuration + auction.auctionCloseDelay + kAuction2.db.profile.gui.frames.main.autoRemoveAuctionsDelay,false);
				kAuction2:Threading_StartTimer("autoRemoveAuction_"..auction.id);			
			end
		end	
		-- Check if wishlist requires auto-bid
		if kAuction2:Wishlist_IsEnabled() then
			local oMatches = kAuction2:Wishlist_GetWishlistItemMatches(kAuction2:Item_GetItemIdFromItemLink(auction.itemLink));
			if oMatches then
				-- Check for priority item
				local wishlistItem = kAuction2:Wishlist_GetHighestPriorityItemFromSet(oMatches);
				if wishlistItem then
					if wishlistItem.autoBid == true then
						kAuction2:Gui_AuctionBidButtonOnClick(auction, wishlistItem.bidType, wishlistItem.bestInSlot, wishlistItem.setBonus);				
						-- Auto bid, check if alert
						if wishlistItem.alert == true then
							local sBidType;
							if wishlistItem.bidType == 'normal' then
								sBidType = "|cFF"..kAuction2:RGBToHex(0,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
							elseif wishlistItem.bidType == 'offspec' then
								sBidType = "|cFF"..kAuction2:RGBToHex(255,255,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
							elseif wishlistItem.bidType == 'rot' then
								sBidType = "|cFF"..kAuction2:RGBToHex(210,0,0)..strupper(strsub(wishlistItem.bidType, 1, 1)) .. strsub(wishlistItem.bidType, 2).."|r";
							end
							StaticPopupDialogs["kAuction2Popup_PromptAutoBid_"..auction.id] = {
								text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|n|n"..
								"An automatic " .. sBidType .. " bid has been entered for the recently created auction of ".. auction.itemLink .. " due to your wishlist of this item.|n|n" ..
								"Would you like to keep or cancel your bid?",
								OnAccept = function()
									return;
								end,
								button1 = "Keep Bid",
								button2 = "Cancel Bid",
								OnCancel = function(a,b,c,d)
									if c ~= 'timeout' then
										kAuction2:Gui_AuctionBidButtonOnClick(auction, 'none');				
									end
								end,
								timeout = auction.duration,
								whileDead = 1,
								hideOnEscape = 1,
								hasEditBox = false,
								showAlert = true,
							};	
							StaticPopup_Show("kAuction2Popup_PromptAutoBid_"..auction.id);
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
						StaticPopupDialogs["kAuction2Popup_PromptAutoBid_"..auction.id] = {
							text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2|r|n|n"..
							"An auction has been detected for the following item found in your wishlists:|n" ..
							auction.itemLink ..
							"|n|nWould you like to enter a bid based on your wishlist settings as seen below?|n|n" ..
							"Bid Type: " .. sBidType .. "|n" ..
							"Best in Slot: " .. sBestInSlot .. "|n" ..
							"Set Bonus: " .. sSetBonus .. "|n",
							OnAccept = function()
								kAuction2:Gui_AuctionBidButtonOnClick(auction, wishlistItem.bidType, wishlistItem.bestInSlot, wishlistItem.setBonus);
							end,
							button1 = "Bid",
							button2 = "No Thanks",
							OnCancel = function()
								return;
							end,
							timeout = auction.duration,
							whileDead = 1,
							hideOnEscape = 1,
							hasEditBox = false,
							showAlert = true,
						};	
						StaticPopup_Show("kAuction2Popup_PromptAutoBid_"..auction.id);
					end
				end
			end
		end
	end
end
function kAuction2:Client_AuctionDeleteReceived(sender, auction)
	kAuction2:Client_DeleteAuction(auction);
end
function kAuction2:Client_AuraCancelReceived(sender, auraId)
	for i=1,40 do
		local id = select(11, UnitAura("player", i));
		-- Check if matching buff is detected
		if auraId == id then
			booMatch = true;
			kAuction2:Debug("Client_AuraCancelReceived - Removing aura ["..GetSpellInfo(auraId).."], due to server request.", 3);
			CancelUnitBuff("player", i);
			break;
		end
	end
end
function kAuction2:Client_AuraDisableReceived(sender, auras)
	local names = "";
	for i,auraId in pairs(auras) do
		names = names .. " - " .. select(1, GetSpellInfo(auraId));
		kAuction2:Aura_Disable(auraId);
	end
	if names ~= "" then
		kAuction2:Print("|cFF"..kAuction2:RGBToHex(100,255,0).."Disabling Auras|r"..names);
	end
end
function kAuction2:Client_AuraEnableReceived(sender, auras)
	local names = "";
	for i,auraId in pairs(auras) do
		names = names .. " - " .. select(1, GetSpellInfo(auraId));
		kAuction2:Aura_Enable(auraId);
	end
	if names ~= "" then
		kAuction2:Print("|cFF"..kAuction2:RGBToHex(100,255,0).."Enabling Auras|r"..names);
	end
end
function kAuction2:Client_AuctionWinnerReceived(sender, auction)
	if auction.winner and auction.winner == UnitName("player") then -- Auction winner is Player
		kAuction2:Gui_TriggerEffectsAuctionWon();
		if kAuction2.db.profile.bidding.auctionWonTextAlert == 2 then
			kAuction2:Print("|cFF"..kAuction2:RGBToHex(255,0,0).."Auction Won|r -- Item "..auction.itemLink);
		end
		if kAuction2:Wishlist_IsEnabled() then
			local oMatches = kAuction2:Wishlist_GetWishlistItemMatches(kAuction2:Item_GetItemIdFromItemLink(auction.itemLink));
			if oMatches then
				-- Check for priority item
				local wishlistItem = kAuction2:Wishlist_GetHighestPriorityItemFromSet(oMatches);
				if wishlistItem then
					-- Check if auto-remove
					if wishlistItem.autoRemove == true then
						kAuction2:Wishlist_RemoveItem(wishlistItem.wishlistId, wishlistItem.id);
					end
				end
			end
		end
	elseif auction.winner then -- Winner is someone else
		kAuction2:Gui_TriggerEffectsAuctionWinnerReceived();
		if kAuction2.db.profile.bidding.auctionWinnerReceivedTextAlert == 2 then
			kAuction2:Print("|cFF"..kAuction2:RGBToHex(255,0,255).."Auction Winner Declared: |r|cFF"..kAuction2:RGBToHex(255,255,0)..auction.winner.."|r -- Item "..auction.itemLink);
		end
	end
end
function kAuction2:Client_BidCancelReceived(sender, auction)
	kAuction2:Server_RemoveBidFromAuction(sender, auction);
end
function kAuction2:Client_BidReceived(sender, localAuctionData)
	kAuction2:Server_AddBidToAuction(sender, localAuctionData);
end
function kAuction2:Client_BidVoteReceived(sender, data)
	local success, auction, bid = kAuction2:Deserialize(data);
	kAuction2:Debug("FUNC: Client_BidVoteReceived, auction.id: " .. auction.id .. ", bid.name: " .. bid.name, 1)
	kAuction2:Server_AddBidVote(sender, auction, bid);
end
function kAuction2:Client_BidVoteCancelReceived(sender, data)
	local success, auction, bid = kAuction2:Deserialize(data);
	kAuction2:Debug("FUNC: Client_BidVoteCancelReceived, auction.id: " .. auction.id .. ", bid.name: " .. bid.name, 1)
	kAuction2:Server_RemoveBidVote(sender, auction, bid);
end
function kAuction2:Client_DataUpdateReceived(sender, data)
	local success, type, auction = kAuction2:Deserialize(data);
	if type == "auction" then
		index = kAuction2:Client_GetAuctionIndexByAuctionId(auction.id);
		if kAuction2.auctions[index] then
			kAuction2.auctions[index] = auction; -- Update auction
		end
	end
end
function kAuction2:Client_DeleteAuction(auction)
	if kAuction2.auctions[kAuction2:Client_GetAuctionIndexByAuctionId(auction.id)] then
		tremove(kAuction2.auctions, kAuction2:Client_GetAuctionIndexByAuctionId(auction.id));
	end
end
function kAuction2:Client_DoesAuctionExist(id)
	for i,item in pairs(kAuction2.auctions) do
		if item.id == id then
			kAuction2:Debug("FUNC: Client_DoesAuctionExist, Id: " .. id, 3)
			-- Item exists already
			return true;
		end
	end	
	return false;
end
function kAuction2:Client_DoesAuctionHaveBidFromName(auction, sender)
	for i,bid in pairs(auction.bids) do
		if bid.name == sender then
			return true;
		end
	end
	return false;
end
function kAuction2:Client_GetAuctionIndexByAuctionId(id)
	for i,auction in pairs(kAuction2.auctions) do
		if auction.id == id then
			-- Item exists already
			return i;
		end
	end	
	return nil;
end
function kAuction2:Client_GetAuctionBidIndexByBidId(id)
	for iAuction,vAuction in pairs(kAuction2.auctions) do
		for iBid,vBid in pairs(vAuction.bids) do
			if vBid.id == id then
				return iAuction, iBid;
			end
		end	
	end
	return nil;
end
function kAuction2:Client_GetAuctionById(id)
	for i,auction in pairs(kAuction2.auctions) do
		if auction.id == id then
			kAuction2:Debug("FUNC: Client_DoesAuctionExist, Id: " .. id, 3)
			-- Item exists already
			return auction;
		end
	end	
	return nil;
end
function kAuction2:Client_GetBidById(id)
	for iAuction,vAuction in pairs(kAuction2.auctions) do
		for iBid,vBid in pairs(vAuction.bids) do
			if vBid.id == id then
				return vBid;
			end
		end	
	end
	return nil;
end
function kAuction2:Client_GetBidOfAuctionFromName(auction, sender)
	for i,bid in pairs(auction.bids) do
		if bid.name == sender then
			return bid;
		end
	end
	return nil;
end
function kAuction2:Client_GetLocalAuctionDataById(id)
	for i,auction in pairs(kAuction2.localAuctionData) do
		if auction.id == id then
			return auction;
		end
	end
	return nil;
end
function kAuction2:Client_RaidServerReceived(sender)
	kAuction2.server = sender;
	kAuction2.enabled = true;
	-- Run version check
	if not kAuction2.hasRunVersionCheck and not kAuction2:IsServer() then
		kAuction2:SendCommunication("Version", kAuction2.version);
		kAuction2:Debug("FUNC: Client_RaidServerReceived, server = "..kAuction2.server..", enabled = true, running version check.", 1);
	end
end
function kAuction2:Client_VersionInvalidReceived(sender, data)
	if not kAuction2.hasRunVersionCheck then
		local success, name, minRequiredVersion, serverVersion = kAuction2:Deserialize(data);
		kAuction2:Debug("FUNC: Client_VersionInvalidReceived, name, minRequiredVersion, serverVersion " .. name.. minRequiredVersion..serverVersion, 1);
		if name ~= UnitName("player") then
			return;
		end
		StaticPopupDialogs["kAuction2Popup_VersionInvalid"] = {
			text = "|cFF"..kAuction2:RGBToHex(0,255,0).."kAuction2 out of date.|r|n|nYour version: |cFF"..kAuction2:RGBToHex(255,0,0)..kAuction2.version.."|r|nRequired version: |cFF"..kAuction2:RGBToHex(255,255,0)..minRequiredVersion.."|r|nServer version: |cFF"..kAuction2:RGBToHex(0,255,0)..serverVersion.."|r|n|nPlease exit World of Warcraft and update your latest version from:|n|cFF"..kAuction2:RGBToHex(190,0,110).."wow.curseforge.com/projects/kAuction2|r",
			button1 = "On it!",
			OnAccept = function()
				return;
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		};
		PlaySoundFile(kAuction2.sharedMedia:Fetch("sound", "Worms - Uh Oh"));		
		StaticPopup_Show("kAuction2Popup_VersionInvalid");
		kAuction2.hasRunVersionCheck = true;
	end
end
function kAuction2:Client_VersionRequestReceived(sender, version)
	kAuction2:SendCommunication("Version", kAuction2.version);
end