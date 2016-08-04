-----------------------
--Global Variables
-----------------------
SLASH_ItemInvestigator1, SLASH_ItemInvestigator2 = "/ItemInvestigator", "/ii";
-----------------------
--Local Variables
-----------------------
local effectStats = {};
local wrongStatsForSpec = {};
local fivePercentStatsBonus = {};
local allItemSlots = {};
local upgradeLevels = {};
local cloakArmor = {};

local currentVersion = "1.3";
local gemFrame = CreateFrame('GameTooltip', 'SocketTooltip', UIParent, 'GameTooltipTemplate');
local addonLoaded = false;
local enabled = false;
local showHistory = false;
local events = {};
local inspectReady = true;
local inspectAchievementsReady = true;
local retryedInspect = false;
local lastInspect = nil;
local inCombat = false;
local debugMode = false;
local releaseMode = true;
local cultureCode = "";
local localizedText = {};
local playerCacheSize = 200;

-----------------------
-- Config Functions
----------------------

local configFrame = CreateFrame('Frame');
local configTitle = nil;
local configCheckboxSpec = nil;
local configCheckboxStatPrio = nil;
local configCheckboxScannedAgo = nil;
local configCheckboxRaid = nil;
local configCheckboxRaidsInCombat = nil;
local configCheckboxScanInCombat = nil;
local configCheckboxGuild = nil;

function ItemInvestigator_CreateCheckbox(label, description, onClick)
	local check = CreateFrame("CheckButton", "IAConfigCheckbox" .. label, configFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		onClick(self, self:GetChecked() and true or false)
	end)
	check.label = _G[check:GetName() .. "Text"]
	check.label:SetText(label)
	check.tooltipText = label
	check.tooltipRequirement = description
	return check
end

function ItemInvestigator_CreateConfigFrame()
	configTitle = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    configTitle:SetPoint("TOPLEFT", 16, -16)
    configTitle:SetText("ItemInvestigator")

    configCheckboxSpec = ItemInvestigator_CreateCheckbox(
    	LocalText("ConfigSpecLabel"),
    	LocalText("ConfigSpecLabelTooltip"),
    	function(self, value) ItemInvestigator_SetIncludeSpec(value) end)
    configCheckboxSpec:SetPoint("TOPLEFT", configTitle, "BOTTOMLEFT", 0, -8)

	configCheckboxScannedAgo = ItemInvestigator_CreateCheckbox(
		LocalText("ConfigScannedago"),
		LocalText("ConfigScannedagoTooltip"),
		function(self, value) ItemInvestigator_SetScannedAgo(value) end)
	configCheckboxScannedAgo:SetPoint("TOPLEFT", configCheckboxSpec, "BOTTOMLEFT", 0, -8)
	
	configCheckboxStatPrio = ItemInvestigator_CreateCheckbox(
		LocalText("ConfigStatPrio"),
		LocalText("ConfigStatPrioTooltip"),
		function(self, value) ItemInvestigator_SetStatPrio(value) end)
	configCheckboxStatPrio:SetPoint("TOPLEFT", configCheckboxScannedAgo, "BOTTOMLEFT", 0, -8)
	
    configCheckboxRaid = ItemInvestigator_CreateCheckbox(
    	LocalText("ConfigRaidsLabel"),
    	LocalText("ConfigRaidsLabelTooltip"),
    	function(self, value) ItemInvestigator_SetIncludeRaids(value) end)
    configCheckboxRaid:SetPoint("TOPLEFT", configCheckboxStatPrio, "BOTTOMLEFT", 0, -8)

    configCheckboxRaidsInCombat = ItemInvestigator_CreateCheckbox(
    	LocalText("ConfigRaidsInCombatLabel"),
        LocalText("ConfigRaidsInCombatLabelTooptip"),
    	function(self, value) ItemInvestigator_SetRaidsInCombat(value) end)
    configCheckboxRaidsInCombat:SetPoint("TOPLEFT", configCheckboxRaid, "BOTTOMLEFT", 24, -8)

    configCheckboxGuild = ItemInvestigator_CreateCheckbox(
    	LocalText("ConfigGuildLabel"),
        LocalText("ConfigGuildLabelTooltip"),
    	function(self, value) ItemInvestigator_SetIncludeGuild(value) end)
    configCheckboxGuild:SetPoint("TOPLEFT", configCheckboxRaidsInCombat, "BOTTOMLEFT", -24, -8)
	
	configCheckboxScanInCombat = ItemInvestigator_CreateCheckbox(
    	LocalText("ConfigScanInCombatLabel"),
        LocalText("ConfigScanInCombatLabelTooptip"),
    	function(self, value) ItemInvestigator_SetScanInCombat(value) end)
    configCheckboxScanInCombat:SetPoint("TOPLEFT", configCheckboxGuild, "BOTTOMLEFT", 0, -8)
end

function ItemInvestigator_RefreshConfigUI()
	configCheckboxSpec:SetChecked(ItemInvestigatorDB["include-spec"]);
	configCheckboxScannedAgo:SetChecked(ItemInvestigatorDB["include-scanned-ago"])
	configCheckboxRaid:SetChecked(ItemInvestigatorDB["include-raids"]);
	configCheckboxRaidsInCombat:SetChecked(ItemInvestigatorDB["raids-in-combat"]);
	configCheckboxScanInCombat:SetChecked(ItemInvestigatorDB["scan-in-combat"]);
	configCheckboxGuild:SetChecked(ItemInvestigatorDB["include-guild"]);
	configCheckboxStatPrio:SetChecked(ItemInvestigatorDB["include-stat-prio"])
end

-----------------------
-- Localization Functions
----------------------

function LocalText(textItem)
	if(localizedText[cultureCode] ~= nil and localizedText[cultureCode][textItem] ~= nil) then
		return localizedText[cultureCode][textItem];
	else
		return localizedText["enUS"][textItem];
	end
end

function ItemInvestigator_AddLocale(locale, localeTable)
	if(localizedText[locale] ~= nil) then
		localizedText[locale] = nil;
	end
	localizedText[locale] = localeTable;
end

-----------------------
-- Tooltip Functions
----------------------

function ItemInvestigator_GameTooltipActivated(self)
	local name, unitid = self:GetUnit()
	if(UnitIsPlayer(unitid) and enabled) then
		local foundPlayers = ItemInvestigator_GetPlayerByName(name);
		
		if(ItemInvestigator_tablelength(foundPlayers) == 0) then
			GameTooltip:AddLine(LocalText("StartAnalysis"), true);
		else
			local isNext = false;
			table.foreach(foundPlayers, function(index, player)
				if(isNext) then
					GameTooltip:AddLine("-----");
				end
				isNext = true;
				ItemInvestigator_AppendPlayerToTooltip(player);
			end);
		end
	end
end

