
kAuction2.menu = {};
kAuction2.currentZone = false;

function kAuction2:OnInitialize()
    -- Load Database
    kAuction2.db = LibStub("AceDB-3.0"):New("kAuction2DB", kAuction2.defaults)
    kAuction2.raidDb = LibStub("AceDB-3.0"):New("kAuction2RaidDB")
    -- Inject Options Table and Slash Commands
	kAuction2.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(kAuction2.db)
	kAuction2.candyBar = LibStub("CandyBar-2.0");
	kAuction2.config = LibStub("AceConfig-3.0"):RegisterOptionsTable("kAuction2", kAuction2.options, {"kAuction2", "ka"})
	kAuction2.dialog = LibStub("AceConfigDialog-3.0")
	kAuction2.AceGUI = LibStub("AceGUI-3.0")
	kAuction2.cb = LibStub:GetLibrary("CallbackHandler-1.0")
	kAuction2.effects = LibStub("LibEffects-1.0")
	kAuction2.oo = LibStub("AceOO-2.0")
	kAuction2.qTip = LibStub("LibQTip-1.0")
	kAuction2.roster = LibStub("Roster-2.1")
	kAuction2.sharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")
	kAuction2:RegisterLibSharedMediaObjects();
	kAuction2.tablet = LibStub("Tablet-2.0")
	kAuction2.StatLogic = LibStub("LibStatLogic-1.1")
	--kAuction2.ring = LibStub("kRotaryLib-1.0")
	--kAuction2:Threading_CreateTimer("createTestRing",InitializeTestRing,5,false,nil);
	--kAuction2:Threading_StartTimer("createTestRing");
	--kAuction2:Ring_InitalizeTestRing();
	-- Init Events
	kAuction2:InitializeEvents()
	-- Comm registry
	kAuction2:RegisterComm("kAuction2")
	-- Frames
	kAuction2.selectedAuctionIndex = 0;
	kAuction2.auctions = {};	
	kAuction2.auctionTabs = {};
	kAuction2.localAuctionData = {};
	kAuction2:Gui_InitializePopups();
	kAuction2:Gui_InitializeFrames()
	kAuction2:Gui_HookFrameRefreshUpdate();
	-- Menu
	kAuction2.menu = CreateFrame("Frame", "Test_DropDown", UIParent, "UIDropDownMenuTemplate");
	-- Init council list
	kAuction2:Server_InitializeCouncilMemberList();
end
function kAuction2:InitializeEvents()
	kAuction2.enabled = false;
	kAuction2.isActiveRaid = false;
	kAuction2.isInRaid = false;
	kAuction2:RegisterEvent("LOOT_OPENED");
	kAuction2:RegisterEvent("LOOT_CLOSED");
	kAuction2:RegisterEvent("UNIT_SPELLCAST_SENT");
	kAuction2:RegisterEvent("RAID_ROSTER_UPDATE");
	kAuction2:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	kAuction2:RegisterEvent("CHAT_MSG_WHISPER");
	--kAuction2:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	if kAuction2.db.profile.modules.aura.enabled then
		kAuction2:RegisterEvent("UNIT_AURA");
	end
	--kAuction2:RegisterEvent("UI_ERROR_MESSAGE");
end

do
	local function kAuction2FilterOutgoing(self, event, ...)
		local msg = ...
		if not msg and self then
			return kAuction2FilterOutgoing(nil, nil, self, event)
		end
		-- Check for addon prefix, suppress automatically
		if string.find(msg, kAuction2.const.chatPrefix) then
			return true;
		end
		return false;
	end
	local function kAuction2FilterIncoming(self, event, ...)
		local msg = ...;
		if not msg and self then
			return kAuction2FilterIncoming(nil, nil, self, event)
		end		
		-- Check for addon prefix, suppress automatically
		if string.find(msg, kAuction2.const.chatPrefix) then
			return true;
		end
		if strlower(msg) == "kAuction2 help" or strlower(msg) == "ka help" then
			return true;
		end
		if not kAuction2.db.profile.looting.auctionWhisperBidSuppressionEnabled or not kAuction2.db.profile.looting.auctionWhisperBidEnabled then
			return false;
		end
		local isBid, localAuctionData = kAuction2:Gui_GetWhisperBidType(msg,true);
		if isBid then
			return true;
		end
		return false;
	end
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", kAuction2FilterOutgoing)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", kAuction2FilterOutgoing)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", kAuction2FilterIncoming)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", kAuction2FilterIncoming)
end
function kAuction2:CHAT_MSG_WHISPER(event, msg, name)
	kAuction2:Gui_OnWhisper(msg, name, false);
end
function kAuction2:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...);
	-- Note, for this example, you could just use 'local type = select(2, ...)'.  The others are included so that it's clear what's available.
	if (type=="SPELL_DAMAGE") then
		local spellId, spellName, spellSchool = select(9, ...)
		-- Use the following line in game version 3.0 or higher, for previous versions use the line after
		local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(12, ...)

		if destGUID == UnitGUID("player") then
			if amount and overkill and absorbed then
				kAuction2:Debug("Amount: " .. amount .. ", Absorb: " .. absorbed .. ", Overkill: " .. overkill ..", Total: " .. amount + absorbed + overkill, 3);
			elseif amount and absorbed then
				kAuction2:Debug("Amount: " .. amount .. ", Absorb: " .. absorbed .. ", Total: " .. amount + absorbed, 3);
			end
			-- Amount includes overkill
			-- if overkill: amount - overkill + resist + absorbed
			-- Amount, Resist, Absorbed are seperate
			-- Total damage dealt: resist + absorbed + (amount - overkill)
		end
	end
end

