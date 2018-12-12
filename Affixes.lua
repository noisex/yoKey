local L, yo = unpack( select( 2, ...))

local tonumber, floor, ceil, abs, mod, modf, format, len, sub = tonumber, math.floor, math.ceil, math.abs, math.fmod, math.modf, string.format, string.len, string.sub

local rowCount = 3
local affCount = 3
local iSize = 35
local requestKeystoneCheck, currentWeek, registered

local challengeMapID
local TIME_FOR_3 = 0.6
local TIME_FOR_2 = 0.8

local yo_OldKey, yo_OldKey2 = nil, nil

local mythicRewards = {
--	{"Level","End","Weekly","Azer Weekly"},
	{2,345,350,340},
	{3,345,355,340},
	{4,350,360,355},
	{5,355,360,355},
	{6,355,365,355},
	{7,360,370,370},
	{8,365,370,370},
	{9,365,375,370},
	{10,370,380,385},
}

--Сундук в подземелье

--Ключ	Награда
--2	375
--3	375
--4	380
--5	385
--6	385
--7	390
--8	395
--9	395
--10+	400
--       	Еженедельный ларь

--Ключ	Награда
--2	385
--3	385
--4	390
--5	390
--6	395
--7	400
--8	400
--9	405
--10+	410

-- 1: Overflowing, 2: Skittish, 3: Volcanic, 4: Necrotic, 5: Teeming, 6: Raging, 7: Bolstering, 8: Sanguine, 9: Tyrannical, 10: Fortified, 11: Bursting, 12: Grievous, 13: Explosive, 14: Quaking

local affixWeeksLegs = { --affixID as used in C_ChallengeMode.GetAffixInfo(affixID)
    [1] = {[1]=6,[2]=3,[3]=9,[4]=16},
    [2] = {[1]=5,[2]=13,[3]=10,[4]=16},
    [3] = {[1]=7,[2]=12,[3]=9,[4]=16},
    [4] = {[1]=8,[2]=4,[3]=10,[4]=16},
    [5] = {[1]=11,[2]=2,[3]=9,[4]=16},
    [6] = {[1]=5,[2]=14,[3]=10,[4]=16},
    [7] = {[1]=6,[2]=4,[3]=9,[4]=16},
    [8] = {[1]=7,[2]=2,[3]=10,[4]=16},
    [9] = {[1]=5,[2]=3,[3]=9,[4]=16},
    [10] = {[1]=8,[2]=12,[3]=10,[4]=16},
    [11] = {[1]=7,[2]=13,[3]=9,[4]=16},
    [12] = {[1]=11,[2]=14,[3]=10,[4]=16},
}
--TODO Change this once BFA hits
local affixWeeks = { --affixID as used in C_ChallengeMode.GetAffixInfo(affixID)
    [1] = {[1]=9,[2]=6,[3]=3,[4]=16},
    [2] = {[1]=10,[2]=5,[3]=13,[4]=16},
    [3] = {[1]=9,[2]=7,[3]=12,[4]=16},
    [4] = {[1]=10,[2]=8,[3]=4,[4]=16},
    [5] = {[1]=9,[2]=11,[3]=2,[4]=16},
    [6] = {[1]=10,[2]=5,[3]=14,[4]=16},
    [7] = {[1]=9,[2]=6,[3]=4,[4]=16},
    [8] = {[1]=10,[2]=7,[3]=2,[4]=16},
    [9] = {[1]=9,[2]=5,[3]=3,[4]=16},
    [10] = {[1]=10,[2]=8,[3]=12,[4]=16},
    [11] = {[1]=9,[2]=7,[3]=13,[4]=16},
    [12] = {[1]=10,[2]=11,[3]=14,[4]=16},
}

local function GuildLeadersOnLeave(...)
    GameTooltip:Hide()
end