function ItemInvestigator_AppendPlayerToTooltip(foundPlayer)
	for index,summaryItem in pairs(foundPlayer["summary"]) do
		GameTooltip:AddLine(summaryItem["Text"]);
	end
end

-----------------------
-- General Functions
----------------------

function ItemInvestigator_Enable()
	ItemInvestigator_Frame:RegisterEvent("ADDON_LOADED");
	ItemInvestigator_Frame:RegisterEvent("PLAYER_TARGET_CHANGED");
	ItemInvestigator_Frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	ItemInvestigator_Frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	--ItemInvestigator_Frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	enabled = true;
end

function ItemInvestigator_Disable()
	ItemInvestigator_Frame:UnregisterEvent("ADDON_LOADED");
	ItemInvestigator_Frame:UnregisterEvent("PLAYER_TARGET_CHANGED");
	ItemInvestigator_Frame:UnregisterEvent("PLAYER_REGEN_DISABLED");
	ItemInvestigator_Frame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	--ItemInvestigator_Frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");
	enabled = false;
end

function ItemInvestigator_SetIncludeSpec(b)
	ItemInvestigatorDB["include-spec"] = b;
    ItemInvestigator_InitializeDatabase();
    ItemInvestigatorDB["storedPlayers"] = {};
end

function ItemInvestigator_SetIncludeRaids(b)
	ItemInvestigatorDB["include-raids"] = b;
    ItemInvestigator_InitializeDatabase();
end

function ItemInvestigator_SetScannedAgo(b)
	ItemInvestigatorDB["include-scanned-ago"] = b;
    ItemInvestigator_InitializeDatabase();
end

function ItemInvestigator_SetStatPrio(b)
	ItemInvestigatorDB["include-stat-prio"] = b;
    ItemInvestigator_InitializeDatabase();
end

function ItemInvestigator_SetRaidsInCombat(b)
	ItemInvestigatorDB["raids-in-combat"] = b;
end

function ItemInvestigator_SetScanInCombat(b)
	ItemInvestigatorDB["scan-in-combat"] = b;
end

function ItemInvestigator_SetIncludeGuild(b)
	ItemInvestigatorDB["include-guild"] = b;
    ItemInvestigator_InitializeDatabase();
end

function ItemInvestigator_Reset()
	ItemInvestigatorDB = nil;
    ItemInvestigator_InitializeDatabase();
end

function ItemInvestigator_CommandHandler(msg)
	InterfaceOptionsFrame_OpenToCategory("ItemInvestigator");
	InterfaceOptionsFrame_OpenToCategory("ItemInvestigator");
end;

function ItemInvestigator_InitializeAddon()
	cultureCode = GetLocale();
	
	ItemInvestigator_Enable();
end

function ItemInvestigator_InitializeDatabase()
	if(ItemInvestigatorDB == nil or ItemInvestigatorDB["version"] ~= currentVersion) then
		local spec = (ItemInvestigatorDB and ItemInvestigatorDB["include-spec"]);
		if spec == nil then
			spec = false
		end
		local raids = (ItemInvestigatorDB and ItemInvestigatorDB["include-raids"]);
		if raids == nil then
        	raids = true
        end
        local raidsInCombat = (ItemInvestigatorDB and ItemInvestigatorDB["raids-in-combat"]);
        if raidsInCombat == nil then
        	raidsInCombat = false
        end
		local scanInCombat = (ItemInvestigatorDB and ItemInvestigatorDB["scan-in-combat"]);
        if scanInCombat == nil then
        	scanInCombat = true
        end
        local guild = (ItemInvestigatorDB and ItemInvestigatorDB["include-guild"]);
        if guild == nil then
        	guild = false
        end
		local scannedAgo = (ItemInvestigatorDB and ItemInvestigatorDB["include-scanned-ago"]);
        if scannedAgo == nil then
        	scannedAgo = true
        end
		
		local statPrio = (ItemInvestigatorDB and ItemInvestigatorDB["include-stat-prio"]);
        if statPrio == nil then
        	statPrio = true
        end
		
		ItemInvestigatorDB = {
			["version"] = currentVersion,
			["include-spec"] = spec,
			["include-raids"] = raids,
			["raids-in-combat"] = raidsInCombat,
			["scan-in-combat"] = scanInCombat,
			["include-guild"] = guild,
			["include-scanned-ago"] = scannedAgo,
			["include-stat-prio"] = statPrio,
			["storedPlayers"] = {},
			["localItemText"] = {}
		};
	end
end

function ItemInvestigator_InitializeLocalizationForAnalysis()
	if(ItemInvestigatorDB["localItemText"][cultureCode] == nil) then
		ItemInvestigatorDB["localItemText"][cultureCode] = {};
		
		ItemInvestigatorDB["localItemText"][cultureCode]["Cloth"] = ItemInvestigator_GetItemSubClassStringForItem(55998);
		ItemInvestigatorDB["localItemText"][cultureCode]["Leather"] = ItemInvestigator_GetItemSubClassStringForItem(59335);
		ItemInvestigatorDB["localItemText"][cultureCode]["Mail"] = ItemInvestigator_GetItemSubClassStringForItem(63447);
		ItemInvestigatorDB["localItemText"][cultureCode]["Plate"] = ItemInvestigator_GetItemSubClassStringForItem(75128);
		
		ItemInvestigatorDB["localItemText"][cultureCode]["One-Handed Maces"] = ItemInvestigator_GetItemSubClassStringForItem(56130);
		ItemInvestigatorDB["localItemText"][cultureCode]["Two-Handed Maces"] = ItemInvestigator_GetItemSubClassStringForItem(56131);
		ItemInvestigatorDB["localItemText"][cultureCode]["One-Handed Swords"] = ItemInvestigator_GetItemSubClassStringForItem(56101);
		ItemInvestigatorDB["localItemText"][cultureCode]["Two-Handed Swords"] = ItemInvestigator_GetItemSubClassStringForItem(63787);
		ItemInvestigatorDB["localItemText"][cultureCode]["One-Handed Axes"] = ItemInvestigator_GetItemSubClassStringForItem(63788);
		ItemInvestigatorDB["localItemText"][cultureCode]["Two-Handed Axes"] = ItemInvestigator_GetItemSubClassStringForItem(56284);
		ItemInvestigatorDB["localItemText"][cultureCode]["Daggers"] = ItemInvestigator_GetItemSubClassStringForItem(63792);
		ItemInvestigatorDB["localItemText"][cultureCode]["Fist Weapons"] = ItemInvestigator_GetItemSubClassStringForItem(52493);
		ItemInvestigatorDB["localItemText"][cultureCode]["Bows"] = ItemInvestigator_GetItemSubClassStringForItem(78480);
		ItemInvestigatorDB["localItemText"][cultureCode]["Guns"] = ItemInvestigator_GetItemSubClassStringForItem(60210);
		ItemInvestigatorDB["localItemText"][cultureCode]["Crossbows"] = ItemInvestigator_GetItemSubClassStringForItem(59598);
		
		if(debugMode) then
			for index,text in pairs(ItemInvestigatorDB["localItemText"][cultureCode]) do 
				print(index .. " = " .. text);
			end 
		end
		
		if(ItemInvestigator_tablelength(ItemInvestigatorDB["localItemText"][cultureCode]) ~= 15) then
			ItemInvestigatorDB["localItemText"][cultureCode] = nil;
			return false;
		end
	end
	
	return true;