function kAuction2:RegisterLibSharedMediaObjects()
	-- Fonts
	kAuction2.sharedMedia:Register("font", "Adventure",	[[Interface\AddOns\kAuction2\Fonts\Adventure.ttf]]);
	kAuction2.sharedMedia:Register("font", "Alba Super", [[Interface\AddOns\kAuction2\Fonts\albas.ttf]]);
	kAuction2.sharedMedia:Register("font", "Caslon Antique", [[Interface\AddOns\kAuction2\Fonts\CAS_ANTN.TTF]]);
	kAuction2.sharedMedia:Register("font", "Caslon Antique", [[Interface\AddOns\kAuction2\Fonts\Cella.otf]]);
	kAuction2.sharedMedia:Register("font", "Chick", [[Interface\AddOns\kAuction2\Fonts\chick.ttf]]);
	kAuction2.sharedMedia:Register("font", "Corleone",	[[Interface\AddOns\kAuction2\Fonts\Corleone.ttf]]);
	kAuction2.sharedMedia:Register("font", "The Godfather",	[[Interface\AddOns\kAuction2\Fonts\CorleoneDue.ttf]]);
	kAuction2.sharedMedia:Register("font", "Forte",	[[Interface\AddOns\kAuction2\Fonts\Forte.ttf]]);
	kAuction2.sharedMedia:Register("font", "Freshbot", [[Interface\AddOns\kAuction2\Fonts\freshbot.ttf]]);
	kAuction2.sharedMedia:Register("font", "Jokewood", [[Interface\AddOns\kAuction2\Fonts\jokewood.ttf]]);
	kAuction2.sharedMedia:Register("font", "Sopranos",	[[Interface\AddOns\kAuction2\Fonts\Mobsters.ttf]]);
	kAuction2.sharedMedia:Register("font", "Weltron Urban", [[Interface\AddOns\kAuction2\Fonts\weltu.ttf]]);
	kAuction2.sharedMedia:Register("font", "Wild Ride", [[Interface\AddOns\kAuction2\Fonts\WildRide.ttf]]);
	-- Sounds
	
	kAuction2.sharedMedia:Register("sound", "Alarm", [[Interface\AddOns\kAuction2\Sounds\alarm.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Alert", [[Interface\AddOns\kAuction2\Sounds\alert.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Info", [[Interface\AddOns\kAuction2\Sounds\info.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Long", [[Interface\AddOns\kAuction2\Sounds\long.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Shot", [[Interface\AddOns\kAuction2\Sounds\shot.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Sonar", [[Interface\AddOns\kAuction2\Sounds\sonar.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Victory", [[Interface\AddOns\kAuction2\Sounds\victory.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Victory Classic", [[Interface\AddOns\kAuction2\Sounds\victoryClassic.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Victory Long", [[Interface\AddOns\kAuction2\Sounds\victoryLong.mp3]]);
	kAuction2.sharedMedia:Register("sound", "Wilhelm", [[Interface\AddOns\kAuction2\Sounds\wilhelm.mp3]]);

	-- Sounds, Worms
	kAuction2.sharedMedia:Register("sound", "Worms - Angry Scot Come On Then", [[Interface\AddOns\kAuction2\Sounds\wangryscotscomeonthen.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Angry Scot Coward", [[Interface\AddOns\kAuction2\Sounds\wangryscotscoward.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Angry Scot I'll Get You", [[Interface\AddOns\kAuction2\Sounds\wangryscotsillgetyou.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Sargeant Fire", [[Interface\AddOns\kAuction2\Sounds\wdrillsargeantfire.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Sargeant Stupid", [[Interface\AddOns\kAuction2\Sounds\wdrillsargeantstupid.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Sargeant Watch This", [[Interface\AddOns\kAuction2\Sounds\wdrillsargeantwatchthis.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Grandpa Coward", [[Interface\AddOns\kAuction2\Sounds\wgrandpacoward.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Grandpa Uh Oh", [[Interface\AddOns\kAuction2\Sounds\wgrandpauhoh.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - I'll Get You", [[Interface\AddOns\kAuction2\Sounds\willgetyou.wav]]);
	kAuction2.sharedMedia:Register("sound", "Worms - Uh Oh", [[Interface\AddOns\kAuction2\Sounds\wuhoh.wav]]);
	-- Drum
	kAuction2.sharedMedia:Register("sound", "Snare1", [[Interface\AddOns\kAuction2\Sounds\snare1.mp3]]);
end

function kAuction2:OnEnable()
	if kAuction2:Client_IsServer() then
		if GetNumRaidMembers() > 0 then
			kAuction2.isInRaid = true;
			kAuction2:SendCommunication("RaidServer");
			if kAuction2:Server_IsInValidRaidZone() then -- Check for valid zone
				StaticPopup_Show("kAuction2Popup_StartRaidTracking");
			end
			kAuction2:Debug("FUNC: OnEnable, ClientIsServer = true, raid exists, enabled = true.", 1)
		else
			kAuction2:Debug("FUNC: OnEnable, ClientIsServer = true, raid doesn't exist, enabled = false.", 1)
		end
	else
		if GetNumRaidMembers() > 0 then
			kAuction2.isInRaid = true;
			kAuction2:SendCommunication("RaidHasServer", nil);
			kAuction2:Debug("FUNC: OnEnable, ClientIsServer = false, raid exists, RaidHasServer comm sent.", 1)
		else
			kAuction2:Debug("FUNC: OnEnable, ClientIsServer = false, raid doesn't exist, enabled = false.", 1)
		end
	end
end
function kAuction2:OnDisable()
    -- Called when the addon is disabled
end
function kAuction2:LOOT_CLOSED()
	kAuction2:Debug("EVENT: LOOT_CLOSED", 3)
	kAuction2.isLooting = false;
end
function kAuction2:LOOT_OPENED()
	kAuction2:Debug("EVENT: LOOT_OPENED", 3)
	kAuction2.isLooting = true;
	if kAuction2.enabled and kAuction2.isActiveRaid and GetNumRaidMembers() > 0 and kAuction2:Client_IsServer() then -- Player in raid and raid leader
		local guid = UnitGUID("target") -- NPC Looted
		local corpseName = UnitName("target");
		if not guid then -- Else Container Looted
			guid = kAuction2.guids.lastObjectOpened;
			corpseName = kAuction2.guids.lastObjectOpened;
		end			
		if kAuction2:Server_HasCorpseBeenAuctioned(guid) == false then -- Check if corpse auctioned already.
			kAuction2:Server_SetCorpseAsAuctioned(guid) -- Mark corpse as auctioned		
			for i = 1, GetNumLootItems() do
				if (LootSlotIsItem(i)) then
					if kAuction2.db.profile.looting.isAutoAuction then
						kAuction2:Server_AuctionItem(GetLootSlotLink(i), guid, corpseName)
					end
				end
			end		
		end		
	end
end
function kAuction2:RAID_ROSTER_UPDATE()
	-- Client just joined a raid.
	if kAuction2.isInRaid == false and GetNumRaidMembers() > 0 then
		kAuction2.hasRunVersionCheck = false;
		kAuction2.isInRaid = true;
		-- Check if Server, and valid zone
		if kAuction2:Client_IsServer() then
			kAuction2:SendCommunication("RaidServer");
			if kAuction2:Server_IsInValidRaidZone() then -- Check for valid zone
				StaticPopup_Show("kAuction2Popup_StartRaidTracking");
			end
		else
			kAuction2:SendCommunication("RaidHasServer", nil);
		end
		kAuction2:Debug("FUNC: RAID_ROSTER_UPDATE - Client just joined a raid.", 1);
	-- Client just left a raid.
	elseif kAuction2.isInRaid == true and isActiveRaid == true and GetNumRaidMembers() == 0 then
		kAuction2.hasRunVersionCheck = false;
		kAuction2.isInRaid = false;
		-- Check if Server
		if kAuction2:Client_IsServer() then
			StaticPopup_Show("kAuction2Popup_StopRaidTracking");
		end
		kAuction2:Debug("FUNC: RAID_ROSTER_UPDATE - Client just left a raid.", 1);
	end
end
function kAuction2:UNIT_SPELLCAST_SENT(blah, unit, spell, rank, target)
	if spell == "Opening" then
		kAuction2.guids.lastObjectOpened = target;
		kAuction2:Debug("FUNC: UNIT_SPELLCAST_SENT, target: " .. target .. ", spell: " .. spell, 3)
	end
end
function kAuction2:SendCommunication(command, data)
	kAuction2:SendCommMessage("kAuction2", kAuction2:Serialize(command, data), "RAID")
end
function kAuction2:OnCommReceived(prefix, serialObject, distribution, sender)
	kAuction2:Debug("FUNC: OnCommReceived, FIRE", 3)
	local success, command, data = kAuction2:Deserialize(serialObject)
	if success then
		if prefix == "kAuction2" and distribution == "RAID" then
			if (command == "Auction" and kAuction2:IsPlayerRaidLeader(sender)) then
				kAuction2:Client_AuctionReceived(data);
			end
			if (command == "AuctionDelete" and kAuction2:IsPlayerRaidLeader(sender)) then
				kAuction2:Client_AuctionDeleteReceived(sender, data);
			end
			if (command == "AuctionWinner" and kAuction2:IsPlayerRaidLeader(sender)) then
				kAuction2:Client_AuctionWinnerReceived(sender, data);
			end
			if (command == "Bid") then
				kAuction2:Client_BidReceived(sender, data);
			end
			if (command == "BidCancel") then
				kAuction2:Client_BidCancelReceived(sender, data);
			end
			if (command == "BidVote") then
				kAuction2:Client_BidVoteReceived(sender, data);
			end
			if (command == "BidVoteCancel") then
				kAuction2:Client_BidVoteCancelReceived(sender, data);
			end
			if (command == "DataUpdate") then
				kAuction2:Client_DataUpdateReceived(sender, data);
				-- Update Raid DB Xml
				if kAuction2:Client_IsServer() then
					kAuction2:Server_UpdateRaidDb();
				end				
			end
			if (command == "RaidEnd") and kAuction2:IsPlayerRaidLeader(sender) then
				kAuction2.auctions = {};	
				kAuction2.auctionTabs = {};
			end			
			if (command == "RaidHasServer") then
				kAuction2:Server_RaidHasServerReceived(sender);
			end
			if (command == "RaidServer") then
				kAuction2:Client_RaidServerReceived(sender);
			end
			if (command == "RequestAuraCancel") then
				kAuction2:Client_AuraCancelReceived(sender, data);
			end
			if (command == "RequestAuraEnable") then
				kAuction2:Client_AuraEnableReceived(sender, data);
			end
			if (command == "RequestAuraDisable") then
				kAuction2:Client_AuraDisableReceived(sender, data);
			end
			if (command == "Version") then
				kAuction2:Server_VersionReceived(sender, data);
			end
			if (command == "VersionInvalid") and kAuction2:IsPlayerRaidLeader(sender) then
				kAuction2:Client_VersionInvalidReceived(sender, data);
			end
			if (command == "VersionRequest") and kAuction2:IsPlayerRaidLeader(sender) then
				kAuction2:Client_VersionRequestReceived(sender, data);
			end
			-- Refresh frames
			kAuction2:Gui_HookFrameRefreshUpdate();
		end
	end
end
function kAuction2:IsPlayerRaidLeader(name)
	local objUnit = kAuction2.roster:GetUnitObjectFromName(name)
	if objUnit then
		if objUnit.rank == 2 then -- 0 regular, 1 assistant, 2 raid leader
			return true;
		end
	end
	return false;
end
function kAuction2:ParseAuctionItemLinkCommString(string)
	local itemLink, id, seedTime, duration, corpseGuid = strsplit("_", string);
	return itemLink, id, seedTime, duration, corpseGuid;
end
function kAuction2:Debug(msg, threshold)
	if kAuction2.db.profile.debug.enabled then
		if threshold == nil then
			kAuction2:Print(ChatFrame1, "DEBUG: " .. msg)		
		elseif threshold <= kAuction2.db.profile.debug.threshold then
			kAuction2:Print(ChatFrame1, "DEBUG: " .. msg)		
		end
	end
end
function kAuction2:HookBidsFrameScrollUpdate()
	kAuction2:BidsFrameScrollUpdate();
end
function kAuction2:RegisterLootCouncilVote(auction, bid)
	if kAuction2:IsLootCouncilMember(auction, UnitName("player")) then
		-- Clear current vote for council member
		kAuction2:ClearLootCouncilVoteFromAuction(auction, UnitName("player"));
		kAuction2:SendCommunication("BidVote", kAuction2:Serialize(auction, bid));
	end
end
function kAuction2:CancelLootCouncilVote(auction, bid)
	if kAuction2:IsLootCouncilMember(auction, UnitName("player")) then
		-- Clear current vote for council member
		kAuction2:ClearLootCouncilVoteFromAuction(auction, UnitName("player"));
		kAuction2:SendCommunication("BidVoteCancel", kAuction2:Serialize(auction, bid));
	end
end
function kAuction2:IsLootCouncilMember(auction, councilMember)
	if IsRaidLeader() then
		return true;
	else
		local memberName = councilMember;
		if not councilMember then
			memberName = UnitName("player");
		end
		for i,member in pairs(auction.councilMembers) do
			if memberName == member then
				return true;
			end
		end	
	end
	return false;
end
function kAuction2:ClearLootCouncilVoteFromAuction(auction, councilMember)
	for i,bid in pairs(auction.bids) do -- Loop through bids
		for iCouncil, vCouncil in pairs(bid.lootCouncilVoters) do -- Loop through Council Voters
			if vCouncil == councilMember then -- Find council name match in bid voters
				kAuction2:Debug("FUNC: ClearLootCouncilVoteFromAuction, auction.itemLink: " .. auction.itemLink, 1)
				-- Remove entry
				tremove(bid.lootCouncilVoters, iCouncil);
			end
		end
	end
	return true;
end
function kAuction2:BidHasCouncilMemberVote(bid, councilMember)
	for i,vCouncil in pairs(bid.lootCouncilVoters) do
		if councilMember == vCouncil then
			return true;
		end
	end
	return false;
end
function kAuction2:BidsFrameScrollUpdate()
	local line; -- 1 through 5 of our window to scroll
	local lineplusoffset; -- an index into our data calculated from the scroll offset
	--_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitleText"]:SetFont(kAuction2.sharedMedia:Fetch("font", kAuction2.db.profile.gui.frames.bids.font), 16);
	--_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitleRightText"]:SetFont(kAuction2.sharedMedia:Fetch("font", kAuction2.db.profile.gui.frames.bids.font), 16);
	if #(kAuction2.auctions) > 0 and #(kAuction2.auctions) >= kAuction2.selectedAuctionIndex and kAuction2.selectedAuctionIndex ~= 0 and kAuction2.db.profile.gui.frames.bids.visible then
		--_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitleText"]:SetText(kAuction2.auctions[kAuction2.selectedAuctionIndex].itemLink);
		--_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitle"]:SetScript("OnEnter", function() kAuction2:Gui_CurrentItemMenuOnEnter(_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitleText"), kAuction2.auctions[kAuction2.selectedAuctionIndex].itemLink) end);
		--_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerTitle"]:SetScript("OnLeave", function() GameTooltip:Hide() end);
		FauxScrollFrame_Update(kAuction2MainFrameBidScrollContainerScrollFrame,#(kAuction2.auctions[kAuction2.selectedAuctionIndex].bids),5,16);
		for line=1,5 do
			lineplusoffset = line + FauxScrollFrame_GetOffset(kAuction2MainFrameBidScrollContainerScrollFrame);
			if lineplusoffset <= #(kAuction2.auctions[kAuction2.selectedAuctionIndex].bids) then
				-- Update Bid Current Item Buttons
				kAuction2:Gui_UpdateBidCurrentItemButtons(line, kAuction2.auctions[kAuction2.selectedAuctionIndex], kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[lineplusoffset]);
				-- Update Bid Items Won Frame
				kAuction2:Gui_UpdateBidItemsWonFrame(_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..line.."ItemsWon"]);
				-- Update Bid Items Won Text
				kAuction2:Gui_UpdateBidItemsWonText(_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..line.."ItemsWonText"]);
				-- Update Bid Name Text
				kAuction2:Gui_UpdateBidNameText(_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..line.."NameText"]);
				-- Update Bid Roll Text
				kAuction2:Gui_UpdateBidRollText(line, kAuction2.auctions[kAuction2.selectedAuctionIndex], kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[lineplusoffset]);
				-- Update Bid Vote button
				kAuction2:Gui_UpdateBidVoteButton(line, kAuction2.auctions[kAuction2.selectedAuctionIndex], kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[lineplusoffset]);
				kAuction2:Gui_ConfigureBidColumns(line, kAuction2.auctions[kAuction2.selectedAuctionIndex]);
				_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..line]:Show();
			else
				_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..line]:Hide();
			end
		end
		_G[kAuction2.db.profile.gui.frames.main.name]:Show();		
	end
end
function kAuction2:GetFirstOpenAuctionIndex()
	for i,auction in pairs(kAuction2.auctions) do
		if not auction.closed then
			return i;
		end
	end
	return 1;
end
function kAuction2:MainFrameScrollUpdate()
	if kAuction2.auctions and #(kAuction2.auctions) > 0 and kAuction2.db.profile.gui.frames.main.visible then
		local line; -- 1 through 5 of our window to scroll
		local lineplusoffset; -- an index into our data calculated from the scroll offset
		FauxScrollFrame_Update(kAuction2MainFrameMainScrollContainerScrollFrame,#(kAuction2.auctions),5,16);
		_G[kAuction2.db.profile.gui.frames.main.name.."TitleText"]:SetFont(kAuction2.sharedMedia:Fetch("font", kAuction2.db.profile.gui.frames.main.font), 16);
		for line=1,5 do
			lineplusoffset = line + FauxScrollFrame_GetOffset(kAuction2MainFrameMainScrollContainerScrollFrame);
			if lineplusoffset <= #(kAuction2.auctions) then
				_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..line.."ItemNameText"]:SetText(kAuction2.auctions[lineplusoffset].itemLink);
				_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..line.."ItemNameText"]:SetFont(kAuction2.sharedMedia:Fetch("font", kAuction2.db.profile.gui.frames.main.font), kAuction2.db.profile.gui.frames.main.fontSize);
				_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..line.."StatusText"]:SetFont(kAuction2.sharedMedia:Fetch("font", kAuction2.db.profile.gui.frames.main.font), kAuction2.db.profile.gui.frames.main.fontSize);
				-- Removed r8702, replaced by dropdown system -- Update Bid Button --kAuction2:Gui_UpdateAuctionBidButton(line, kAuction2.auctions[lineplusoffset]);
				-- Update Close Button
				kAuction2:Gui_UpdateAuctionCloseButton(line, kAuction2.auctions[lineplusoffset]);
				-- Update Current Item Buttons
				kAuction2:Gui_UpdateAuctionCurrentItemButtons(line, kAuction2.auctions[lineplusoffset]);
				-- Update Candy Bars
				kAuction2:Gui_UpdateAuctionCandyBar(line, kAuction2.auctions[lineplusoffset]);
				-- Update Status
				kAuction2:Gui_UpdateAuctionStatusText(line, kAuction2.auctions[lineplusoffset]);
				-- Update Pullout menu
				kAuction2:Gui_UpdateItemMatchMenu(line, kAuction2.auctions[lineplusoffset]);
				_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..line]:Show();
			else
				-- Update Candy Bars
				kAuction2.candyBar:Unregister("auction"..line);
				_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..line]:Hide();
			end
		end
		--_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainer"]:Show();
		_G[kAuction2.db.profile.gui.frames.main.name]:Show();
	else
		_G[kAuction2.db.profile.gui.frames.main.name]:Hide();
	end
end
function kAuction2:DetermineRandomAuctionWinner(iAuction)
	-- Verify raid leader
	if not IsRaidLeader() then
		return;
	end
	if kAuction2.auctions and kAuction2.auctions[iAuction] then
		if not kAuction2.auctions[iAuction].closed then
			return;
		end
		-- Check auction type
		if kAuction2.auctions[iAuction].auctionType == 1 then -- Random
			if #(kAuction2.auctions[iAuction].bids) > 0 then
				local winningBid = kAuction2:GetRandomAuctionWinningBid(kAuction2.auctions[iAuction]);
				if winningBid then
					kAuction2.auctions[iAuction].winner = winningBid.name; -- set winner
					return kAuction2.auctions[iAuction].winner;
				end
			end
		end
	end
	return nil;
end
function kAuction2:GetEnchanterInRaidRosterObject()
	for i,val in pairs(kAuction2.db.profile.looting.disenchanters) do
		local unit = kAuction2.roster:GetUnitObjectFromName(val);
		if unit then
			return unit;
		end
	end
	return nil;
end
function kAuction2:GetRandomAuctionWinningBid(auction)
	if auction.auctionType ~= 1 then
		return;
	end
	while kAuction2:DoesRandomAuctionHaveHighRoll(auction) == false do
		-- Do nothing
	end
	local booNormalExists = false;
	local booOffspecExists = false;
	for i,bid in pairs(auction.bids) do
		if bid.bidType == "normal" then
			booNormalExists = true;
		elseif bid.bidType == "offspec" then
			booOffspecExists = true;
		end
	end
	local highRoll = kAuction2:GetAuctionHighRoll(auction);
	if booNormalExists then
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "normal" and bid.roll == highRoll then
				return bid;
			end
		end
	elseif booNormalExists then
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "offspec" and bid.roll == highRoll then
				return bid;
			end
		end
	else
		for i,bid in pairs(auction.bids) do
			if bid.roll == highRoll then
				return bid;
			end
		end
	end
	return nil;
end
function kAuction2:DoesRandomAuctionHaveHighRoll(auction)
	if auction.auctionType ~= 1 then
		return;
	end
	-- Check if normal bidTypes, if so, ignore offspec entry rolls
	local booNormalExists = false;
	local booOffspecExists = false;
	for i,bid in pairs(auction.bids) do
		if bid.bidType == "normal" then
			booNormalExists = true;
		elseif bid.bidType == "offspec" then
			booOffspecExists = true;
		end
	end
	local highBids = {};
	local highRoll = kAuction2:GetAuctionHighRoll(auction);
	if booNormalExists then
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "normal" and bid.roll == highRoll then
				tinsert(highBids, #(highBids)+1, i);
			end
		end
	elseif booOffspecExists then
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "offspec" and bid.roll == highRoll then
				tinsert(highBids, #(highBids)+1, i);
			end
		end
	else
		for i,bid in pairs(auction.bids) do
			if bid.roll == highRoll then
				tinsert(highBids, #(highBids)+1, i);
			end
		end
	end
	-- Redo matching high rolls
	if #(highBids) > 1 then
		for i,val in pairs(highBids) do
			auction.bids[val].roll = math.random(1,kAuction2.db.profile.looting.rollMaximum);
		end
	end
	if #(highBids) == 1 then
		return true;
	else
		return false;
	end
end
function kAuction2:GetAuctionHighRoll(auction)
	if auction.auctionType ~= 1 then
		return;
	end
	local booNormalExists = false;
	local booOffspecExists = false;
	for i,bid in pairs(auction.bids) do
		if bid.bidType == "normal" then
			booNormalExists = true;
		elseif bid.bidType == "offspec" then
			booOffspecExists = true;
		end
	end
	if booNormalExists then
		local highRoll = 0;
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "normal" then
				if bid.roll > highRoll then
					highRoll = bid.roll;
				end
			end
		end
		return highRoll;
	elseif booNormalExists then
		local highRoll = 0;
		for i,bid in pairs(auction.bids) do
			if bid.bidType == "offspec" then
				if bid.roll > highRoll then
					highRoll = bid.roll;
				end
			end
		end
		return highRoll;
	else
		local highRoll = 0;
		for i,bid in pairs(auction.bids) do
			if bid.roll > highRoll then
				highRoll = bid.roll;
			end
		end
		return highRoll;		
	end
	return nil;
end
function kAuction2:GetAuctionTimeleft(objAuction, offset)
	local localAuctionData = kAuction2:Client_GetLocalAuctionDataById(objAuction.id);
	kAuction2:Debug("FUNC: GetAuctionTimeleft, localstarttime: " .. localAuctionData.localStartTime .. ", time: " .. time(), 2)
	if offset then
		if offset >= 0 then
			if (time() - localAuctionData.localStartTime) > objAuction.duration + offset then -- auction closed
				objAuction.closed = true;
				kAuction2:Debug("FUNC: GetAuctionTimeleft offset >= 0, value: 0", 2)
				return nil;
			else
				kAuction2:Debug("FUNC: GetAuctionTimeleft, value: " .. (objAuction.duration + offset) - (time() - localAuctionData.localStartTime), 2)
				return (objAuction.duration + offset) - (time() - localAuctionData.localStartTime);
			end	
		else
			if (time() + offset - localAuctionData.localStartTime) > objAuction.duration then -- auction closed
				objAuction.closed = true;
				kAuction2:Debug("FUNC: GetAuctionTimeleft, offset < 0: 0", 2)
				return nil;
			else
				kAuction2:Debug("FUNC: GetAuctionTimeleft, value: " .. (objAuction.duration) - (time() + offset - localAuctionData.localStartTime), 2)
				return (objAuction.duration) - (time() + offset - localAuctionData.localStartTime);
			end				
		end
	else
		if (time() - localAuctionData.localStartTime) > objAuction.duration then -- auction closed
			objAuction.closed = true;
			kAuction2:Debug("FUNC: GetAuctionTimeleft, no offset, value: 0", 2)
			return nil;
		else
			kAuction2:Debug("FUNC: GetAuctionTimeleft, value: " .. objAuction.duration - (time() - localAuctionData.localStartTime), 2)
			return objAuction.duration - (time() - localAuctionData.localStartTime);
		end
	end
end
function kAuction2:RGBToHex(r, g, b)
	r = r <= 255 and r >= 0 and r or 0
	g = g <= 255 and g >= 0 and g or 0
	b = b <= 255 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r, g, b)
end
function kAuction2:ColorizeSubstringInString(subject, substring, r, g, b)
	local t = {};
	for i = 1, strlen(subject) do
		local iStart, iEnd = string.find(strlower(subject), strlower(substring), i, strlen(substring) + i - 1)
		if iStart and iEnd then
			for iTrue = iStart, iEnd do
				t[iTrue] = true;
			end
		else
			if not t[i] then
				t[i] = false;
			end
		end
	end
	local sOut = '';
	local sColor = kAuction2:RGBToHex(r*255,g*255,b*255);
	for i = 1, strlen(subject) do
		if t[i] == true then
			sOut = sOut .. "|cFF"..sColor..strsub(subject, i, i).."|r";
		else
			sOut = sOut .. strsub(subject, i, i);
		end
	end
	if strlen(sOut) > 0 then
		return sOut;
	else
		return nil;
	end
end
function kAuction2:OnBidItemsWonEnter(frame)
	kAuction2Tooltip:Hide(); -- Clear tooltip
	offset = FauxScrollFrame_GetOffset(kAuction2MainFrameBidScrollContainerScrollFrame);
	local _, _, row = string.find(frame:GetName(), "(%d+)");
	local selectFrame;	
	if kAuction2.auctions[kAuction2.selectedAuctionIndex] and kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row] then
		local wonItemList = kAuction2:Item_GetPlayerWonItemList(kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row].name);
		-- If active bid, menu locked, do not show
		if #(wonItemList) > 0 then
			--Current item mouse over, show select frame
			selectFrame = _G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWonSelectFrame"];
			local i = 1;
			while _G[selectFrame:GetName().."Button"..i] and i <= #(kAuction2:Item_GetPlayerWonItemList(kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row].name))  do
				_G[selectFrame:GetName().."Button"..i]:Show()
				i=i+1;
			end
			kAuction2:Threading_StartTimer("kAuction2ThreadingFrameBids"..row);
			if _G["kAuction2ThreadingFrameBids"..row] then
				_G["kAuction2ThreadingFrameBids"..row]:Show();
			end
		else
			if _G["kAuction2ThreadingFrameBids"..row] then
				_G["kAuction2ThreadingFrameBids"..row]:Hide();
			end
			_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWonSelectFrame"]:Hide();
		end
		-- Hide other Rows
		local iSelectFrame = 1;
		while _G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..iSelectFrame.."ItemsWonSelectFrame"] do
			if iSelectFrame ~= row then
				_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..iSelectFrame.."ItemsWonSelectFrame"]:Hide();
			end
			iSelectFrame = iSelectFrame + 1;
		end
		if #(wonItemList) > 0 then
			kAuction2:Gui_OnBidRollOnLeave(nil);
			kAuction2:Gui_OnBidItemsWonLeave(nil);		
			selectFrame:Show();
			-- Update tooltip
			--[[
			if localAuctionData.currentItemLink ~= false then
				kAuction2:Gui_CurrentItemMenuOnEnter(frame,localAuctionData.currentItemLink);
			end
			]]
			local tip = kAuction2.qTip:Acquire("GameTooltip", 1, "LEFT")
			tip:Clear();
			tip:SetPoint("TOP", frame, "BOTTOM", 0, 0);
			tip:AddHeader("Items Won by " .. kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row].name);
			tip:AddLine("");
			tip:AddLine("");
			tip:AddLine("");
			local fontRed = CreateFont("kAuction2BidItemsWonFontRed")
			fontRed:CopyFontObject(GameTooltipText)
			fontRed:SetTextColor(1,0,0)
			local fontGreen = CreateFont("kAuction2BidItemsWonFontGreen")
			fontGreen:CopyFontObject(GameTooltipText)
			fontGreen:SetTextColor(0,1,0)
			local fontYellow = CreateFont("kAuction2BidItemsWonFontYellow")
			fontYellow:CopyFontObject(GameTooltipText)
			fontYellow:SetTextColor(1,1,0)
			tip:SetCell(2, 1, "Normal", fontGreen);
			tip:SetCell(3, 1, "Offspec", fontYellow);
			tip:SetCell(4, 1, "Rot", fontRed);
			tip:Show();
		end
	end	
end
function kAuction2:OnBidNameOnEnter(frame)
	offset = FauxScrollFrame_GetOffset(kAuction2MainFrameBidScrollContainerScrollFrame);
	local _, _, row = string.find(frame:GetName(), "(%d+)");
	local bidType = kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row].bidType;
	local tip = kAuction2.qTip:Acquire("GameTooltip", 1, "LEFT")
	tip:Clear();
	tip:SetPoint("TOP", frame, "BOTTOM", 0, 0);
	tip:AddHeader(kAuction2.auctions[kAuction2.selectedAuctionIndex].bids[offset+row].name.."'s Bid Type:");
	tip:AddLine("");
	local fontRed = CreateFont("kAuction2BidItemsWonFontRed")
	fontRed:CopyFontObject(GameTooltipText)
	fontRed:SetTextColor(1,0,0)
	local fontGreen = CreateFont("kAuction2BidItemsWonFontGreen")
	fontGreen:CopyFontObject(GameTooltipText)
	fontGreen:SetTextColor(0,1,0)
	local fontYellow = CreateFont("kAuction2BidItemsWonFontYellow")
	fontYellow:CopyFontObject(GameTooltipText)
	fontYellow:SetTextColor(1,1,0)
	if bidType == "normal" then
		tip:SetCell(2, 1, "Normal", fontGreen);
	elseif bidType == "offspec" then
		tip:SetCell(2, 1, "Offspec", fontYellow);
	else
		tip:SetCell(2, 1, "Rot", fontRed);
	end
	tip:Show();
end
function kAuction2:OnCurrentItemEnter(frame)
	kAuction2:Debug("FUNC: OnCurrentItemEnter, frame: " .. frame:GetName(), 3);
	kAuction2Tooltip:Hide(); -- Clear tooltip
	offset = FauxScrollFrame_GetOffset(kAuction2MainFrameMainScrollContainerScrollFrame);
	local _, _, row = string.find(frame:GetName(), "(%d+)");
	local selectFrame;
	local localAuctionData = kAuction2:Client_GetLocalAuctionDataById(kAuction2.auctions[offset + row].id);	
	-- If active bid, menu locked, do not show
	if kAuction2.auctions[offset + row].currentItemSlot and not localAuctionData.bid and kAuction2:GetAuctionTimeleft(kAuction2.auctions[offset + row]) then
		--Current item mouse over, show select frame
		selectFrame = _G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrame"];
		--selectFrame = _G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrame", 1];
		local i = 1;
		local matchTable = kAuction2:Item_GetInventoryItemMatchTable(kAuction2.auctions[offset + row].currentItemSlot)
		while _G[selectFrame:GetName().."Button"..i] do
			if i <= #(matchTable) then
				_G[selectFrame:GetName().."Button"..i]:Show()
			end
			i=i+1;			
		end
	end
	-- Hide other Rows
	local iSelectFrame = 1;
	while _G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..iSelectFrame.."CurrentItemSelectFrame"] do
		if iSelectFrame ~= row then
			_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..iSelectFrame.."CurrentItemSelectFrame"]:Hide();
		end
		iSelectFrame = iSelectFrame + 1;
	end
	if kAuction2.auctions[offset + row].currentItemSlot then
		if not localAuctionData.bid and kAuction2:GetAuctionTimeleft(kAuction2.auctions[offset + row]) then
			selectFrame:Show();
		end
		-- Update tooltip
		if localAuctionData.currentItemLink ~= false then
			kAuction2:Gui_CurrentItemMenuOnEnter(frame,localAuctionData.currentItemLink);
		end
		kAuction2:Threading_StartTimer("kAuction2ThreadingFrameMain"..row);
		_G["kAuction2ThreadingFrameMain"..row]:Show();
	else
		if _G["kAuction2ThreadingFrameMain"..row] then
			_G["kAuction2ThreadingFrameMain"..row]:Hide();
		end
	end