local function GuildLeadersOnEnter( self)
	--local leaderInfo = self.leadersInfo;

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    local name = C_ChallengeMode.GetMapUIInfo(self.leadersInfo.mapChallengeModeID);
    GameTooltip:SetText(name, 1, 1, 1);
    GameTooltip:AddLine(CHALLENGE_MODE_POWER_LEVEL:format(self.leadersInfo.keystoneLevel));
    for i = 1, #self.leadersInfo.members do
        local classColorStr = RAID_CLASS_COLORS[self.leadersInfo.members[i].classFileName].colorStr;
        GameTooltip:AddLine(CHALLENGE_MODE_GUILD_BEST_LINE:format(classColorStr,self.leadersInfo.members[i].name));
    end
    GameTooltip:Show();
end

local function CreateLeadersIcon( self, index)
	if not self[index] then
		local frame = CreateFrame("Frame", nil, self)
		if index == 1 then
			frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		else
			frame:SetPoint("TOPLEFT", self[index-1], "BOTTOMLEFT", 0, -5)
		end
		frame:SetSize( iSize +10, iSize +10)

		frame.icon = frame:CreateTexture(nil, "OVERLAY")
		frame.icon:SetAllPoints(frame)
		--frame.icon:SetTexCoord( 0.365, 0.636, 0.352, 0.742)

		frame.level = frame:CreateFontString(nil, "OVERLAY")
		frame.level:SetFont( font, fontsize + 4, "OUTLINE")
		frame.level:SetTextColor( 1, 0.75, 0, 1)
		frame.level:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 1)

		frame.mapname = frame:CreateFontString(nil, "ARTWORK")
		frame.mapname:SetFont( font, fontsize, "OUTLINE")
		frame.mapname:SetTextColor( 1, 0.75, 0, 1)
		frame.mapname:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 5, 0)

		frame.leadername = frame:CreateFontString(nil, "ARTWORK")
		frame.leadername:SetFont( font, fontsize, "OUTLINE")
		frame.leadername:SetPoint("LEFT", frame.icon, "RIGHT", 5, 0)
		CreateStyle( frame, 4, 2)

		frame:SetScript("OnEnter", GuildLeadersOnEnter)
		frame:SetScript("OnLeave", GuildLeadersOnLeave)

		self[index] = frame
	end

	return self[index]
end

local function CreateLiders( self)

	local leaders = C_ChallengeMode.GetGuildLeaders()
	if leaders and #leaders > 0 then

		if not self.leaderBest then
			self.leaderBest = CreateFrame("Frame", nil, ChallengesFrame)
			self.leaderBest:SetSize(175, ( 35+5) * #leaders)
			self.leaderBest:SetPoint("TOPLEFT", ChallengesFrame, "TOPLEFT", 10, -120)

			self.leaderBest.title = self.leaderBest:CreateFontString(nil, "ARTWORK")
			self.leaderBest.title:SetFont( font, fontsize + 3, "OUTLINE")
			self.leaderBest.title:SetTextColor( 1, 0.75, 0, 1)
			self.leaderBest.title:SetText(  L["WeekLeader"])
			self.leaderBest.title:SetPoint("BOTTOM", self.leaderBest, "TOP", -15, 10)
		end

		for ind, leadersInfo in ipairs( leaders) do
   			local icons = CreateLeadersIcon( self.leaderBest, ind)
			local map, _, _, mapTexture =  C_ChallengeMode.GetMapUIInfo( leadersInfo.mapChallengeModeID)

			icons.level:SetText( leadersInfo.keystoneLevel)
			icons.leadername:SetText( "|c" .. RAID_CLASS_COLORS[leadersInfo.classFileName].colorStr .. leadersInfo.name)
			icons.mapname:SetText( map)
			icons.icon:SetTexture( mapTexture)

			icons.leadersInfo = leadersInfo
		end
	end
end

local function CheckInventoryKeystone()
	local keyslink = nil

	local newname = UnitName("player")
	local realm = GetRealmName()
	if yo_AllData == nil then
		yo_AllData = {}
	end

	if yo_AllData[realm] == nil then
		yo_AllData[realm] = {}
	end

	if yo_AllData[realm][newname] == nil then
		yo_AllData[realm][newname] = {}
	end
	yo_AllData[realm][newname]["KeyStone"] = nil
	yo_AllData[realm][newname]["KeyStoneDay"] = nil
	yo_AllData[realm][newname]["KeyStoneTime"] = nil

	for container=BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		for slot=1, slots do  -- 198 16 8 4 10  -- keystone:challengeMapID:mythicLevel:isActive:affix1:affix2:affix3
			local _, _, _, _, _, _, slotLink = GetContainerItemInfo(container, slot)
			local itemString = slotLink and slotLink:match("|Hkeystone:([0-9:]+)|h(%b[])|h")

			if itemString then
				keyslink  = slotLink
				yo_AllData[realm][newname]["KeyStone"] = slotLink
				yo_AllData[realm][newname]["KeyStoneDay"] = date()
				yo_AllData[realm][newname]["KeyStoneTime"] = time()
			end
		end
	end
	requestKeystoneCheck = false

	return keyslink
end

local function skinDungens()
	for k, map in pairs( ChallengesFrame.DungeonIcons) do
		map.HighestLevel:ClearAllPoints()
		map.HighestLevel:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", -1, 2)

		map.Icon:SetHeight( map:GetHeight() - 4)
		map.Icon:SetWidth( map:GetWidth() - 4)
		map.Icon:SetTexCoord(unpack( yo.tCoord))
		map:GetRegions(1):SetAtlas( nil) --GetAtlas())
		if not map.shadow then
			CreateStyle( map, 4)
		end
	end