end

function ItemInvestigator_GetItemSubClassStringForItem(itemId)
	local itemName, itemlink, itemQuality, itemIlvl, itemReqLevel, itemClass, itemSubclass, itemMaxStack, itemEquipSlot = GetItemInfo(itemId);
	return itemSubclass;
end

function ItemInvestigator_tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


-----------------------
-- Scanning Functions
-----------------------

function ItemInvestigator_CanInspectTarget()
	local hours, minutes = GetGameTime();

	if addonLoaded == true and (inspectReady or difftime(time(), lastInspect) > 30) and (CanInspect("target")) and (UnitIsPlayer("target")) then
		return true;
	end
	
	return false;
end

function ItemInvestigator_InspectTarget()
	if(ItemInvestigator_InitializeLocalizationForAnalysis()) then
		lastInspect = time();
		inspectReady = false;
		inspectAchievementsReady = false;
		ItemInvestigator_Frame:RegisterEvent("INSPECT_READY");
		ItemInvestigator_Frame:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
		if ItemInvestigatorDB["include-raids"] and (ItemInvestigatorDB["raids-in-combat"] or not inCombat or UnitIsDeadOrGhost("player")) then
			if AchievementFrameComparison and AchievementFrameComparison:IsShown() then
				AchievementFrame:Hide();
			end
			--##Fix UpdateStatusBar Error##
            --Achievement UI bugs out then this event is triggered
            --To make this work we temporarily disable it and re-enable when we are done.
		    if AchievementFrameComparison then
		    	AchievementFrameComparison:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
		    end
		    SetAchievementComparisonUnit("target");
		end
		NotifyInspect("target");
	end
end

function ItemInvestigator_InspectRaidProgress(player)
    if inspectAchievementsReady then
        local HFC_Normal = {10202, 10206, 10210, 10214, 10218, 10222, 10226, 10230, 10234, 10238, 10242, 10246, 10250};
        local HFC_Heroic = {10203, 10207, 10211, 10215, 10219, 10223, 10227, 10231, 10235, 10239, 10243, 10247, 10251};
        local HFC_Mythic = {10204, 10208, 10212, 10216, 10220, 10224, 10228, 10232, 10236, 10240, 10244, 10248, 10252};

        player["progress"]["HFC N"] = ItemInvestigator_CountProgress(HFC_Normal);
        player["progress"]["HFC H"] = ItemInvestigator_CountProgress(HFC_Heroic);
        player["progress"]["HFC M"] = ItemInvestigator_CountProgress(HFC_Mythic);
        player["progress"]["HFC Curve"] = GetAchievementComparisonInfo(10044);
        player["progress"]["HFC Edge"] = GetAchievementComparisonInfo(10045);

        ClearAchievementComparisonUnit();
    end
end

function ItemInvestigator_GetRealItemLevel(itemLink)
	local S_ITEM_LEVEL = "^"..gsub(ITEM_LEVEL, "%%d", "(%%d+)")
	local scantip = CreateFrame("GameTooltip", "HiddenTooltip", nil, "GameTooltipTemplate")
	scantip:SetOwner(UIParent, "ANCHOR_NONE")
	scantip:SetHyperlink(itemLink)
	for i=2,5 do 
		itemlvlLine = _G["HiddenTooltipTextLeft"..i]:GetText()	
		if itemlvlLine and itemlvlLine ~= "" then
			local realIlvl = strmatch(itemlvlLine, S_ITEM_LEVEL)
			if realIlvl then
				return tonumber(realIlvl)
			end
		end
	end				
end

function ItemInvestigator_TooltipScan(itemLink)
	local S_ITEM_UPGRADE_TOOLTIP_FORMAT = "^"..gsub(ITEM_UPGRADE_TOOLTIP_FORMAT, "%%d/", "(%%d+)/")
	local scantip = CreateFrame("GameTooltip", "HiddenTooltip", nil, "GameTooltipTemplate")
	local upgradedBool = false
	local timewarpedBool = false
	scantip:SetOwner(UIParent, "ANCHOR_NONE")
	scantip:SetHyperlink(itemLink)
	for i=2,6 do 
		tooltipLine = _G["HiddenTooltipTextLeft"..i]:GetText()
		if tooltipLine and tooltipLine ~= "" then
			local upgradelevel = strmatch(tooltipLine, S_ITEM_UPGRADE_TOOLTIP_FORMAT)
			if upgradelevel then
				upgradedBool = true
			end
			local timewarped = strfind(tooltipLine, LocalText("Timewarped"))
			if timewarped ~= nil then
				timewarpedBool = true
			end
		end
	end	
	return upgradedBool, timewarpedBool
end