end
function kAuction2:OnCurrentItemLeave(frame)
	kAuction2:Debug("FUNC: OnCurrentItemLeave, frame: " .. frame:GetName(), 1);
	local _, _, row = string.find(frame:GetName(), "(%d+)");
	_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrame"]:Hide();
end
function IsInPopoutMainFrameTimer(timerName)
	-- Hide other rows if needed
	local _, _, row = string.find(timerName, "(%d+)");
	if not kAuction2:IsInPopoutMainFrame(row) then
		local i = 1;
		while _G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrameButton"..i] do
			_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrameButton"..i]:Hide();
			i=i+1;
		end
		_G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItemSelectFrame"]:Hide();
		kAuction2:Threading_StopTimer(timerName);	
		_G[timerName]:Hide();
	end
end
function IsInPopoutBidsFrameTimer(timerName)
	-- Hide other rows if needed
	local _, _, row = string.find(timerName, "(%d+)");
	if not kAuction2:IsInPopoutBidsFrame(row) then
		local i = 1;
		while _G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWonSelectFrameButton"..i] do
			_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWonSelectFrameButton"..i]:Hide();
			i=i+1;
		end
		_G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWonSelectFrame"]:Hide();
		kAuction2:Threading_StopTimer(timerName);
		_G[timerName]:Hide();
	end
