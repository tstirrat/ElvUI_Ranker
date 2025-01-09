local E = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local String = "%s: %s"
local Panel

local FormatLargeNumber = FormatLargeNumber
local GetPVPThisWeekStats = GetPVPThisWeekStats
local GetPVPRankInfo = GetPVPRankInfo
local GetPVPRankProgress = GetPVPRankProgress
local Ranker = Ranker
local format = format

local debug = true

-- Ranker vars copied, sorry
local maxObtainableRank = 14
local lookupData = {
    defaults = {
        showWindowByDefault = false,
        showContributionPointsVarianceBug = true,
        useCurrentHonorWhenModeling = true,
        allowDecayPreventionHop = true,
        knowsboutMinimumHK = false,
        rankerObjective = 14,
        rankerLimit = 500000,
        contributionPointsVarianceThreshold = 16,
        hideHelpfulInformation = false,
    }, 
    rankChangeFactor = {1, 1, 1, 0.8, 0.8, 0.8, 0.7, 0.7, 0.6, 0.5, 0.5, 0.4, 0.4, 0.34, 0.34},
    contributionPointsFloor = {0, 2000, 5000, 10000, 15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 55000, 60000},
    contributionPointsCeiling = {2000, 5000, 10000, 15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 55000, 60000, 65000},
    honorToContributionPointsRatio = {45000/20000, 45000/20000, 45000/20000, 45000/20000, 45000/20000, 45000/20000, (175000-45000)/(40000-20000), (175000-45000)/(40000-20000), (175000-45000)/(40000-20000), (175000-45000)/(40000-20000), (500000-175000)/(60000-40000), (500000-175000)/(60000-40000), (500000-175000)/(60000-40000), (500000-175000)/(60000-40000)},
    honorIncrements = {0, 4500, 11250, 22500, 33750, 45000, 77500, 110000, 142500, 175000, 256250, 337500, 418750, 500000},
    contributionPointsVariances = {
        ["3_4"] = {min = 10, max = 10},
        ["4_3"] = {min = 10},
        ["5_2"] = {min = 10},
        ["6_1"] = {min = 10, max = 10},
        ["6_2"] = {min = 10, max = 0},
        ["6_3"] = {min = 10, max = 0},
        ["6_4"] = {min = 10, max = 0},
        ["7_1"] = {min = 10, max = 10},
        ["7_2"] = {min = 10, max = 10},
        ["7_3"] = {min = 10, max = 10},
        ["7_4"] = {min = 10, max = 0},
        ["8_3"] = {min = 10, max = 10},
        ["9_2"] = {min = 10, max = 10},
        ["10_1"] = {min = 10, max = 10},
        ["10_2"] = {min = 10, max = 0},
        ["10_3"] = {min = 10, max = 0},
        ["10_4"] = {min = 14, max = 6},
        ["11_1"] = {min = 10, max = 10},
        ["11_2"] = {min = 10, max = 10},
        ["11_3"] = {min = 4, max = 16},
        ["12_2"] = {min = 14, max = 6},
        ["13_1"] = {min = 14, max = 6},
    },
    contributionPointsVariancesException = {
        ["10_4"] = {min = 4},
        ["11_3"] = {min = 14},
    },
    contributionPointsVariancesReplace = {
        ["11_1"] = {max = 10, progressFloor = 0.49795, progressCeil = 0.49805},
        ["11_2"] = {max = 10, progressFloor = 0.49795, progressCeil = 0.49805},
    },
}

local rankerOptions = lookupData.defaults
-- TODO: grab this from the Ranker UI if possible
local rankerObjective = 14

local verb = "will"
local maxRank = 14
local objectiveMet = false