function ItemInvestigator_ScanTarget()
	local playerName = UnitName("target");
	local class, classFileName = UnitClass("target");
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("target");
	local level = UnitLevel("target");
	local locRace, engRace = UnitRace("target");
	local currectSpec = GetInspectSpecialization("target");
	local specId, specName, specDescription, specIcon, specBackground, specRole, specClass = GetSpecializationInfoByID(currectSpec);
	local foundPlayerIndex = ItemInvestigator_GetOrCreatePlayer(playerName, specId);
	local storedPlayer = ItemInvestigatorDB["storedPlayers"][foundPlayerIndex];
	
	storedPlayer["race"] = engRace;
	storedPlayer["level"] = level;
	storedPlayer["class"] = classFileName;
	storedPlayer["specId"] = specId;
	storedPlayer["spec"] = specName;
	storedPlayer["guildName"] = guildName;
	storedPlayer["guildRankName"] = guildRankName;
	storedPlayer["guildRankIndex"] = guildRankIndex;
	storedPlayer["spec"] = specName;
	storedPlayer["scannedAt"] = time();
	storedPlayer["summary"] = {};
	storedPlayer["gear"] = {};
	storedPlayer["progress"] = {};
	storedPlayer["totalStats"] = {};
	if(debugMode) then
		for index,item in pairs(storedPlayer) do 
			print(index, item);
		end
	end
	
	local itemsScanned = 0;
	local upgradeableItems = 0;
	local totalItems = #allItemSlots;
	for index, slotName in pairs(allItemSlots) do
		local itemLink = GetInventoryItemLink("target", GetInventorySlotInfo(slotName));
		
		if(debugMode) then
			print("Scanning... ", slotName);
		end
		
		if(itemLink ~= nil) then
			storedPlayer["gear"][slotName] = {};
			if(debugMode) then
				print("The escaped link is: ", itemLink:gsub("|", "||"));
			end			
			
			--local _, _, color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Upgrade, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%d*)|?h?%[?([^%[%]c]*)%]?|?h?|?r?"); --somewhat outdated
			local itemName, itemlink, itemQuality, itemIlvl, itemReqLevel, itemClass, itemSubclass, itemMaxStack, itemEquipSlot = GetItemInfo(itemLink);
			local item, itemId, enchantId, gemId1, gemId2, gemId3, gemId4, suffixId, uniqueId, linkLevel, specializationID, upgradeId, instanceDifficultyId, numBonusIds, bonusId1, bonusId2, upgradeValue = strsplit(":", itemLink);
			local Enchant = enchantId;
			--[[print("item "..item)
			print("itemId "..itemId)
			print("enchantId "..enchantId)
			print("gemId1 "..gemId1)
			print("gemId2 "..gemId2)
			print("gemId3 "..gemId3)
			print("gemId4 "..gemId4)
			print("suffixId "..suffixId)
			print("uniqueId "..uniqueId)
			print("linkLevel "..linkLevel)
			print("specializationID "..specializationID)
			print("upgradeId "..upgradeId)
			print("instanceDifficultyId "..instanceDifficultyId)
			print("numBonusIds "..numBonusIds)
			print("bonusId1 "..bonusId1)
			print("bonusId2 "..bonusId2)
			print("upgradeValue "..upgradeValue)
			print("----")
			printable = gsub(itemLink, "\124", "\124\124");
			print(printable)]]--
			local stats = GetItemStats(itemLink);
			
			upgr, tw = ItemInvestigator_TooltipScan(itemLink)
			
			--if itemQuality == 7 or tw then -- if heirloom
				itemIlvl = ItemInvestigator_GetRealItemLevel(itemLink)
			--end
			
			if upgr then
				upgradeableItems = upgradeableItems + 1;
			end
			
			Upgrade = 0;
			Upgrade = string.match(itemLink, "(%d-):%d*:%d*:%d*|h%[") -- get the last digit of the itemLink (which is always the upgrade lvl; items have, depending on 3rd stat, socket etc. a different amount of digits in the itemString)



			storedPlayer["gear"][slotName]["link"] = itemLink;
			storedPlayer["gear"][slotName]["itemQuality"] = itemQuality;
			storedPlayer["gear"][slotName]["name"] = itemName;
			storedPlayer["gear"][slotName]["ilvl"] = itemIlvl;
			storedPlayer["gear"][slotName]["class"] = itemClass;
			storedPlayer["gear"][slotName]["subClass"] = itemSubclass;
			storedPlayer["gear"][slotName]["equipSlot"] = itemEquipSlot;
			storedPlayer["gear"][slotName]["enchant"] = Enchant;
			storedPlayer["gear"][slotName]["gems"] = {Gem1, Gem2, Gem3, Gem4};
			storedPlayer["gear"][slotName]["upgrade"] = Upgrade;
			storedPlayer["gear"][slotName]["stats"] = stats;
			storedPlayer["gear"][slotName]["emptySockets"] = ItemInvestigator_CountEmptySockets(itemLink);
			
			itemsScanned = itemsScanned + 1;
		end
	end
	storedPlayer["upgradeableItems"] = upgradeableItems;

	ItemInvestigator_InspectRaidProgress(storedPlayer);
	

	ItemInvestigator_ReleaseInspectData();
	
	if(ItemInvestigator_IsDualWielding(storedPlayer) == false) then totalItems = totalItems -1; end
	if retryedInspect == false and (itemsScanned / totalItems) < 0.75 and ItemInvestigator_CanInspectTarget() then
		
		if(debugMode) then
			print("Retrying... " .. itemsScanned .. "/" .. totalItems);
		end
		
		retryedInspect = true;
		ItemInvestigator_InspectTarget();
	else
		
		if(debugMode) then
			print("Done... " .. itemsScanned .. "/" .. totalItems);
		end
		
		retryedInspect = false;
		
		storedPlayer["equipedItems"] = itemsScanned;
		storedPlayer["slotsForItems"] = totalItems;
		
		
		ItemInvestigator_CalculatePlayer(storedPlayer);
		
		if(debugMode) then
			for index,gearTable in pairs(storedPlayer["gear"]) do 
				--for index2,item in pairs(gearTable) do 
				--	print(index,index2, item);
				--end
				for index2,item in pairs(gearTable["stats"]) do 
					print(index,index2, item);
				end 
			end
		end
		
		if (itemsScanned > 0) then
			if (ItemInvestigatorDB["scan-in-combat"]) then --if scan enabled		
				ItemInvestigator_AnalyzePlayer(storedPlayer);
				ItemInvestigator_ReinsertPlayerOnTop(foundPlayerIndex, storedPlayer);				
			elseif (not UnitAffectingCombat("player")) then -- if scan disabled AND player not in combat
				ItemInvestigator_AnalyzePlayer(storedPlayer);
				ItemInvestigator_ReinsertPlayerOnTop(foundPlayerIndex, storedPlayer);	
			end
		end
		
		GameTooltip:SetUnit("target");
		GameTooltip:Show();
	end;
end

function ItemInvestigator_IsDualWielding(player)
	if player["specId"] == 72 then
		return true;
	else
		if player["gear"]["MainHandSlot"] ~= nil and (	player["gear"]["MainHandSlot"]["equipSlot"] == "INVTYPE_2HWEAPON" or 
														player["gear"]["MainHandSlot"]["equipSlot"] == "INVTYPE_RANGED" or
														player["gear"]["MainHandSlot"]["equipSlot"] == "INVTYPE_RANGEDRIGHT") then
			return false;
		else
			return true;
		end
	end
end

function ItemInvestigator_CountEmptySockets(itemLink)
	local count = 0;

	for textureCount = 1, 10 do
		if _G["SocketTooltipTexture"..textureCount] then
			_G["SocketTooltipTexture"..textureCount]:SetTexture("");
		end
	end 
		
	gemFrame:SetOwner(UIParent, 'ANCHOR_NONE');
	gemFrame:ClearLines();
	gemFrame:SetHyperlink(itemLink);
		
	for textureCount = 1, 10 do
		local temp = _G["SocketTooltipTexture"..textureCount]:GetTexture();
		
		if temp and temp == "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta" then 
			count = count + 1;
		end
		if temp and temp == "Interface\\ItemSocketingFrame\\UI-EmptySocket-Red" then 
			count = count + 1;
		end
		if temp and temp == "Interface\\ItemSocketingFrame\\UI-EmptySocket-Yellow" then 
			count = count + 1;			
		end
		if temp and temp == "Interface\\ItemSocketingFrame\\UI-EmptySocket-Blue" then 
			count = count + 1;
		end
		if temp and temp == "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic" then 
			count = count + 1;
		end 
	end
	gemFrame:Hide();
	return count;
