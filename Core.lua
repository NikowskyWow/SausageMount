-- =========================================================================
-- SAUSAGE MOUNT
-- =========================================================================

-- KONFIGURÁCIA
local SAUSAGE_VERSION = "1.0.8"
local GITHUB_URL = "github.com/NikowskyWow/SausageMount/releases"

-- 1. DEFINÍCIA NÁZVOV PRE MENU
_G["BINDING_HEADER_SAUSAGE_HEADER"] = "|cffeda55fSausage Mount|r"
_G["BINDING_NAME_SAUSAGE_CAST_RANDOM"] = "Cast Random Mount"

local addonName, addonTable = ...
local SM = CreateFrame("Frame")
local db

-- === THE ULTIMATE FLYING LIST (WARMANE EDITION) ===
local FLY_KEYWORDS = {
    -- Generic types
    "Drake", "Gryphon", "Wyvern", "Hippogryph", "Ray", "Nether", 
    "Phoenix", "Helicopter", "Carpet", "Proto", "Bat", "Dragon",
    
    -- Specific & Unique
    "Invincible", "Mimiron", "Headless", "Rocket", "Machine", "Broom",
    "Celestial", "Guardian", "Aspect", "Fey", "Reaver", "Nightmare",
    "Windsteed", "Seeker", "Crow", "Wind Rider",
    
    -- NOVÉ PRIDANÉ (Podľa tvojho zoznamu)
    "Al'ar",        -- Ashes of Al'ar
    "Wyrm",         -- Frost Wyrms
    "Vanquisher",   -- ICC Meta mounts
    "Winged",       -- Winged Steed of the Ebon Blade
    "Horseman"      -- The Horseman's Reins (poistka)
}

-- Default nastavenia
local defaults = {
    minimapPos = 45,
    mounts = {}
}

-- =========================================================================
-- 🧠 LOGIKA (Backend)
-- =========================================================================

local function IsLikelyFlyer(name)
    for _, word in ipairs(FLY_KEYWORDS) do
        if string.find(name, word) then return true end
    end
    return false
end

local function RefreshMountDB()
    local numMounts = GetNumCompanions("MOUNT")
    for i = 1, numMounts do
        local creatureID, creatureName, spellID, icon, active = GetCompanionInfo("MOUNT", i)
        
        if not db.mounts[spellID] then
            local isFlyer = IsLikelyFlyer(creatureName)
            db.mounts[spellID] = {
                enabled = true,
                isAir = isFlyer,
                name = creatureName,
                icon = icon
            }
        else
            db.mounts[spellID].name = creatureName
            db.mounts[spellID].icon = icon
            db.mounts[spellID].isAir = IsLikelyFlyer(creatureName)
        end
    end
end