end
function kAuction2:IsInPopoutMainFrame(row)
	local objFrames = {};
	local objCurrentItemFrame = _G[kAuction2.db.profile.gui.frames.main.name.."MainScrollContainerAuctionItem"..row.."CurrentItem"];
	if objCurrentItemFrame then
		tinsert(objFrames, #(objFrames)+1, objCurrentItemFrame);
		if _G[objCurrentItemFrame:GetName().."SelectFrame"] then
			tinsert(objFrames, #(objFrames)+1, _G[objCurrentItemFrame:GetName().."SelectFrame"]);	
			local iButton = 1;
			while _G[objCurrentItemFrame:GetName().."SelectFrameButton"..iButton] do
				tinsert(objFrames, #(objFrames)+1, _G[objCurrentItemFrame:GetName().."SelectFrameButton"..iButton]);
				iButton=iButton+1;
			end
		end
	end
	local currentFrame = GetMouseFocus();
	for i,val in pairs(objFrames) do
		kAuction2:Debug("FUNC: IsInPopoutMainFrame, FrameCheck: "..val:GetName(), 2);
		if val == currentFrame then
			kAuction2:Debug("FUNC: IsInPopoutMainFrame, Row: "..row..", VALUE: true", 2);
			return true;
		end
	end
end
function kAuction2:IsInPopoutBidsFrame(row)
	local objFrames = {};
	local objCurrentItemFrame = _G[kAuction2.db.profile.gui.frames.main.name.."BidScrollContainerBid"..row.."ItemsWon"];
	if objCurrentItemFrame then
		tinsert(objFrames, #(objFrames)+1, objCurrentItemFrame);
		if _G[objCurrentItemFrame:GetName().."SelectFrame"] then
			tinsert(objFrames, #(objFrames)+1, _G[objCurrentItemFrame:GetName().."SelectFrame"]);	
			local iButton = 1;
			while _G[objCurrentItemFrame:GetName().."SelectFrameButton"..iButton] do
				tinsert(objFrames, #(objFrames)+1, _G[objCurrentItemFrame:GetName().."SelectFrameButton"..iButton]);
				iButton=iButton+1;
			end
		end
	end
	local currentFrame = GetMouseFocus();
	for i,val in pairs(objFrames) do
		kAuction2:Debug("FUNC: IsInPopoutBidsFrame, FrameCheck: "..val:GetName(), 2);
		if val == currentFrame then
			kAuction2:Debug("FUNC: IsInPopoutBidsFrame, Row: "..row..", VALUE: true", 2);
			return true;
		end
	end
end
function kAuction2:ZONE_CHANGED_NEW_AREA()
	-- Check if entering a valid raid zone
	if kAuction2.isInRaid == true and not kAuction2.isActiveRaid and kAuction2:Client_IsServer() then
		if kAuction2:Server_IsInValidRaidZone() then -- Check for valid zone
			StaticPopup_Show("kAuction2Popup_StartRaidTracking");
		end
	elseif kAuction2.isInRaid == true and kAuction2.isActiveRaid == true and kAuction2.enabled == true and kAuction2:Client_IsServer() and not kAuction2:Server_IsInValidRaidZone() and not UnitIsDeadOrGhost("player") then
		StaticPopup_Show("kAuction2Popup_StopRaidTracking");
	end
end
function kAuction2:SplitString(subject, delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( subject, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( subject, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( subject, delimiter, from  )
	end
	table.insert( result, string.sub( subject, from  ) )
	return result
end