end;

function ItemInvestigator_ReleaseInspectData()
	inspectReady = true;
 	ClearInspectPlayer();
end

-----------------------
-- Player Functions
-----------------------

function ItemInvestigator_GetOrCreatePlayer(name, specId)
	local foundPlayerIndex = ItemInvestigator_GetPlayer(name, specId);	
	if (foundPlayerIndex == nil) then
		foundPlayerIndex = ItemInvestigator_CreatePlayer(name, specId);
	end
	
	return foundPlayerIndex;
end

function ItemInvestigator_GetPlayerByName(name)
	local foundPlayers = {};
	table.foreach(ItemInvestigatorDB["storedPlayers"], function(index, player)
		if(player["name"] == name) then
			table.insert(foundPlayers, player);
		end
	end);
	
	return foundPlayers;
end

function ItemInvestigator_GetPlayer(name, specId)
	local foundPlayerIndex = nil;
	table.foreach(ItemInvestigatorDB["storedPlayers"], function(index, player)
		if(player["name"] == name and (not ItemInvestigatorDB["include-spec"] or player["specId"] == specId)) then
			foundPlayerIndex = index;
		end
	end);
	
	return foundPlayerIndex;
end

function ItemInvestigator_CreatePlayer(name, specId)
	table.insert(ItemInvestigatorDB["storedPlayers"], 1, 
	{
		scannedAt = nil,
		name = name,
		specId = specId
	});
	
	if(getn(ItemInvestigatorDB["storedPlayers"]) > playerCacheSize) then
		table.remove(ItemInvestigatorDB["storedPlayers"]);
	end
	
	return ItemInvestigator_GetPlayer(name, specId);
end

function ItemInvestigator_ReinsertPlayerOnTop(index, player)
	table.remove(ItemInvestigatorDB["storedPlayers"],index)
	table.insert(ItemInvestigatorDB["storedPlayers"],1,player);
end

-----------------------
-- Analysis Functions
-----------------------

function ItemInvestigator_CalculatePlayer(player)
	--ItemInvestigator_CalculateUpgradedStats(player);
	ItemInvestigator_CalculateEnchantedStats(player);
	ItemInvestigator_CalculateGemedStats(player);
	ItemInvestigator_CalculateTotalStat(player);
end

function ItemInvestigator_CalculateUpgradedStats(player)
	for index,gearTable in pairs(player["gear"]) do
		local bilzardFactor = 1.14; --1.06035 (5.1) upped it a bit to compensate ;
		local upgradeLevel = upgradeLevels[gearTable["upgrade"]] or -1;
		local upgradePercentage = (gearTable["ilvl"] + upgradeLevel) / gearTable["ilvl"];

		if(not releaseMode and gearTable["ilvl"] >= 272 and gearTable["upgrade"] ~= "0" and upgradeLevel == -1) then
			print("IA: Unknown upgrade " .. gearTable["upgrade"] .. " in item " .. gearTable["link"]);
		end
		
		if (upgradeLevel ~= 0) then
			for stat, value in pairs(gearTable["stats"]) do
				if value > 0 and (ItemInvestigator_IsPrimaryStat(stat) or ItemInvestigator_IsSecondaryStat(stat)) then
					gearTable["stats"][stat] = math.floor(value * upgradePercentage * bilzardFactor);
				end
			end
		end
	end
end

function ItemInvestigator_CalculateEnchantedStats(player)
	for index,gearTable in pairs(player["gear"]) do
		local enchantId = gearTable["enchant"]
		if (enchantId ~= "0") then
			if(effectStats[enchantId] ~= nil) then
				local enchantStats = effectStats[enchantId];
				for statName,statValue in pairs(enchantStats) do
					if(gearTable["stats"][statName]) then
						gearTable["stats"][statName] = gearTable["stats"][statName] + statValue;
					else
						gearTable["stats"][statName] = statValue;
					end
				end 
			else
				if(not releaseMode and gearTable["ilvl"] >= 272) then
					print("IA: Unknown enchant " .. enchantId .. " in item " .. gearTable["link"]);
				end
			end
		end
	end
end

function ItemInvestigator_CalculateGemedStats(player)
	for index,gearTable in pairs(player["gear"]) do
		for index2,gemId in pairs(gearTable["gems"]) do
			if (gemId ~= "0") then
				if(effectStats[gemId] ~= nil) then
					local gemStats = effectStats[gemId];
					for statName,statValue in pairs(gemStats) do
						if(gearTable["stats"][statName]) then
							gearTable["stats"][statName] = gearTable["stats"][statName] + statValue;
						else
							gearTable["stats"][statName] = statValue;
						end
					end 
				else
					if(not releaseMode and gearTable["ilvl"] >= 272) then
						print("IA: Unknown gem " .. gemId .. " in socket " .. index2 .. " of item " .. gearTable["link"]);
					end
				end
			end
		end
	end
end

function ItemInvestigator_CalculateTotalStat(player)
	for index,gearTable in pairs(player["gear"]) do
		if gearTable["stats"] ~= nil then
			for stat, value in pairs(gearTable["stats"]) do
				if value > 0 then
					if not ItemInvestigator_CanHaveBonusArmor(index) and stat == "RESISTANCE0_NAME" then
					else
						local ilvl = gearTable["ilvl"] + (upgradeLevels[gearTable["upgrade"]] or 0)
						if ilvl < 500 and index == "BackSlot" and stat == "RESISTANCE0_NAME" then
						else
							if player["totalStats"][stat] == nil then
								player["totalStats"][stat] = 0;
							end
							
							if index == "BackSlot" and stat == "RESISTANCE0_NAME" then
								local bonusArmor = 0 
								if ilvl >= 500 and ilvl < 600 then
									bonusArmor = value - ((cloakArmor[ilvl] or (0.00148*ilvl^2-1.378*ilvl+329.477)) + 0)
								elseif ilvl >= 600 then
									bonusArmor = value - ((cloakArmor[ilvl] or (0.001523*ilvl^2-1.622*ilvl+461.18)) + 0)
								end
								if bonusArmor > 0 then
									player["totalStats"][stat] = player["totalStats"][stat] + bonusArmor;
								end
							else
								player["totalStats"][stat] = player["totalStats"][stat] + value;
							end
						end
					end
				end
			end
		end
	end
	
	local bonusStat = nil
	for specs,stat in pairs(fivePercentStatsBonus) do
		if specs[player["specId"]] then
			bonusStat = stat;
		end
	end
	
	for stat,value in pairs(player["totalStats"]) do
		if stat == bonusStat then
			player["totalStats"][stat] = player["totalStats"][stat] * 1.05
		end
		
		player["totalStats"][stat] = math.floor(player["totalStats"][stat]);
	end
	