function Sausage_CastRandomMount()
    if IsMounted() then
        Dismount()
        return
    end

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("|cffeda55f[Sausage]|r Cannot mount in combat!", 1.0, 0.0, 0.0)
        return
    end

    RefreshMountDB()

    local zone = GetRealZoneText()
    local subZone = GetSubZoneText()
    local canFly = IsFlyableArea()
    
    if zone == "Dalaran" then
        if subZone == "Krasus' Landing" then canFly = true else canFly = false end
    elseif zone == "Wintergrasp" then
        if not canFly then canFly = false end
    end

    local candidates = {}
    local numMounts = GetNumCompanions("MOUNT")

    for i = 1, numMounts do
        local _, _, spellID = GetCompanionInfo("MOUNT", i)
        local data = db.mounts[spellID]

        if data and data.enabled then
            if canFly then
                if data.isAir then table.insert(candidates, i) end
            else
                if not data.isAir then table.insert(candidates, i) end
            end
        end
    end

    if #candidates == 0 then
        if canFly then
            UIErrorsFrame:AddMessage("|cffeda55f[Sausage]|r No FLYING mounts found!", 1.0, 0.0, 0.0)
        else
            UIErrorsFrame:AddMessage("|cffeda55f[Sausage]|r No GROUND mounts found!", 1.0, 0.0, 0.0)
        end
        return
    end

    local index = candidates[math.random(1, #candidates)]
    CallCompanion("MOUNT", index)
end

-- =========================================================================
-- 🎨 SAUSAGE UI - MAIN FRAME
-- =========================================================================

local MainFrame = CreateFrame("Frame", "SausageMountMainFrame", UIParent)
MainFrame:SetSize(400, 500)
MainFrame:SetPoint("CENTER")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()

MainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local CloseBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", -5, -5)

-- HEADER (ZMENŠENÝ)
local HeaderTexture = MainFrame:CreateTexture(nil, "ARTWORK")
HeaderTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
HeaderTexture:SetWidth(250)
HeaderTexture:SetHeight(64)
HeaderTexture:SetPoint("TOP", 0, 12)

local HeaderText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeaderText:SetPoint("TOP", HeaderTexture, "TOP", 0, -14)
HeaderText:SetText("Sausage Mount")

local Footer = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
Footer:SetPoint("BOTTOM", 0, 15)
Footer:SetText("by Sausage Party")

-- Version Text (Vľavo dole)
local VersionText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
VersionText:SetPoint("BOTTOMLEFT", 20, 15)
VersionText:SetText("v" .. SAUSAGE_VERSION)

-- Help Text pre Keybind
local HelpText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
HelpText:SetPoint("BOTTOM", 0, 45)
HelpText:SetWidth(350)
HelpText:SetJustifyH("CENTER")
HelpText:SetText("|cffFFD100Keybind:|r Press |cffFFFFFFESC -> Key Bindings -> Sausage Mount|r")


-- =========================================================================
-- 🆕 GITHUB POPUP FRAME
-- =========================================================================

local GitFrame = CreateFrame("Frame", "SausageGitFrame", UIParent)
GitFrame:SetSize(350, 120)
GitFrame:SetPoint("CENTER")
GitFrame:SetFrameStrata("DIALOG")
GitFrame:Hide()

GitFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local GitClose = CreateFrame("Button", nil, GitFrame, "UIPanelCloseButton")
GitClose:SetPoint("TOPRIGHT", -5, -5)

local GitHeader = GitFrame:CreateTexture(nil, "ARTWORK")
GitHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
GitHeader:SetWidth(200)
GitHeader:SetHeight(64)
GitHeader:SetPoint("TOP", 0, 12)

local GitTitle = GitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
GitTitle:SetPoint("TOP", GitHeader, "TOP", 0, -14)
GitTitle:SetText("Update Link")

local GitBox = CreateFrame("EditBox", nil, GitFrame, "InputBoxTemplate")
GitBox:SetSize(280, 20)
GitBox:SetPoint("CENTER", 0, -10)
GitBox:SetAutoFocus(false)
GitBox:SetText(GITHUB_URL)
GitBox:SetCursorPosition(0)
GitBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
GitBox:SetScript("OnEscapePressed", function(self) GitFrame:Hide() end)
GitBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)

local GitInst = GitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
GitInst:SetPoint("BOTTOM", GitBox, "TOP", 0, 5)
GitInst:SetText("Press CTRL+C to copy:")

-- BUTTON "CHECK UPDATES" (Vpravo dole na hlavnom okne)
local UpdateBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
UpdateBtn:SetSize(110, 25)
UpdateBtn:SetPoint("BOTTOMRIGHT", -15, 12)
UpdateBtn:SetText("Check Updates")
UpdateBtn:SetScript("OnClick", function()
    GitFrame:Show()
    GitBox:SetFocus()
    GitBox:HighlightText()
end)

-- =========================================================================
-- 📜 SCROLL FRAME
-- =========================================================================

local function CreateDarkPanel(parent)
    local box = CreateFrame("Frame", nil, parent)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    box:SetBackdropBorderColor(0, 0.7, 1, 1)
    return box
end

local ListBox = CreateDarkPanel(MainFrame)
ListBox:SetPoint("TOPLEFT", 20, -50)
ListBox:SetPoint("BOTTOMRIGHT", -20, 70) 

local ScrollFrame = CreateFrame("ScrollFrame", "SausageScrollFrame", ListBox, "FauxScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 0, -5)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 5)

local ROW_HEIGHT = 35
local MAX_ROWS = 10
local rows = {}

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, ListBox)
    row:SetSize(330, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 10, -((index - 1) * ROW_HEIGHT) - 12)
    
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("LEFT", 5, 0)
    
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.name:SetWidth(180)
    row.name:SetJustifyH("LEFT")
    
    row.cbEnable = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.cbEnable:SetSize(24, 24)
    row.cbEnable:SetPoint("RIGHT", -20, 0)
    row.cbEnable.text = row.cbEnable:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.cbEnable.text:SetPoint("BOTTOM", row.cbEnable, "TOP", 0, 0)
    row.cbEnable.text:SetText("Enable")
    
    return row
end

for i = 1, MAX_ROWS do rows[i] = CreateRow(i) end

local function UpdateScrollList()
    RefreshMountDB()
    local mountList = {}
    local numMounts = GetNumCompanions("MOUNT")
    for i = 1, numMounts do
        local _, _, spellID = GetCompanionInfo("MOUNT", i)
        table.insert(mountList, { index = i, spellID = spellID })
    end
    
    FauxScrollFrame_Update(ScrollFrame, #mountList, MAX_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(ScrollFrame)
    
    for i = 1, MAX_ROWS do
        local idx = offset + i
        local row = rows[i]
        if idx <= #mountList then
            local mountInfo = mountList[idx]
            local dbData = db.mounts[mountInfo.spellID]
            
            row:Show()
            row.icon:SetTexture(dbData.icon)
            
            local typeTag = " (Ground)"
            if dbData.isAir then typeTag = " |cff00FF00(Fly)|r" end
            row.name:SetText(dbData.name .. typeTag)
            
            row.cbEnable:SetChecked(dbData.enabled)
            row.cbEnable:SetScript("OnClick", function(self) db.mounts[mountInfo.spellID].enabled = self:GetChecked() end)
        else
            row:Hide()
        end
    end
end

ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, UpdateScrollList) 
end)

