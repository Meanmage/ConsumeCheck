-- ConsumeCheck: World of Warcraft Vanilla 1.12.1 Addon
-- Requires SuperWoW for extended functionality
-- Author: ConsumeCheck
-- Version: 1.0

-- Check if SuperWoW is available
local superwow = SUPERWOW_VERSION
if not superwow then
    DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[ConsumeCheck]|r SuperWoW is required for this addon to function properly.")
    return
end

-- Local references for better performance
local UnitExists = UnitExists
local UnitBuff = UnitBuff
local UnitName = UnitName
local UnitClass = UnitClass
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local GetRealZoneText = GetRealZoneText
local GetNumRaidMembers = GetNumRaidMembers
local date = date
local ExportFile = ExportFile
local SpellInfo = SpellInfo
local string_gsub = string.gsub
local table_insert = table.insert
local table_concat = table.concat
local table_getn = table.getn
local pcall = pcall
local type = type
local tostring = tostring

-- Addon constants
local MAX_BUFFS = 32

-- Buff blacklist - buffs to exclude from reports but still count in total (case-insensitive)
local BuffBlacklist = {
    ["amplify magic"] = true,
    ["ancestral fortitude"] = true,
    ["arcane brilliance"] = true,
    ["arcane intellect"] = true,
    ["argent dawn commission"] = true,
    ["aspect of the cheetah"] = true,
    ["aspect of the hawk"] = true,
    ["aspect of the monkey"] = true,
    ["battle shout"] = true,
    ["blessing of kings"] = true,
    ["blessing of light"] = true,
    ["blessing of might"] = true,
    ["blessing of salvation"] = true,
    ["blessing of wisdom"] = true,
    ["blood frenzy"] = true,
    ["blood pact"] = true,
    ["bloodrage"] = true,
    ["cat form"] = true,
    ["champion's grace"] = true,
    ["clearcasting"] = true,
    ["concentration aura"] = true,
    ["dampen magic"] = true,
    ["daybreak"] = true,
    ["demon armor"] = true,
    ["devotion aura"] = true,
    ["diamond flask"] = true,
    ["dire bear form"] = true,
    ["electrified"] = true,
    ["elemental devastation"] = true,
    ["emerald blessing"] = true,
    ["enlighten"] = true,
    ["enlightened"] = true,
    ["enrage"] = true,
    ["fire resistance aura"] = true,
    ["fire shield"] = true,
    ["fire ward"] = true,
    ["flametongue totem passive"] = true,
    ["flip out"] = true,
    ["flurry"] = true,
    ["frenzied regeneration"] = true,
    ["frost armor"] = true,
    ["frost ward"] = true,
    ["gift of the wild"] = true,
    ["grace of air"] = true,
    ["greater blessing of kings"] = true,
    ["greater blessing of light"] = true,
    ["greater blessing of might"] = true,
    ["greater blessing of salvation"] = true,
    ["greater blessing of wisdom"] = true,
    ["healing way"] = true,
    ["holy champion"] = true,
    ["holy judgement"] = true,
    ["holy strength"] = true,
    ["ice barrier"] = true,
    ["inner fire"] = true,
    ["inspiration"] = true,
    ["leader of the pack"] = true,
    ["lightning shield"] = true,
    ["mage armor"] = true,
    ["mana spring"] = true,
    ["mark of the wild"] = true,
    ["moonkin aura"] = true,
    ["moonkin form"] = true,
    ["power word: fortitude"] = true,
    ["power word: shield"] = true,
    ["prayer of fortitude"] = true,
    ["prayer of shadow protection"] = true,
    ["prayer of spirit"] = true,
    ["redoubt"] = true,
    ["regrowth"] = true,
    ["rejuvenation"] = true,
    ["renew"] = true,
    ["righteous fury"] = true,
    ["sanctity aura"] = true,
    ["seal of command"] = true,
    ["seal of righteousness"] = true,
    ["shadowform"] = true,
    ["soulstone resurrection"] = true,
    ["spellstone"] = true,
    ["spirit bond"] = true,
    ["strength of earth"] = true,
    ["thorns"] = true,
    ["tidal surge"] = true,
    ["travel form"] = true,
    ["tree of life aura"] = true,
    ["tree of life form"] = true,
    ["trueshot aura"] = true,
    ["vengeance"] = true,
    ["water shield"] = true,
    ["windfury totem effect"] = true,
    ["zeal"] = true,
}

-- Helper function to check if a buff should be blacklisted from display
local function IsBuffBlacklisted(buffName)
    if not buffName or buffName == "" then
        return false -- Don't blacklist unknown buffs, let them show
    end

    local lowerName = string.lower(buffName)

    -- Check if buff is in the explicit blacklist
    if BuffBlacklist[lowerName] then
        return true
    end

    -- Check if buff name contains "illusion" (case-insensitive)
    if string.find(lowerName, "illusion") then
        return true
    end

    return false
end

-- Class names for display
local ClassNames = {
    ["WARRIOR"] = "Warrior",
    ["DRUID"] = "Druid",
    ["PALADIN"] = "Paladin",
    ["WARLOCK"] = "Warlock",
    ["MAGE"] = "Mage",
    ["PRIEST"] = "Priest",
    ["ROGUE"] = "Rogue",
    ["HUNTER"] = "Hunter",
    ["SHAMAN"] = "Shaman"
}