end

-----------------------
-- Analysis Functions
-----------------------

function ItemInvestigator_AnalyzePlayer(player)
    local minutesDiff = math.floor((difftime (time(), player["scannedAt"]) / 60)+0.5);

	if (ItemInvestigatorDB["include-scanned-ago"]) then
		if(minutesDiff < 60) then
			local summaryItem = {Item = "time", Text = string.format(LocalText("ScannedMinutesAgo"), minutesDiff), Value = minutesDiff};
			table.insert(player["summary"], summaryItem);
		else
			local summaryItem = {Item = "time", Text = string.format(LocalText("ScannedHoursAgo"), math.floor((minutesDiff/60)+0.5)), Value = minutesDiff};
			table.insert(player["summary"], summaryItem);
		end
	end

    if ItemInvestigatorDB["include-guild"] and player["guildRankName"] then
        local summaryItem = {Item = "guildRank", Text = string.format(LocalText("Rank"), player["guildRankName"], player["guildRankIndex"]), Value = player["guildRankName"]};
        table.insert(player["summary"], summaryItem);
    end

    if(player["spec"] ~= nil) then
        local summaryItem = {Item = "spec", Text = string.format(LocalText("Spec"),player["spec"]), Value = player["spec"]};
        table.insert(player["summary"], summaryItem);
    end

	if (ItemInvestigatorDB["include-stat-prio"]) then
		ItemInvestigator_CheckStatPrio(player, 4);
	end
	ItemInvestigator_CalculateAverageItemLevel(player);
	ItemInvestigator_AddProgress(player);

	ItemInvestigator_CheckMissingOrNotScannedItems(player);
	ItemInvestigator_CheckForUpgrades(player);
	ItemInvestigator_CheckForPvPItems(player);
	
	ItemInvestigator_CheckForMissingEnchants(player);
	ItemInvestigator_CheckForMissingGems(player);

	ItemInvestigator_CheckForArmorSpecialization(player);
	ItemInvestigator_CheckWrongStatsForSpec(player);
	
	ItemInvestigator_GetLegendaryRingUpgrade(player);
	
	--if(ItemInvestigator_IsAHealer(player)) then
	--	ItemInvestigator_AddEmptyLine(player);
	--	ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_SPIRIT_SHORT");
	--end
	
	--if(ItemInvestigator_IsATank(player)) then
	--	ItemInvestigator_AddEmptyLine(player);
	--	ItemInvestigator_CheckTotalStat(player, "RESISTANCE0_NAME");
	--	ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_MASTERY_RATING_SHORT");
	--end
	
	--Show primary stat totals
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_STRENGTH_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_AGILITY_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_INTELLECT_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_STAMINA_SHORT");
	
	--Show secondary stat totals
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_SPIRIT_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_DODGE_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_PARRY_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_CRIT_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_HASTE_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_MASTERY_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_SPELL_POWER_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_ATTACK_POWER_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "RESISTANCE0_NAME");
	
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_CR_MULTISTRIKE_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_CR_LIFESTEAL_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_VERSATILITY");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_CR_AVOIDANCE_SHORT");
	
	--Weapon Damage
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_DAMAGE_PER_SECOND_SHORT");
	
	--PvP Stats
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_RESILIENCE_RATING_SHORT");
	--ItemInvestigator_CheckTotalStat(player, "ITEM_MOD_PVP_POWER_SHORT");
	
	---if(debugMode) then
	--	for index,summaryItem in pairs(player["summary"]) do
	--		print(summaryItem["Text"]);
	--	end
	--end
end

function ItemInvestigator_CheckStatPrio(player, amount)
	
	local topStats = {};
	local topStatText = "";
	local i = 0;
	while i < amount do
		local highestStat = "";
		local highestValue = 0;
		for stat,value in pairs(player["totalStats"]) do 
			if (topStats[stat] == nil and ItemInvestigator_IsSecondaryStat(stat) and value > highestValue) then
				highestStat = stat;
				highestValue = value
			end
		end
		i = i + 1;
		if(highestStat ~= "") then
			topStats[highestStat] = highestValue;
			topStatText = topStatText .. _G[highestStat];
			if(i < amount) then
				topStatText = topStatText .. " > "
			end
		end
	end
	
	local summaryItem = {Item = "statPrio", Text = topStatText, Value = ""};
	table.insert(player["summary"], summaryItem);
end

function ItemInvestigator_CalculateAverageItemLevel(player)
	local totalItemLevel = 0;
	for index,gearTable in pairs(player["gear"]) do
		--totalItemLevel = totalItemLevel + gearTable["ilvl"] + (upgradeLevels[gearTable["upgrade"]] or 0);
		totalItemLevel = totalItemLevel + gearTable["ilvl"]; --removed (upgradeLevels[gearTable["upgrade"]] or 0) due to changed derivation of ilvl
		--print(gearTable["link"] .. " = " .. gearTable["ilvl"] .. " + " .. (upgradeLevels[gearTable["upgrade"]] or 0));
	end
	
	local avgIlvl = floor(totalItemLevel / player["equipedItems"]);
	
	local summaryItem = {Item = "avgItemLvl", Text = string.format(LocalText("AvgIlvl"), avgIlvl), Value = avgIlvl};
	table.insert(player["summary"], summaryItem);
end

function ItemInvestigator_FormatProgress(n,h,m,c,e)
    if n and h and m then
        local progressString = "";
        for i = 1, #n do
            if m[i] == true then
                progressString = progressString .. "|cFFFF0000" .. LocalText("RaidMythic");
            elseif h[i] == true then
                progressString = progressString .. "|cFFFF6600" .. LocalText("RaidHeroic");
            elseif n[i] == true then
                progressString = progressString .. "|cFFFFFF00" .. LocalText("RaidNormal");
            else
                progressString = progressString .. "_"
            end
        end

        if e then
           	progressString = progressString .. "|cFFFF0000" .. " (" .. LocalText("Edge") .. ")";
        elseif c then
        	progressString = progressString .. "|cFFFF6600" .. " (" .. LocalText("Curve") .. ")";
        end

        return progressString;
    elseif ItemInvestigatorDB["include-raids"] then
        return LocalText("NA")
    end
end