end

local function UpdateAffixes( self)
	ChallengesFrame.WeeklyInfo.Child.RunStatus:SetFont( font, fontsize + 2, "OUTLINE")
	ChallengesFrame.WeeklyInfo.Child.RunStatus:ClearAllPoints()
	ChallengesFrame.WeeklyInfo.Child.RunStatus:SetPoint("TOP", ChallengesFrame, "TOP", 0, -150)
	ChallengesFrame.WeeklyInfo.Child.RunStatus:SetWidth( 250)
	ChallengesFrame.WeeklyInfo.Child.RunStatus.ClearAllPoints = dummy

	C_MythicPlus.RequestCurrentAffixes()
    local affixIds = C_MythicPlus.GetCurrentAffixes() --table
    if not affixIds then return end
    --tprint( affixIds)
    for week, affixes in ipairs( affixWeeks) do
       	--if affixes[1] == affixIds[3] and affixes[2] == affixIds[1] and affixes[3] == affixIds[2] then
       	if affixes[1] == affixIds[1].id and affixes[2] == affixIds[2].id and affixes[3] == affixIds[3].id then
           	currentWeek = week
       	end
    end

	if currentWeek then
		for i = 1, rowCount do
			local entry = yo_WeeklyAffixes.Frame.Entries[i]
			entry:Show()

			local scheduleWeek = (currentWeek - 2 + i) % 12 + 1
			local affixes = affixWeeks[scheduleWeek]
			for j = 1, affCount do
				local affix = entry.Affixes[j]
				affix:SetUp( affixes[j])
			end
		end
	end
	CreateLiders( ChallengesFrame)
	skinDungens()
end

