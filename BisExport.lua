-- BisExport.lua
-- Export your equipped gear to BiS planner format

local addonName, addon = ...

BisExport = {}

-- Slot order matching the website format
local SLOT_ORDER = {
    { name = "Head",      slotId = 1  },
    { name = "Neck",      slotId = 2  },
    { name = "Shoulders", slotId = 3  },
    { name = "Back",      slotId = 15 },
    { name = "Chest",     slotId = 5  },
    { name = "Wrists",    slotId = 9  },
    { name = "Hands",     slotId = 10 },
    { name = "Waist",     slotId = 6  },
    { name = "Legs",      slotId = 7  },
    { name = "Feet",      slotId = 8  },
    { name = "Finger 1",  slotId = 11 },
    { name = "Finger 2",  slotId = 12 },
    { name = "Trinket 1", slotId = 13 },
    { name = "Trinket 2", slotId = 14 },
    { name = "Main Hand", slotId = 16 },
    { name = "Off Hand",  slotId = 17 },
    { name = "Ranged",    slotId = 18 },
}

-- Mapping Enchantment Item ID to Profession Spell ID (wip, will add more later but the DB is screwed up at the moment. Crowdsourcing it..)
local ENCHANT_SPELL_MAP = {
    -- Weapon Enchantments
    [1900] = 20034, -- Crusader
}

-- Slot Suffix Mapping
local SLOT_SUFFIXES = {
    ["Head"]      = "01", ["Shoulders"] = "02", ["Back"]      = "03",
    ["Chest"]     = "04", ["Wrists"]    = "05", ["Hands"]     = "06",
    ["Waist"]     = "07", ["Legs"]      = "08", ["Feet"]      = "09",
    ["Main Hand"] = "12", ["Off Hand"]  = "12", ["Ranged"]    = "14",
}

-- Class/Spec to code mapping
local SPEC_CODES = {
    ["WARRIOR"] = { {name="Arms", code="WA"}, {name="Fury", code="WF"}, {name="Prot", code="WP"} },
    ["PALADIN"] = { {name="Holy", code="PH"}, {name="Prot", code="PP"}, {name="Ret", code="PR"} },
    ["HUNTER"]  = { {name="BM",   code="HB"}, {name="Marks", code="HM"}, {name="Surv", code="HS"} },
    ["ROGUE"]   = { {name="Assa", code="RA"}, {name="Combat",code="RC"}, {name="Sub",  code="RS"} },
    ["PRIEST"]  = { {name="Disc", code="PD"}, {name="Holy",  code="PO"}, {name="Shadow",code="PS"} },
    ["SHAMAN"]  = { {name="Ele",  code="SE"}, {name="Enh",   code="SN"}, {name="Resto", code="SR"} },
    ["MAGE"]    = { {name="Arc",  code="MA"}, {name="Fire",  code="MF"}, {name="Frost", code="MO"} },
    ["WARLOCK"] = { {name="Affli",code="LA"}, {name="Demo",  code="LD"}, {name="Destro",code="LT"} },
    ["DRUID"]   = { {name="Bal",  code="DB"}, {name="Feral", code="DF"}, {name="Resto", code="DR"} },
}

local function ParseItemLink(link)
    if not link then return nil, nil end
    local itemId, enchantId = link:match("item:(%d+):(%d*)")
    itemId = tonumber(itemId)
    enchantId = tonumber(enchantId)
    if enchantId == 0 then enchantId = nil end
    return itemId, enchantId
end

local function GetEnchantExportValue(enchantId, slotName)
    if not enchantId then return "-" end
    local spellId = ENCHANT_SPELL_MAP[enchantId]
    local suffix = SLOT_SUFFIXES[slotName] or ""
    if spellId then
        return tostring(spellId) .. suffix
    else
        print("|cffff0000[BiS Export] Mapping Missing:|r ID |cffffff00" .. enchantId .. "|r on |cffffff00" .. slotName .. "|r")
        return tostring(enchantId) .. suffix
    end
end

local function GetEquippedGear()
    local itemIds = {}
    local enchantValues = {}
    for i, slotInfo in ipairs(SLOT_ORDER) do
        local link = GetInventoryItemLink("player", slotInfo.slotId)
        local itemId, enchantId = ParseItemLink(link)
        itemIds[i] = itemId or "-"
        enchantValues[i] = GetEnchantExportValue(enchantId, slotInfo.name)
    end
    return itemIds, enchantValues