function ItemInvestigator_GetLegendaryRingUpgrade(player)
	local ring1iLvL = 0;
	local ring2iLvL = 0;
	local ringiLvL = 0;
	
	for index,gearTable in pairs(player["gear"]) do
		if index == "Finger0Slot" then
			ring1iLvL = player["gear"]["Finger0Slot"]["itemQuality"]
			if ring1iLvL == 5 then --legendary
				ringiLvL = player["gear"]["Finger0Slot"]["ilvl"]
			end
		end
		if index == "Finger1Slot" then
			ring2iLvL = player["gear"]["Finger1Slot"]["itemQuality"]
			if ring2iLvL == 5 then
				ringiLvL = player["gear"]["Finger1Slot"]["ilvl"]		
			end
		end
	end	

	if tonumber(ringiLvL) > 0 then
		local upgrades = (ringiLvL-735)/3;
		local summaryItem = {Item = "RingUpgrades", Text = "|cffff8000" .. string.format(LocalText("RingUpgrades"),upgrades, "20",ringiLvL), Value = upgrades};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_AddProgress(player)
    local n = player["progress"]["HFC N"];
    local h = player["progress"]["HFC H"];
    local m = player["progress"]["HFC M"];
    local c = player["progress"]["HFC Curve"];
    local e = player["progress"]["HFC Edge"];

    local progress = ItemInvestigator_FormatProgress(n, h, m, c, e);
    if progress then
		local summaryItem = {Item = "ProgressHFC", Text = string.format(LocalText("ProgressHFC"), progress), Value = progress};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckForUpgrades(player)
	local upgradedItems = 0;
	for index,gearTable in pairs(player["gear"]) do
		if((upgradeLevels[gearTable["upgrade"]] or 0) > 0) then
			upgradedItems = upgradedItems + 1;
		end
	end
	
	if(upgradedItems > 0) then
		local summaryItem = {Item = "hasUpgrades", Text = "|cff88ff88" .. string.format(LocalText("HasUpgrades"), upgradedItems, --[[player["equipedItems"]--]] player["upgradeableItems"]), Value = avgIlvl};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckMissingOrNotScannedItems(player)
	local missingOrNotScannedItems = player["slotsForItems"] - player["equipedItems"];
	if (missingOrNotScannedItems > 0) then
		local summaryItem = {Item = "missingItems", Text = "|cffff00ff" .. LocalText("IncompleteScan"), Value = missingOrNotScannedItems};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckForMissingEnchants(player)
	local totalMissingEnchants = 0;
	for index,gearTable in pairs(player["gear"]) do
		--print(gearTable["link"] .. " = " .. gearTable["enchant"])
		if gearTable["enchant"] == "" then
			if 	index == "NeckSlot" or
				index == "BackSlot" or 
				index == "Finger0Slot" or 
				index == "Finger1Slot" or
				index == "MainHandSlot" then
				totalMissingEnchants = totalMissingEnchants + 1;
			end;
		end;
	end
	
	if(totalMissingEnchants > 0) then
		local summaryItem = {Item = "emptySockets", Text = "|cffff0000" .. string.format(LocalText("MissingEnchants"), totalMissingEnchants), Value = totalMissingEnchants};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckForMissingGems(player)
	local totalEmptySockets = 0;
	for index,gearTable in pairs(player["gear"]) do
		totalEmptySockets = totalEmptySockets + gearTable["emptySockets"];
	end
	
	if(totalEmptySockets > 0) then
		local summaryItem = {Item = "emptySockets", Text = "|cffff0000" .. string.format(LocalText("MissingGems"),totalEmptySockets), Value = totalEmptySockets};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckForPvPItems(player)
	local totalPvPItems = 0;
	for index,gearTable in pairs(player["gear"]) do
		if gearTable["stats"]["ITEM_MOD_PVP_POWER_SHORT"] and gearTable["stats"]["ITEM_MOD_PVP_POWER_SHORT"] > 0 then
			totalPvPItems = totalPvPItems + 1;
		end
	end
	
	if(totalPvPItems > 0) then
		local summaryItem = {Item = "pvpItems", Text = "|cff8888ff" .. string.format(LocalText("HasPVPItems"), totalPvPItems), Value = totalPvPItems};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckTotalStat(player, stat)
	local summaryItem = {Item = "totalStat_" .. stat, Text = string.format(LocalText("StatsFromGear"), (player["totalStats"][stat] or 0 ), _G[stat]), Value = player["totalStats"][stat]};
	table.insert(player["summary"], summaryItem);
end

function ItemInvestigator_CheckForArmorSpecialization(player)
	local armorSpecBonus = true;
	local armorSpecBonusType = ItemInvestigator_GetArmorSpecBonusType(player);
	for index,slotName in pairs(allItemSlots) do
		if (slotName ~= "NeckSlot" and 
			slotName ~= "BackSlot" and 
			slotName ~= "Finger0Slot" and 
			slotName ~= "Finger1Slot" and 
			slotName ~= "Trinket0Slot" and 
			slotName ~= "Trinket1Slot" and
			slotName ~= "MainHandSlot" and
			slotName ~= "SecondaryHandSlot"
		   )then
			if(player["gear"][slotName] == nil or player["gear"][slotName]["subClass"] ~= armorSpecBonusType) then
				armorSpecBonus = false;
			end
		end;
	end
	
	if(armorSpecBonus == false) then
		local summaryItem = {Item = "armorSpecBonus", Text = "|cffff0000" .. LocalText("NoArmorSpecialization"), Value = 0};
		table.insert(player["summary"], summaryItem);
	end
end