local function makeAffix(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(iSize +2, iSize +2)  --(16, 16)

	local border = frame:CreateTexture(nil, "OVERLAY")
	border:SetAllPoints()
	border:SetAtlas("ChallengeMode-AffixRing-Sm")
	frame.Border = border

	local portrait = frame:CreateTexture(nil, "ARTWORK")
	portrait:SetSize( iSize, iSize)  --(14, 14)
	portrait:SetPoint("CENTER", border)
	frame.Portrait = portrait

	frame.SetUp = ScenarioChallengeModeAffixMixin.SetUp
	frame:SetScript("OnEnter", ScenarioChallengeModeAffixMixin.OnEnter)
	frame:SetScript("OnLeave", GameTooltip_Hide)

	return frame
end

local function Blizzard_ChallengesUI( self)
	local frame = CreateFrame("Frame", nil, ChallengesFrame)
	frame:SetSize( (iSize + 10) * affCount, (iSize + 7) * rowCount + 50 + 120)
	frame:SetPoint("TOPRIGHT", ChallengesFrame.WeeklyInfo.Child, "TOPRIGHT", -6, -15)
	self.Frame = frame

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetAtlas("ChallengeMode-guild-background")
	bg:SetAlpha( .4)

	local title = frame:CreateFontString(nil, "ARTWORK")--, "GameFontNormalMed1")
	title:SetFont( font, fontsize + 3, "OUTLINE")
	title:SetTextColor(1, 0.75, 0, 1)
	title:SetText( L["Schedule"])
	title:SetPoint("TOP", 0, -7)

	local line = frame:CreateTexture(nil, "ARTWORK")
	line:SetSize( frame:GetWidth() - 10, 9)
	line:SetAtlas("ChallengeMode-RankLineDivider", false)
	line:SetPoint("TOP", 0, -20)

	local Levels = frame:CreateFontString(nil, "ARTWORK") --, "GameFontNormalMed1")
	Levels:SetFont( font, fontsize + 3, "OUTLINE")
	Levels:SetTextColor( 0.5, 0.5, 0.5, 1)
	--Levels:SetText( "2+      4+      7+      10+")
	Levels:SetText( "2+      4+      7+")
	Levels:SetPoint("TOPLEFT", 20, -29)

	local line2 = frame:CreateTexture(nil, "ARTWORK")
	line2:SetSize( frame:GetWidth() - 10, 9)
	line2:SetAtlas("ChallengeMode-RankLineDivider", false)
	line2:SetPoint("TOP", 0, -39)

	local line3 = frame:CreateTexture(nil, "ARTWORK")
	line3:SetSize( frame:GetWidth() - 10, 9)
	line3:SetAtlas("ChallengeMode-RankLineDivider", false)
	line3:SetPoint("TOP", 0, -(iSize + 7) * rowCount - 50)

	local title2 = frame:CreateFontString(nil, "ARTWORK")--, "GameFontNormalMed1")
	title2:SetFont( font, fontsize + 3, "OUTLINE")
	title2:SetTextColor(1, 0.75, 0, 1)
	title2:SetText( L["Rewards"])
	title2:SetPoint("TOP", line3, "BOTTOM", 0, 0)

	local line4 = frame:CreateTexture(nil, "ARTWORK")
	line4:SetSize( frame:GetWidth() - 10, 9)
	line4:SetAtlas("ChallengeMode-RankLineDivider", false)
	line4:SetPoint("TOP", title2, "BOTTOM", 0, 0)

	local outReward = "|cffffc300Level  Reward   Week Azer|r\n"
	for i, v in ipairs( mythicRewards ) do
		outReward = outReward .. format("|cffff0000%5d|r|cff00ffff%10d%10d/|cffff9900%d\n", v[1], v[2], v[3], v[4])
	end

	local rewards = frame:CreateFontString(nil, "ARTWORK") --, "GameFontNormalMed1")
	rewards:SetFont( font, fontsize, "OUTLINE")
	rewards:SetText( outReward)
	rewards:SetJustifyH("LEFT")
	rewards:SetPoint("TOP", line4, "BOTTOM", 0, 0)

	local entries = {}
	for i = 1, rowCount do
		local entry = CreateFrame("Frame", nil, frame)
		entry:SetSize( frame:GetWidth(), iSize)

		local affixes = {}
		local prevAffix
		for j = 1, affCount, 1 do
			local affix = makeAffix(entry)
			if prevAffix then
				affix:SetPoint("LEFT", prevAffix, "RIGHT", 5, 0)
			else
				affix:SetPoint("LEFT", 5, 0)
			end
			prevAffix = affix
			affixes[j] = affix
		end
		entry.Affixes = affixes

		if i == 1 then
			entry:SetPoint("TOP", line2, "BOTTOM", 0, -5)
		else
			entry:SetPoint("TOP", entries[i-1], "BOTTOM", 0, -5)
		end

		entries[i] = entry
	end
	frame.Entries = entries
	hooksecurefunc("ChallengesFrame_Update", UpdateAffixes)