-- Main function to scan raid buffs
local function ScanRaidBuffs()
    -- Check if we're in a raid
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[ConsumeCheck]|r You must be in a raid to use this command.")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[ConsumeCheck]|r Scanning raid buffs...")

    local timestamp = date("%Y-%m-%d_%H-%M-%S")
    local zoneName = GetRealZoneText() or "Unknown_Zone"

    -- Clean zone name for filename (remove spaces and special characters)
    zoneName = string_gsub(zoneName, "[^%w_]", "_")

    -- Use table for efficient string building
    local reportLines = {}
    table_insert(reportLines, "=== ConsumeCheck Report ===")
    table_insert(reportLines, "Timestamp: " .. date("%Y-%m-%d %H:%M:%S"))
    table_insert(reportLines, "Zone: " .. (GetRealZoneText() or "Unknown Zone"))
    table_insert(reportLines, "==========================")
    table_insert(reportLines, "")

    -- Count and scan each raid member
    local onlineCount = 0
    local playerData = {}

    -- Scan each raid member
    for i = 1, numRaidMembers do
        local unit = "raid" .. i

        if UnitExists(unit) and UnitIsConnected(unit) then
            onlineCount = onlineCount + 1
            local unitName = UnitName(unit)
            local _, unitClass = UnitClass(unit)
            local maxHealth = UnitHealthMax(unit)
            local className = ClassNames[unitClass] or unitClass or "Unknown"

            -- Collect buff information
            local buffs = {}
            local buffCount = 0
            local displayedBuffs = {}

            -- Scan all possible buff slots (up to 32)
            for buffIndex = 1, MAX_BUFFS do
                local buffTexture, buffApplications, buffType, buffSpellId = UnitBuff(unit, buffIndex)

                if buffTexture then
                    buffCount = buffCount + 1

                    -- Get buff name using SuperWoW's SpellInfo function
                    local buffName = "Unknown Buff"
                    local spellId = nil

                    -- SuperWoW returns spell ID in the buffType parameter (3rd parameter)
                    if buffType and type(buffType) == "number" and buffType > 0 then
                        spellId = buffType
                    end

                    -- Get spell name from ID with error protection
                    if spellId and spellId > 0 and SpellInfo then
                        local success, spellName = pcall(SpellInfo, spellId)
                        if success and spellName and spellName ~= "" then
                            buffName = spellName
                        end
                    end

                    -- Always add to total buffs list
                    table_insert(buffs, buffName)

                    -- Only add to display list if not blacklisted
                    if not IsBuffBlacklisted(buffName) then
                        -- Include spell ID in display for debugging/identification
                        local displayName = buffName
                        if spellId and spellId > 0 then
                            displayName = buffName .. " (ID: " .. tostring(spellId) .. ")"
                        end
                        table_insert(displayedBuffs, displayName)
                    end
                else
                    break -- No more buffs
                end
            end

            -- Store player data
            table_insert(playerData, {
                name = unitName,
                class = className,
                health = maxHealth,
                buffs = buffs,  -- All buffs (for counting)
                displayedBuffs = displayedBuffs,  -- Only non-blacklisted buffs (for display)
                buffCount = buffCount
            })
        end
    end

    -- Add online count to header
    table_insert(reportLines, "Online Players: " .. onlineCount)
    table_insert(reportLines, "")

    -- Add player info to report
    for _, player in ipairs(playerData) do
        table_insert(reportLines, player.name .. " (" .. player.class .. ")")
        table_insert(reportLines, "Max Health: " .. (player.health or "Unknown"))
        table_insert(reportLines, "Buffs: " .. player.buffCount .. "/" .. MAX_BUFFS .. " (showing " .. table_getn(player.displayedBuffs) .. " significant)")

        if table_getn(player.displayedBuffs) > 0 then
            for j, buffName in ipairs(player.displayedBuffs) do
                table_insert(reportLines, "  " .. j .. ". " .. buffName)
            end
        else
            table_insert(reportLines, "  No significant buffs detected")
        end

        table_insert(reportLines, "")
    end

    -- Add report footer and convert to string
    table_insert(reportLines, "=== End of Report ===")
    local reportText = table_concat(reportLines, "\n")

    -- Generate filename
    local filename = "ConsumeCheck_" .. timestamp .. "_" .. zoneName .. ".txt"

    -- Export to file with error handling
    local success, errorMsg = pcall(ExportFile, filename, reportText)
    if success then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[ConsumeCheck]|r Report saved to: " .. filename)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[ConsumeCheck]|r Failed to save report: " .. tostring(errorMsg or "Unknown error"))
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[ConsumeCheck]|r Scan complete!")
end

-- Slash command handler
SLASH_CONSUMECHECK1 = "/cc"
SlashCmdList["CONSUMECHECK"] = function(cmd)
    cmd = string.lower(cmd or "")

    if cmd == "" then
        ScanRaidBuffs()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00[ConsumeCheck]|r Usage: /cc - Scan raid buffs and generate report")
    end
end

-- Addon loaded message
DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[ConsumeCheck]|r v1.0 loaded. SuperWoW v" .. superwow .. " detected.")
DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00[ConsumeCheck]|r Use /cc to scan raid buffs and generate a report.")