MainFrame:SetScript("OnShow", UpdateScrollList)

-- =========================================================================
-- 🌭 MINIMAP BUTTON
-- =========================================================================

local MinimapBtn = CreateFrame("Button", "SausageMinimapButton", Minimap)
MinimapBtn:SetSize(32, 32)
MinimapBtn:SetFrameLevel(8)
MinimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local icon = MinimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Inv_Misc_Food_54")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")

local border = MinimapBtn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(52, 52)
border:SetPoint("TOPLEFT")

local function UpdateMinimapButton()
    local angle = math.rad(db.minimapPos or 45)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    MinimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

MinimapBtn:RegisterForDrag("RightButton")
MinimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
        xpos = xpos / Minimap:GetEffectiveScale() - xmin - 70
        ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70
        local angle = math.deg(math.atan2(ypos, xpos))
        db.minimapPos = angle
        UpdateMinimapButton()
    end)
end)

MinimapBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

MinimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() end
    end
end)

MinimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Sausage Mount Manager")
    GameTooltip:AddLine("Left-Click: Configure Mounts", 1, 1, 1)
    GameTooltip:AddLine("Right-Click: Move Icon", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
MinimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- =========================================================================
-- INITIALIZATION
-- =========================================================================

SM:RegisterEvent("ADDON_LOADED")
SM:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "SausageMount" then
        if not SausageMountDB then SausageMountDB = defaults end
        db = SausageMountDB
        if not db.mounts then db.mounts = {} end
        RefreshMountDB()
        
        UpdateMinimapButton()
        
        SLASH_SAUSAGE1 = "/sausage"
        SlashCmdList["SAUSAGE"] = function() MainFrame:Show() end
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)