end

local function SlotKeystone()
	for container=BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		for slot=1, slots do
			local _, _, _, _, _, _, slotLink, _, _, slotItemID = GetContainerItemInfo(container, slot)
			if slotLink and slotLink:match("|Hkeystone:") then
				PickupContainerItem(container, slot)
				if (CursorHasItem()) then
					C_ChallengeMode.SlotKeystone()
				end
			end
		end
	end
end

local function OnEvent( self, event, name, sender, ...)

	if event == "ADDON_LOADED" and name == "Blizzard_ChallengesUI" then
		Blizzard_ChallengesUI( self)
		ChallengesKeystoneFrame:HookScript("OnShow", SlotKeystone)

	elseif event == "BAG_UPDATE" then
		requestKeystoneCheck = true

	elseif event == "PLAYER_ENTERING_WORLD" then
		--self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		if not registered then
			self:RegisterEvent("ADDON_LOADED")
			self:RegisterEvent("BAG_UPDATE")

			self:RegisterEvent("CHAT_MSG_PARTY_LEADER")
			self:RegisterEvent("CHAT_MSG_PARTY")
			self:RegisterEvent("CHAT_MSG_GUILD")
			self:RegisterEvent("CHAT_MSG_LOOT")
			self:RegisterEvent("CHAT_MSG_WHISPER")
			registered = true
		end

		challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
		yo_OldKey = CheckInventoryKeystone()

	elseif event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_PARTY" then
		name = strlower( name)
		if name == "!key" or name == "!ключ" or name == "!keys" then
			local keys = CheckInventoryKeystone()
			if keys then
				SendChatMessage( keys, "PARTY")
			end
		end
	elseif event == "CHAT_MSG_GUILD" then
		name = strlower( name)
		if name == "!key" or name == "!ключ" or name == "!keys" then
			local keys = CheckInventoryKeystone()
			if keys then
				SendChatMessage( keys, "GUILD")
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		name = strlower( name)
		if name == "!key" or name == "!ключ" or name == "!keys" then
			local keys = CheckInventoryKeystone()
			if keys then
				SendChatMessage( keys, "WHISPER", "Common", sender)
			end
		end

	elseif event == "CHAT_MSG_LOOT" then

		--local b = name:match("Эпохальный ключ")
		local c = name:match("|Hkeystone:")
		local y = name:match("^Вы ")
		local z = name:match("^Ваша ")

	--	--print( name, b, c, y, z, a)
		if ( z or y) and ( b or c ) then
			local keys = CheckInventoryKeystone()
			print( "KEY Find: ", name, b, c, y, z)
			if keys then
				print( "WIN: ", b or c)
			--SendChatMessage( a, "PARTY")
			end
		end

	elseif event == "CHALLENGE_MODE_START"  or event == "CHALLENGE_MODE_RESET" then
		challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
		yo_OldKey = CheckInventoryKeystone()

	elseif event == "CHALLENGE_MODE_COMPLETED" then

		if not challengeMapID then return end

		local mapID, level, time, onTime, keystoneUpgradeLevels = C_ChallengeMode.GetCompletionInfo()
		local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(challengeMapID)

		timeLimit = timeLimit * 1000
		local timeLimit2 = timeLimit * TIME_FOR_2
		local timeLimit3 = timeLimit * TIME_FOR_3

		--print(name, level, timeFormatMS(time), timeFormatMS(time - timeLimit), L["completion0"])
		--"Гробница королей"," 2, "1:05:01.321", "26:01.321"
		--L["completion0"] = "|cff8787ED[%s] %s|r окончили за |cffff0000%s|r, вы отстали на %s от общего лимита времени."
		print("|cff00ffff--------------------------------------------------------------------------")
		print( "|cff00ffff" .. LANDING_PAGE_REPORT)
		print("|cff00ffff--------------------------------------------------------------------------")
		if time <= timeLimit3 then
			DEFAULT_CHAT_FRAME:AddMessage( format( L["completion3"], level, name, timeFormatMS(time), timeFormatMS(timeLimit3 - time)), 255/255, 215/255, 1/255)
		elseif time <= timeLimit2 then
			DEFAULT_CHAT_FRAME:AddMessage( format( L["completion2"], level, name, timeFormatMS(time), timeFormatMS(timeLimit2 - time), timeFormatMS(time - timeLimit3)), 199/255, 199/255, 199/255)
		elseif onTime then
			DEFAULT_CHAT_FRAME:AddMessage( format( L["completion1"], level, name, timeFormatMS(time), timeFormatMS(timeLimit - time), timeFormatMS(time - timeLimit2)), 237/255, 165/255, 95/255)
		else
			DEFAULT_CHAT_FRAME:AddMessage( format( L["completion0"], name, level, timeFormatMS(time), timeFormatMS(time - timeLimit)), 255/255, 32/255, 32/255)
		end
		print("|cff00ffff--------------------------------------------------------------------------")

		yo_OldKey2 = CheckInventoryKeystone()
		C_Timer.After( 2, function()
			local newKey = CheckInventoryKeystone()
			print("Debug: OLd: ", yo_OldKey, ". OLd2: ", yo_OldKey2, ". New: " , newKey)
			if newKey and newKey ~= yo_OldKey then
				--print(yo_OldKey, newKey)
				SendChatMessage( newKey, "PARTY")
			end
		end)
	end