end

function BisExport:Export(phase, specCode)
    local itemIds, enchantValues = GetEquippedGear()
    local rawString = string.format("%s.%d.%s.%s", specCode, phase, table.concat(itemIds, ","), table.concat(enchantValues, ","))
    local compressed = LZString.compressToEncodedURIComponent(rawString)
    return "https://bisbeard.com/?build=" .. compressed
end

local exportFrame = nil

local function CreateExportFrame()
    if exportFrame then return exportFrame end
    
    local _, playerClass = UnitClass("player")
    local specs = SPEC_CODES[playerClass] or {}
    local currentSpec = specs[1] or {name="Unknown", code="XX"}
    local selectedPhase = 5

    local frame = CreateFrame("Frame", "BisExportFrame", UIParent)
    frame:SetSize(500, 280)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("BiS Export")
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Spec Dropdown
    local specLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specLabel:SetPoint("TOPLEFT", 20, -50)
    specLabel:SetText("Spec:")

    local specDropdown = CreateFrame("Frame", "BisExportSpecDropdown", frame, "UIDropDownMenuTemplate")
    specDropdown:SetPoint("LEFT", specLabel, "RIGHT", -10, -2)
    UIDropDownMenu_SetWidth(specDropdown, 100)
    UIDropDownMenu_SetText(specDropdown, currentSpec.name)

    UIDropDownMenu_Initialize(specDropdown, function(self, level)
        for _, s in ipairs(specs) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = s.name
            info.value = s.code
            info.func = function(self)
                currentSpec = s
                UIDropDownMenu_SetText(specDropdown, s.name)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Phase Dropdown
    local phaseLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phaseLabel:SetPoint("TOPLEFT", 230, -50)
    phaseLabel:SetText("Phase:")

    local phaseDropdown = CreateFrame("Frame", "BisExportPhaseDropdown", frame, "UIDropDownMenuTemplate")
    phaseDropdown:SetPoint("LEFT", phaseLabel, "RIGHT", -10, -2)
    UIDropDownMenu_SetWidth(phaseDropdown, 80)
    UIDropDownMenu_SetText(phaseDropdown, "Phase " .. selectedPhase)
    UIDropDownMenu_Initialize(phaseDropdown, function(self, level)
        for i = 1, 5 do
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Phase " .. i
            info.value = i
            info.func = function(self)
                selectedPhase = self.value
                UIDropDownMenu_SetText(phaseDropdown, "Phase " .. self.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetSize(140, 25)
    exportBtn:SetPoint("TOP", 0, -85)
    exportBtn:SetText("Generate URL")
    
    local urlLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    urlLabel:SetPoint("TOPLEFT", 20, -115)
    urlLabel:SetText("Bisbeard url:")
    
    local urlScroll = CreateFrame("ScrollFrame", "BisExportUrlScroll", frame, "UIPanelScrollFrameTemplate")
    urlScroll:SetPoint("TOPLEFT", 20, -135)
    urlScroll:SetSize(440, 80)
    
    local urlEdit = CreateFrame("EditBox", "BisExportUrlEdit", urlScroll)
    urlEdit:SetMultiLine(true)
    urlEdit:SetFontObject(GameFontHighlightSmall)
    urlEdit:SetWidth(420)
    urlEdit:SetAutoFocus(false)
    urlEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    urlScroll:SetScrollChild(urlEdit)
    
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("BOTTOMLEFT", 20, 15)
    instructions:SetWidth(460)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("1. Select Spec & Phase.  2. Click Generate URL.  3. Ctrl+A then Ctrl+C to copy.")
    
    exportBtn:SetScript("OnClick", function()
        urlEdit:SetText(BisExport:Export(selectedPhase, currentSpec.code))
        urlEdit:HighlightText()
        urlEdit:SetFocus()
    end)
    
    exportFrame = frame
    return frame
end

SLASH_BISEXPORT1, SLASH_BISEXPORT2 = "/bisexport", "/bis"
SlashCmdList["BISEXPORT"] = function()
    local f = CreateExportFrame()
    if f:IsShown() then f:Hide() else f:Show() end
end

print("|cff00ff00BiS Export|r loaded. Type |cffff9900/bis|r to open.")