local printOptions = function(options)
    local stop = false
    local output = ""
    
    for key = 1, #options do
        if options[key].honorRemains and options[key].honorRemains > 0 and options[key].rank <= rankerObjective and options[key].situation ~= "+1" and stop ~= true then
            Ranker:OutputToChat("Option #: "..options[key].number.." ("..options[key].situation.."): rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).." with "..FormatLargeNumber(options[key].honorNeed).." honor (missing "..FormatLargeNumber(options[key].honorRemains)..").", debug)
            if maxObtainableRank == options[key].rank then stop = true end
            if options[key].situation == "!!" then
                if lookupData.defaults.allowDecayPreventionHop == true then
                    output = output .."You can obtain |cffe6cc80rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).."|r with "..FormatLargeNumber(options[key].honorNeed).." honor."
                end
            else
                output = output .."You can obtain |cffe6cc80rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).."|r with "..FormatLargeNumber(options[key].honorNeed).." honor."
            end
            if (options[key].situation == "!!" and lookupData.defaults.allowDecayPreventionHop == true) or options[key].situation ~= "!!" then
                output = output .."        You need |cffe6cc80"..FormatLargeNumber(options[key].honorRemains).." more|r honor."
            end
        elseif (options[key].honorRemains and options[key].honorRemains <= 0) or (options[key].rank <= rankerObjective) and options[key].situation ~= "+1" and stop ~= true then
            Ranker:OutputToChat("Option #: "..options[key].number.." ("..options[key].situation.."): rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).." with "..FormatLargeNumber(options[key].honorNeed).." honor.", debug)
            if (options[options[key].number+1] and options[options[key].number+1].honorRemains > 0) or not options[options[key].number+1] then
                if options[key].situation == "!!" then
                    if lookupData.defaults.allowDecayPreventionHop == true then
                        if options[key].rank >= rankerObjective then objectiveMet = true maxRank = options[key].rank verb = "will" end
                        output = output .."You "..verb.." be |cffe6cc80rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).."|r."
                    end
                else
                    if options[key].rank >= rankerObjective then objectiveMet = true maxRank = options[key].rank verb = "will" end
                    output = output .."You "..verb.." be |cffe6cc80rank "..options[key].rank.." and "..format("%.2f%%", options[key].rankProgress*100).."|r."
                end
            end
        end
    end
    -- print(output)
end

local getCurrentMilestone = function(r, currentHonor)
    for key = 1, #r do
        if (r[key].honorNeed > currentHonor) then
            -- print(format("found: remains: %d, need: %d ", r[key].honorRemains, r[key].honorNeed))
            return r[key]
        end
    end
    return nil
end

local MAX_WEEKLY_HONOR = 500000

local OnEvent = function(self)
    local _, rank = GetPVPRankInfo(UnitPVPRank("player"), "player")

    local _, currentHonor = GetPVPThisWeekStats()
    local rankProgress = floor(GetPVPRankProgress() * 10000000000) / 10000000000

    
    local milestones = Ranker:ChooseYourOwnAdventure(rank, MAX_WEEKLY_HONOR, rankProgress)
    -- printOptions(milestones)

    local current = getCurrentMilestone(milestones, currentHonor)

    if not current then
        self.text:SetFormattedText(String, "Ranker", "N/A")
    else

        self.text:SetFormattedText(String, "Ranker", "-" .. FormatLargeNumber(current.honorNeed - currentHonor))
    end

	if (not Panel) then
		Panel = self
	end
end

local OnClick = function()
	if E.Classic then
		ToggleCharacter("HonorFrame")
	elseif E.Wrath then
		TogglePVPFrame()
	else
		ToggleCharacter("PVPFrame")
	end
end

local OnEnter = function(self)
	DT:SetupTooltip(self)
	local Rank = UnitPVPRank("player")
    
	if (Rank > 0) then
        local rankProgress = floor(GetPVPRankProgress() * 10000000000) / 10000000000
		local _, rankNumber = GetPVPRankInfo(Rank, "player")

		DT.tooltip:AddDoubleLine("Rank", format("R%d + %.2f%%", rankNumber, rankProgress * 100))
	end

    local _, rank = GetPVPRankInfo(UnitPVPRank("player"), "player")

    local _, currentHonor = GetPVPThisWeekStats()

    
    local rankProgress = floor(GetPVPRankProgress() * 10000000000) / 10000000000
    local options = Ranker:ChooseYourOwnAdventure(rank, MAX_WEEKLY_HONOR, rankProgress)
    -- print(format("rank: %d, honor cap: %d, progress: %.2f%%", rank, MAX_WEEKLY_HONOR, rankProgress * 100))
    -- printOptions(options)

    local stop = false
    local output = ""

    DT.tooltip:AddLine(" ")
    DT.tooltip:AddLine("Milestones")
    
    for key = 1, #options do
        local m = options[key]
        if m.honorNeed > currentHonor and m.rank <= rankerObjective and m.situation ~= "+1" and stop ~= true then
            if maxObtainableRank == m.rank then stop = true end
            DT.tooltip:AddDoubleLine(FormatLargeNumber(m.honorNeed), format("R%d + %.2f%%", m.rank, m.rankProgress * 100), 1, 1, 1, 1, 1, 1)

            local remain = m.honorNeed - currentHonor

            if (m.situation == "!!" and lookupData.defaults.allowDecayPreventionHop == true) or m.situation ~= "!!" and remain > 0 then
                DT.tooltip:AddDoubleLine(" ", "-" .. FormatLargeNumber(remain), 1, 1, 1, 1, 1, 1)
            end
            DT.tooltip:AddLine(" ")
        end
    end

    -- MARKS
    local abMarkCount = GetItemCount(20559, true)
    local avMarkCount = GetItemCount(20560, true)
    local wgMarkCount = GetItemCount(20558, true)

    if abMarkCount >= 3 or avMarkCount >= 3 or wgMarkCount >= 3 then
        DT.tooltip:AddLine(" ")
        DT.tooltip:AddLine("Mark of Honor (x3)")
    end

    local turIns = 0
    if abMarkCount >= 3 then
        turnIns = floor(abMarkCount / 3)
        DT.tooltip:AddDoubleLine(format("AB (x%d)", turnIns), FormatLargeNumber(turnIns * 7500), 1, 1, 1, 1, 1, 1)
    end
    if avMarkCount >= 3 then
        turnIns = floor(avMarkCount / 3)
        DT.tooltip:AddDoubleLine(format("AV (x%d)", turnIns), FormatLargeNumber(turnIns * 7500), 1, 1, 1, 1, 1, 1)
    end
    if wgMarkCount >= 3 then
        turnIns = floor(wgMarkCount / 3)
        DT.tooltip:AddDoubleLine(format("WSG (x%d)", turnIns), FormatLargeNumber(turnIns * 7500), 1, 1, 1, 1, 1, 1)
    end



	DT.tooltip:Show()
end

local ValueColorUpdate = function(hex)
	String = strjoin("", "%s: ", hex, " %s|r")

	if Panel then
		OnEvent(Panel)
	end
end

E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Ranker", nil, {"PLAYER_PVP_KILLS_CHANGED", "PLAYER_ENTERING_WORLD", "HONOR_LEVEL_UPDATE", "PLAYER_PVP_RANK_CHANGED"}, OnEvent, nil --[[ OnUpdate ]], OnClick, OnEnter, nil --[[ OnLeave ]])