end


local logan = CreateFrame("Frame", "yo_WeeklyAffixes", UIParent)
	logan:RegisterEvent("PLAYER_ENTERING_WORLD")

	logan:RegisterEvent("CHALLENGE_MODE_COMPLETED");
    logan:RegisterEvent("CHALLENGE_MODE_RESET");
    logan:RegisterEvent("CHALLENGE_MODE_START")
	logan:SetScript("OnEvent", OnEvent)


----------------------------------------------------------------------------------
---			ObjectiveTracker ( Angry KeyStone)
----------------------------------------------------------------------------------

local timeFormat = timeFormat
local timeFormatMS = timeFormatMS

local function GetTimerFrame(block)
	if not block.TimerFrame then
		local TimerFrame = CreateFrame("Frame", nil, block)
		TimerFrame:SetAllPoints(block)

		TimerFrame.Text2 = TimerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		TimerFrame.Text2:SetPoint("LEFT", block.TimeLeft, "LEFT", 70, 0)

		TimerFrame.Text = TimerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		TimerFrame.Text:SetPoint("LEFT", TimerFrame.Text2, "LEFT", 50, 0)

		TimerFrame.Bar3 = TimerFrame:CreateTexture(nil, "OVERLAY")
		TimerFrame.Bar3:SetPoint("TOPLEFT", block.StatusBar, "TOPLEFT", block.StatusBar:GetWidth() * (1 - TIME_FOR_3) - 4, 4)
		TimerFrame.Bar3:SetSize(2, 14)
		TimerFrame.Bar3:SetTexture( texture)
		TimerFrame.Bar3:SetVertexColor( 0, 1, 0, 1)
		--TimerFrame.Bar3:SetTexCoord(0, 0.5, 0, 1)

		TimerFrame.Bar2 = TimerFrame:CreateTexture(nil, "OVERLAY")
		TimerFrame.Bar2:SetPoint("TOPLEFT", block.StatusBar, "TOPLEFT", block.StatusBar:GetWidth() * (1 - TIME_FOR_2) - 4, 4)
		TimerFrame.Bar2:SetSize(2, 14)
		TimerFrame.Bar2:SetTexture( texture)
		TimerFrame.Bar2:SetVertexColor(0, 1, 0, 1)
		--TimerFrame.Bar2:SetTexCoord(0.5, 1, 0, 1)

		TimerFrame:Show()

		block.TimerFrame = TimerFrame
	end
	return block.TimerFrame