function ItemInvestigator_CheckWrongStatsForSpec(player)
	if(player["specId"] ~= nil) then
		local wrongStatsTable = nil
		for specs,statsTable in pairs(wrongStatsForSpec) do
			if specs[player["specId"]] then
				wrongStatsTable = statsTable;
			end
		end
		local wrongStats = {};
		for index,stat in pairs(wrongStatsTable) do
			if player["totalStats"][stat] == nil or player["totalStats"][stat] == 0 then
			else
				table.insert(wrongStats, stat);
			end
		end
		
		if #wrongStats > 0 then
			local wrongStatsText = "";
			local i = 1;
			while i <= #wrongStats do
				wrongStatsText = wrongStatsText .. _G[wrongStats[i]];
				i = i + 1;
				if(i <= #wrongStats) then
					wrongStatsText = wrongStatsText .. ", "
				end
			end
			local summaryItem = {Item = "wrongStats", Text = "|cffff0000" ..  string.format(LocalText("WrongGear"), wrongStatsText), Value = 0};
			table.insert(player["summary"], summaryItem);
		end
	end
end

function ItemInvestigator_CountProgress(stats)
    local progress = {}
    for i, id in pairs(stats) do
    	if GetComparisonStatistic(id) == "--" then
    	    progress[i] = false;
    	else
    	    progress[i] = true;
    	end
    end
    return progress;
end

function ItemInvestigator_IsATank(player)
	local spec = player["specId"];
	
	if (spec == 104 or 
		spec == 250 or
		spec == 73 or
		spec == 66 or
		spec == 268 or
		spec == 577
		) then
		return true;
	end
	
	return false;
end

function ItemInvestigator_IsAMeleeDPS(player)
	local class = player["class"];
	local spec = player["specId"];
	
	if (spec == 251 or 
		spec == 252 or
		spec == 103 or 
		class == "HUNTER" or
		spec == 70 or
		class == "ROGUE" or
		spec == 263 or
		spec == 71 or
		spec == 72 or
		spec == 269 or
		spec == 581
		) then
		return true;
	end
	
	return false;
end

function ItemInvestigator_IsACasterDPS(player)
	local class = player["class"];
	local spec = player["specId"];
	
	if (spec == 258 or 
		class == "MAGE" or
		spec == 102 or
		spec == 262 or
		class == "WARLOCK"
		) then
		return true;
	end
	
	return false;
end

function ItemInvestigator_IsAHealer(player)
	local spec = player["specId"];
	
	if (spec == 257 or 
		spec == 256 or
		spec == 105 or 
		spec == 264 or
		spec == 65 or
		spec == 270
		) then
		return true;
	end
	
	return false;
end

function ItemInvestigator_IsPrimaryStat(stat)
	if(	stat == "ITEM_MOD_STRENGTH_SHORT" or
		stat == "ITEM_MOD_AGILITY_SHORT" or
		stat == "ITEM_MOD_INTELLECT_SHORT") then
		return true;
	end
	
	return false;
end

function ItemInvestigator_IsSecondaryStat(stat)
	if(	stat == "ITEM_MOD_SPIRIT_SHORT" or
		stat == "ITEM_MOD_CRIT_RATING_SHORT" or
		stat == "ITEM_MOD_HASTE_RATING_SHORT" or
		stat == "ITEM_MOD_MASTERY_RATING_SHORT" or
		stat == "RESISTANCE0_NAME" or
		stat == "ITEM_MOD_CR_MULTISTRIKE_SHORT" or
		stat == "ITEM_MOD_VERSATILITY") then
		return true;
	end
	
	return false;
end

function ItemInvestigator_CanHaveBonusArmor(slot)
	if(	slot == "NeckSlot" or
		slot == "BackSlot" or
		slot == "Finger0Slot" or
		slot == "Trinket1Slot" or
		slot == "Trinket0Slot" or
		slot == "Trinket1Slot") then
		return true;
	end
	
	return false;
end

function ItemInvestigator_GetArmorSpecBonusType(player)
	if(player["class"] == "WARRIOR" or player["class"] == "PALADIN" or player["class"] == "DEATHKNIGHT") then
		return ItemInvestigatorDB["localItemText"][cultureCode]["Plate"];
	end
	if(player["class"] == "SHAMAN" or player["class"] == "HUNTER") then
		return ItemInvestigatorDB["localItemText"][cultureCode]["Mail"];
	end
	if(player["class"] == "ROGUE" or player["class"] == "DRUID" or player["class"] == "MONK" or player["class"] == "DEMONHUNTER") then
		return ItemInvestigatorDB["localItemText"][cultureCode]["Leather"];
	end
	if(player["class"] == "MAGE" or player["class"] == "WARLOCK" or player["class"] == "PRIEST") then
		return ItemInvestigatorDB["localItemText"][cultureCode]["Cloth"];
	end
end

-----------------------
--External Data Loaders
-----------------------

function ItemInvestigator_AddEmptyLine(player)
	local dummyItem = {Item = "dummy", Text = " ", Value = ""};
	table.insert(player["summary"], dummyItem);
end

function ItemInvestigator_LoadEffectStats(dataTable)
	effectStats = nil;
	effectStats = dataTable;
end

function ItemInvestigator_LoadWrongStatsForSpec(dataTable)
	wrongStatsForSpec = nil;
	wrongStatsForSpec = dataTable;
end

function ItemInvestigator_LoadFivePercentStatsBonus(dataTable)
	fivePercentStatsBonus = nil;
	fivePercentStatsBonus = dataTable;
end

function ItemInvestigator_LoadAllItemSlots(dataTable)
	allItemSlots = nil;
	allItemSlots = dataTable;
end

function ItemInvestigator_LoadUpgradeLevels(dataTable)
	upgradeLevels = nil;
	upgradeLevels = dataTable;
end

function ItemInvestigator_LoadCloakArmor(dataTable)
	cloakArmor = nil;
	cloakArmor = dataTable;
end

-----------------------
--Event Handlers
-----------------------
function ItemInvestigator_OnEvent(self, event, ...)
	events[event](self, ...);
end

function events:ADDON_LOADED(arg0, ...)
	if(string.lower(arg0) == string.lower("ItemInvestigator")) then
		addonLoaded = true;
		ItemInvestigator_InitializeDatabase();
		ItemInvestigator_InitializeLocalizationForAnalysis();

		ItemInvestigator_CreateConfigFrame();
        configFrame.name = "ItemInvestigator";
        configFrame.refresh = ItemInvestigator_RefreshConfigUI;
        configFrame.default = ItemInvestigator_Reset;
		InterfaceOptions_AddCategory(configFrame)
	end
end

function events:PLAYER_TARGET_CHANGED(...)
	if ItemInvestigator_CanInspectTarget() then
		ItemInvestigator_InspectTarget();
	end
end

function events:UPDATE_MOUSEOVER_UNIT()
	print("FIRED")
	--local storedPlayer = ItemInvestigator_GetPlayerByName(name)
	--if storedPlayer then
		local name = UnitName("mouseover")
		local unitid = "mouseover";
		if(UnitIsPlayer(unitid) and enabled) then
			print("FIRED 2")
			local foundPlayers = ItemInvestigator_GetPlayerByName(name);
			
			if(ItemInvestigator_tablelength(foundPlayers) == 0) then
				GameTooltip:AddLine(LocalText("StartAnalysis"), true);
			else
				local isNext = false;
				table.foreach(foundPlayers, function(index, player)
					if(isNext) then
						GameTooltip:AddLine("-----");
					end
					isNext = true;
					ItemInvestigator_AppendPlayerToTooltip(player);
				end);
			end
		end
	--end
end

function events:INSPECT_READY()
	ItemInvestigator_Frame:UnregisterEvent("INSPECT_READY");
 	ItemInvestigator_ScanTarget();
end

function events:INSPECT_ACHIEVEMENT_READY()
	ItemInvestigator_Frame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
	--##Fix UpdateStatusBar Error##
	--Reenables the event for the comparison window
	if AchievementFrameComparison then
    	AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
    end
	inspectAchievementsReady = true;
end

function events:PLAYER_REGEN_DISABLED()
	inCombat = true;
end

function events:PLAYER_REGEN_ENABLED()
	inCombat = false;
end

GameTooltip:HookScript("OnTooltipSetUnit", ItemInvestigator_GameTooltipActivated);
SlashCmdList["ItemInvestigator"]=function(msg) ItemInvestigator_CommandHandler(msg) end;