end

local function UpdateTime(block, elapsedTime)
	local TimerFrame = GetTimerFrame(block)

	local time3 = block.timeLimit * TIME_FOR_3
	local time2 = block.timeLimit * TIME_FOR_2

	TimerFrame.Bar3:SetShown(elapsedTime < time3)
	TimerFrame.Bar2:SetShown(elapsedTime < time2)

	if elapsedTime < time3 then
		TimerFrame.Text:SetText( timeFormat(time3 - elapsedTime) )
		TimerFrame.Text:SetTextColor(1, 0.843, 0)
		TimerFrame.Text:Show()
		if true then --Addon.Config.silverGoldTimer then
			TimerFrame.Text2:SetText( timeFormat(time2 - elapsedTime) )
			TimerFrame.Text2:SetTextColor(0.78, 0.78, 0.812)
			TimerFrame.Text2:Show()
		else
			TimerFrame.Text2:Hide()
		end
	elseif elapsedTime < time2 then
		TimerFrame.Text:SetText( timeFormat(time2 - elapsedTime) )
		TimerFrame.Text:SetTextColor(0.78, 0.78, 0.812)
		TimerFrame.Text:Show()
		TimerFrame.Text2:Hide()
	else
		TimerFrame.Text:Hide()
		TimerFrame.Text2:Hide()
	end

	if elapsedTime > block.timeLimit then
		block.TimeLeft:SetText(GetTimeStringFromSeconds(elapsedTime - block.timeLimit, false, true))
	end
end

local function ShowBlock(timerID, elapsedTime, timeLimit)
	local block = ScenarioChallengeModeBlock
	local level, affixes, wasEnergized = C_ChallengeMode.GetActiveKeystoneInfo()
	local dmgPct, healthPct = C_ChallengeMode.GetPowerLevelDamageHealthMod(level)
	if true then --Addon.Config.showLevelModifier then
		block.Level:SetText( format("%s, +%d%%", CHALLENGE_MODE_POWER_LEVEL:format(level), dmgPct) )
	else
		block.Level:SetText(CHALLENGE_MODE_POWER_LEVEL:format(level))
	end
end

local function ProgressBar_SetValue(self, percent)
	if self.criteriaIndex then
		local _, _, _, _, totalQuantity, _, _, quantityString, _, _, _, _, _ = C_Scenario.GetCriteriaInfo(self.criteriaIndex)
		local currentQuantity = quantityString and tonumber( strsub(quantityString, 1, -2) )
		if currentQuantity and totalQuantity then
			--	self.Bar.Label:SetFormattedText("%.2f%%", currentQuantity/totalQuantity*100)
			--	self.Bar.Label:SetFormattedText("%d/%d", currentQuantity, totalQuantity)
			--	self.Bar.Label:SetFormattedText("%.2f%% - %d/%d", currentQuantity/totalQuantity*100, currentQuantity, totalQuantity)
			self.Bar.Label:SetFormattedText("%.2f%% (%.2f%%)", currentQuantity/totalQuantity*100, (totalQuantity-currentQuantity)/totalQuantity*100)
			--	self.Bar.Label:SetFormattedText("%d/%d (%d)", currentQuantity, totalQuantity, totalQuantity - currentQuantity)
			--	self.Bar.Label:SetFormattedText("%.2f%% (%.2f%%) - %d/%d (%d)", currentQuantity/totalQuantity*100, (totalQuantity-currentQuantity)/totalQuantity*100, currentQuantity, totalQuantity, totalQuantity - currentQuantity)
		end
	end
end

hooksecurefunc("Scenario_ChallengeMode_UpdateTime", UpdateTime)
hooksecurefunc("Scenario_ChallengeMode_ShowBlock", ShowBlock)
hooksecurefunc("ScenarioTrackerProgressBar_SetValue", ProgressBar_SetValue)
