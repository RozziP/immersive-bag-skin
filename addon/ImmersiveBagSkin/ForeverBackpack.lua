local addonName, skin = ...
local aceAddon = LibStub and LibStub("AceAddon-3.0", true)
local betterBags = aceAddon and aceAddon:GetAddon("BetterBags", true)
if not betterBags or not betterBags.isForever then
  return
end

local sonata = betterBags:GetModule("SonataNext", true)
if not sonata or not sonata.RegisterTheme or not sonata:GetTheme("Plain") then
  return
end

local themeName = "ImmersiveBagSkinForeverBackpack"
local sortNormal = "bags-button-autosort-up"
local sortPressed = "bags-button-autosort-down"
local bagSlotRim = "ui-hud-actionbar-iconframe-bags"
local reagentSlotRim = "UI-HUD-ActionBar-IconFrame"
local bagTabSize, bagTabSpacing = 40, 6
local coinLeft = "common-coinbox-left"
local coinCenter = "_common-coinbox-center"
local coinRight = "common-coinbox-right"
local backpackIcon = "Interface/Icons/Inv_misc_bag_08"
local portraitMask = "Interface/CharacterFrame/TempPortraitAlphaMask"
local getAtlasInfo = C_Texture.GetAtlasInfo
local events = betterBags:GetModule("Events", true)
local context = betterBags:GetModule("Context", true)
local constants = betterBags:GetModule("Constants", true)
local bagSystem = betterBags:GetModule("BagSystem", true)
local categories = betterBags:GetModule("Categories", true)
local groups = betterBags:GetModule("Groups", true)
local locale = betterBags:GetModule("Localization", true)
local itemFrame = betterBags:GetModule("ItemFrame", true)
local sort = betterBags:GetModule("Sort", true)
local tween = betterBags:GetModule("NextTween", true)
local pixel = betterBags:GetModule("NextPixel", true)
local database = betterBags:GetModule("Database", true)
local inventory = betterBags:GetModule("Items", true)
local drag = betterBags:GetModule("NextDrag", true)
local allBagsView = constants and constants.BAG_VIEW and constants.BAG_VIEW.SECTION_ALL_BAGS
local keyring = Enum.BagIndex and Enum.BagIndex.Keyring
local hasSortArt = getAtlasInfo(sortNormal) and getAtlasInfo(sortPressed)
local hasCoinArt = getAtlasInfo(coinLeft) and getAtlasInfo(coinCenter) and getAtlasInfo(coinRight)
local heldBagLayout = NineSliceUtil and NineSliceUtil.GetLayout("HeldBagLayout")

-- Other UI addons can replace GameFontNormal, which Plain copies as-is.
local localizedFonts = {
  koKR = "Fonts/2002.TTF",
  zhCN = "Fonts/ARKai_T.ttf",
  zhTW = "Fonts/blei00d.TTF",
  ruRU = "Fonts/FRIZQT___CYR.TTF",
}
local stockFont = localizedFonts[GetLocale()] or "Fonts/FRIZQT__.TTF"
local function bagFont(size, color)
  return { File = stockFont, Size = size, Color = color, Flags = "", Shadow = true }
end

local defaultLook = sonata:Resolve("Default")
local resetFonts = {
  Title = false,
  Section = false,
  SectionRecent = false,
  SectionFree = false,
  Count = false,
  Tab = false,
  TabSelected = false,
  Footer = false,
  Search = false,
  SearchText = false,
}
local fonts = {
  Title = bagFont(12, "BagGold"),
  Section = bagFont(11, "BagGold"),
  SectionRecent = bagFont(11, "BagText"),
  SectionFree = bagFont(11, "BagMuted"),
  Count = bagFont(10, "BagMuted"),
  Tab = bagFont(11, "BagGold"),
  TabSelected = bagFont(11, "BagText"),
  Footer = bagFont(11, "BagText"),
  BagEmpty = bagFont(11, "BagMuted"),
  Search = bagFont(10, "BagMuted"),
  SearchText = bagFont(11, "BagText"),
}

local function restoreDefaultFonts(spec)
  for key, value in pairs(spec) do
    if type(value) == "table" then
      restoreDefaultFonts(value)
    elseif type(key) == "string" and key:match("Font$") and defaultLook.Fonts[value] then
      resetFonts[value] = false
      fonts[value] = defaultLook.Fonts[value]
    end
  end
end

restoreDefaultFonts(defaultLook.Settings)
restoreDefaultFonts(defaultLook.Controls)

local qualityColors = {}
local qualityColor = ColorManager and ColorManager.GetDefaultColorDataForBagItemQuality
if qualityColor then
  for quality = Enum.ItemQuality.Poor, Enum.ItemQuality.WoWToken do
    local color = qualityColor(quality)
    if color then
      qualityColors[quality] = { color.r, color.g, color.b, 1 }
    end
  end
end

sonata:RegisterTheme({
  Name = themeName,
  DisplayName = "Forever Backpack",
  Description = "The stock WoW Forever backpack frame, portrait, controls, and coin box.",
  Parent = "Plain",

  -- Clear Plain's settings, controls and font roles before applying complete
  -- definitions. Merging alone would leave its textures and Copy fonts behind.
  Panel = { Fill = false },
  Settings = false,
  Controls = false,
  Fonts = resetFonts,
  Palette = defaultLook.Palette,

  Clients = {
    Forever = {
      Palette = {
        BagInterior = { 0.086, 0.067, 0.050, 1 },
        BagGold = { Global = "NORMAL_FONT_COLOR" },
        BagText = { Global = "HIGHLIGHT_FONT_COLOR" },
        BagMuted = { Global = "DISABLED_FONT_COLOR" },
      },
      Panel = {
        Fill = { Color = "BagInterior", Inset = { Left = 2, Right = 2, Top = 20, Bottom = 3 } },
        Frame = {
          Layout = heldBagLayout and "HeldBagLayout" or "ButtonFrameTemplateNoPortrait",
          Bands = false,
        },
        Corners = { BOTTOMINNER = 6, BOTTOMOUTER = 6 },
      },
      Fonts = fonts,
      Settings = defaultLook.Settings,
      Controls = defaultLook.Controls,
    },
  },

  Layout = {
    Icon = 37,
    Gap = 5,
    Pad = 10,
    TitleTop = 6,
    HeaderButton = 28,
    SearchTop = 37,
    SearchHeight = 18,
    ContentTop = 61,
    SectionHeader = 17,
    SectionSpacing = 8,
    Footer = 30,
    FooterMoney = 7,
    FooterText = 8,
  },

  Header = {
    Buttons = {
      Pinned = {
        closeButton = { Point = "TOPOUTER", X = -6, Y = 3 },
      },
      Menu = {
        Point = "TOPINNER",
        X = -4,
        Y = -1,
        Width = 36,
        Height = 36,
        Layers = {
          {
            Texture = backpackIcon,
            Mask = { Texture = portraitMask },
          },
        },
        Panels = heldBagLayout and { Backpack = { Layers = {} } } or nil,
        Highlight = {
          Texture = "Interface/Minimap/UI-Minimap-ZoomButton-Highlight",
          -- Plain's hover uses a sprite sheet. Use the whole circular texture.
          TexCoords = { 0, 1, 0, 1 },
          BlendMode = "ADD",
          Alpha = 0.42,
          Inset = { Left = -1, Right = -1, Top = -1, Bottom = -1 },
        },
      },
    },
  },

  Search = {
    Inset = { Left = 62, Right = hasSortArt and 42 or 10 },
    HelpColor = "BagMuted",
  },
  Footer = { EmptyFont = "BagEmpty" },

  ItemButton = {
    -- The intrinsic ItemButton's 64px normal texture is centered on a 37px
    -- slot. Crop its padding so the same rim scales with Next's icon size.
    Backdrop = {
      Texture = "Interface/Buttons/UI-Quickslot2",
      TexCoords = { 13 / 64, 51 / 64, 12 / 64, 50 / 64 },
    },
    Pushed = { Texture = "Interface/Buttons/UI-Quickslot-Depress" },
    QualityBorder = { Texture = "Interface/Common/WhiteIconFrame" },
    QualityColors = qualityColors,
  },
})

if skin and skin.RegisterProfileImport then
  skin.RegisterProfileImport(betterBags, themeName)
end

if not events or not bagSystem then
  return
end

local function createStoneTexture(owner, body)
  -- Tone down the game texture over an opaque fill. Keep it inside the
  -- frame's lower corners in both the Small and Full Panel layouts.
  local stone = owner:CreateTexture(nil, "BACKGROUND", nil, 1)
  stone:SetPoint("TOPLEFT", body, "TOPLEFT", 3, -20)
  stone:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -3, 7)
  stone:SetTexture("Interface/FrameGeneral/UI-Background-Rock", "REPEAT", "REPEAT")
  stone:SetHorizTile(true)
  stone:SetVertTile(true)
  stone:SetVertexColor(0.50, 0.42, 0.34, 0.24)
  return stone
end

local function createBackpackPortrait(owner, button)
  -- Keep the clickable menu above the NineSlice and the artwork below its rim.
  local icon = owner:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(button)
  icon:SetTexture(backpackIcon)
  local mask = owner:CreateMaskTexture()
  mask:SetTexture(portraitMask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetAllPoints(icon)
  icon:AddMaskTexture(mask)
  return icon
end

local function createCoinBox(money, body)
  local border = CreateFrame("Frame", nil, money)
  border:SetUsingParentLevel(true)
  border:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 8, 8)
  border:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -8, 8)
  border:SetHeight(16)

  local left = border:CreateTexture(nil, "BACKGROUND")
  left:SetAtlas(coinLeft)
  left:SetWidth(8)
  left:SetPoint("TOPLEFT")
  left:SetPoint("BOTTOMLEFT")

  local right = border:CreateTexture(nil, "BACKGROUND")
  right:SetAtlas(coinRight)
  right:SetWidth(8)
  right:SetPoint("TOPRIGHT")
  right:SetPoint("BOTTOMRIGHT")

  local center = border:CreateTexture(nil, "BACKGROUND")
  center:SetAtlas(coinCenter)
  center:SetHorizTile(true)
  center:SetPoint("TOPLEFT", left, "TOPRIGHT")
  center:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
  return border
end

local function createSortButton(backpack, search)
  local button = CreateFrame("Button", nil, search)
  button:SetSize(28, 26)
  button:SetPoint("LEFT", search, "RIGHT", 5, 0)
  button:SetNormalAtlas(sortNormal)
  button:SetPushedAtlas(sortPressed)

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface/Buttons/ButtonHilight-Square")
  highlight:SetBlendMode("ADD")
  highlight:SetSize(24, 23)
  highlight:SetPoint("CENTER")

  button:SetScript("OnClick", function()
    backpack:Sort(context:New(addonName .. "_Sort"))
  end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(backpack:TitleRightClickLabel())
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  return button
end

local skinnedBackpack
local stoneTexture
local portrait
local coinBox
local sortButton
local currencyHint
local portraitMenus = setmetatable({}, { __mode = "k" })
local manualCanvases = setmetatable({}, { __mode = "k" })
local movePanels = setmetatable({}, { __mode = "k" })
local instantOpenClosePanels = setmetatable({}, { __mode = "k" })
local renamedCanvases = setmetatable({}, { __mode = "k" })

local function themeActive()
  return not betterBags.loggingOut
    and bagSystem:ActiveDesign() == "next"
    and sonata:GetCurrentThemeKey() == themeName
end

local function useStockBagTabs(rail)
  if not rail or not rail.paint or not rail.slideTo or not rail.place or not rail.PlaceFoot or not rail.styleTab
    or not pixel or not pixel.Length or not tween or not tween.Stop
    or not getAtlasInfo(bagSlotRim) then return end
  local reagentRim = getAtlasInfo(reagentSlotRim) and reagentSlotRim or bagSlotRim
  local reagentBags = constants and constants.BACKPACK_ONLY_REAGENT_BAGS
  local artByTab = {}
  local paint, slideTo, placeFoot = rail.paint, rail.slideTo, rail.PlaceFoot

  function rail:PlaceFoot()
    if not themeActive() or not (self.tabs[1] and self.tabs[1].bag) then return placeFoot(self) end
    -- Equipped bags are one stack. Include the larger slots in the rail's fitted height.
    local step = pixel:Length(self.frame, bagTabSize) + pixel:Length(self.frame, bagTabSpacing)
    for index, tab in ipairs(self.tabs) do
      tab.y = (index - 1) * step
      self:place(tab)
    end
    self.frame:SetHeight(#self.tabs * step)
  end

  function rail:slideTo(tab, offset)
    if not tab.bag or not themeActive() then return slideTo(self, tab, offset) end
    tween:Stop(tab)
    tab.slide = 0
    self:place(tab)
  end

  function rail:paint(tab)
    local art = artByTab[tab]
    if not tab.bag or not themeActive() then
      if art and art.rim:IsShown() then
        art.icon:Hide()
        art.rim:Hide()
        art.highlight:Hide()
        tab.bg:Show()
        tab.text:Show()
        tab.icon:SetAlpha(1)
        self:styleTab(tab)
      end
      return paint(self, tab)
    end

    local button = tab.button
    if not art then
      local icon = button:CreateTexture(nil, "ARTWORK")
      icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
      icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
      local rim = button:CreateTexture(nil, "OVERLAY")
      rim:SetAllPoints(button)
      local highlight = button:CreateTexture(nil, "HIGHLIGHT")
      highlight:SetAllPoints(button)
      highlight:SetBlendMode("ADD")
      highlight:SetAlpha(0.4)
      art = { icon = icon, rim = rim, highlight = highlight }
      artByTab[tab] = art
    end

    -- Keep BetterBags' existing tab buttons, bag data and drag handlers.
    local atlas = reagentBags and reagentBags[tab.id] and reagentRim or bagSlotRim
    art.icon:SetTexture(tab.icon:GetTexture())
    art.rim:SetAtlas(atlas)
    art.highlight:SetAtlas(atlas)
    art.icon:Show()
    art.rim:Show()
    art.highlight:Show()
    tab.bg:Hide()
    tab.highlight:Hide()
    tab.text:Hide()
    tab.icon:SetAlpha(0)
    tab.width = pixel:Length(button, bagTabSize)
    button:SetSize(tab.width, tab.width)
    self:slideTo(tab, 0)
  end
end

local function useInstantOpenAndClose(backpack)
  local show, hide, canvas = backpack.Show, backpack.Hide, backpack.content
  if instantOpenClosePanels[backpack] or not show or not hide or not backpack.frame
    or not canvas or not canvas.order or not tween or not tween.Stop then return end

  function backpack:Show(...)
    local opening = themeActive() and (not self.frame:IsShown() or self.closing)
    local drew = show(self, ...)
    if opening and self.onShown and not self.closing then
      -- Finish the section fades before the slide calls BetterBags' onShown callbacks.
      for _, section in ipairs(canvas.order) do
        tween:Stop(section, true)
      end
      tween:Stop(self, true)
    end
    return drew
  end
  function backpack:Hide(...)
    local closing = themeActive() and self.frame:IsShown() and not self.closing
    hide(self, ...)
    if closing and self.closing then
      -- Finish BetterBags' close tween so it runs the usual hide callbacks.
      tween:Stop(self, true)
    end
  end

  instantOpenClosePanels[backpack] = true
end

local function hideCombinedKeyring()
  local backpackKind = constants and constants.BAG_KIND.BACKPACK
  local combinedView = constants and constants.BAG_VIEW.SECTION_GRID
  local stack = inventory and inventory.Phase7_ApplyVirtualStacks
  if not keyring or not backpackKind or not combinedView or not stack
    or not database or not database.GetBagView then return end

  local function hideKeyring()
    return themeActive() and database:GetBagView(backpackKind) == combinedView
  end

  local wasHidden
  function inventory:Phase7_ApplyVirtualStacks(kind, itemData)
    if kind == backpackKind then
      wasHidden = hideKeyring()
      if wasHidden then
        -- Leave the physical inventory intact. Exclude keyring slots before BetterBags
        -- picks stack roots so keys in ordinary bags keep their own counts and buttons.
        local combined = {}
        for slotkey, item in pairs(itemData) do
          if item.bagid ~= keyring then combined[slotkey] = item end
        end
        itemData = combined
      end
    end
    return stack(self, kind, itemData)
  end

  events:RegisterMessage("sonata/NextThemeChanged", function(ctx)
    if wasHidden ~= nil and wasHidden ~= hideKeyring() then
      events:SendMessage(ctx, "bags/Rederive", { backpack = true, bank = false, resetLayout = true })
    end
  end)
end

local function sectionKey(canvas, section)
  if allBagsView and canvas.boundView == allBagsView and section.kind == "category" then
    -- BetterBags prefixes physical bag sections with their slot number.
    local number = section.name:match("^#(%d+):")
    if number then return "bag:" .. number end
  end
  return section.kind .. ":" .. section.name
end

local function sectionNames(profile)
  local saved = ImmersiveBagSkinDB
  local profiles = type(saved) == "table" and saved.sectionNames
  local names = type(profiles) == "table" and profiles[profile]
  return type(names) == "table" and names or nil
end

local function saveSectionName(profile, key, name)
  local saved = ImmersiveBagSkinDB
  if type(saved) ~= "table" then saved = {} end
  if type(saved.sectionNames) ~= "table" then saved.sectionNames = {} end
  local names = sectionNames(profile) or {}
  names[key] = name
  saved.sectionNames[profile] = names
  ImmersiveBagSkinDB = saved
end

local renamePopup = addonName .. "_RenameSection"
if StaticPopupDialogs and StaticPopup_Show and StaticPopup_Hide and StaticPopup_OnClick then
  StaticPopupDialogs[renamePopup] = {
    text = "Rename Bag Section\n\nLeave blank to restore the default name.",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 80,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(popup, data)
      local editBox = popup:GetEditBox()
      editBox:SetText(data.name)
      editBox:SetFocus()
      editBox:HighlightText()
    end,
    OnAccept = function(popup, data)
      data.save(popup:GetEditBox():GetText())
    end,
    EditBoxOnEnterPressed = function(editBox)
      StaticPopup_OnClick(editBox:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  }
end

local function useSectionNames(backpack)
  local canvas = backpack.content
  if not canvas or renamedCanvases[canvas] or not backpack.OnHeaderEnter then return end
  renamedCanvases[canvas] = true

  local renameAvailable = canvas.section and canvas.placeTitleRow and backpack.frame and backpack.OnHeaderClick and backpack.Draw
    and database and database.GetCurrentProfileName and context and StaticPopupDialogs and StaticPopupDialogs[renamePopup]
  local function canRename(section)
    return renameAvailable and section.name and section.kind and not GetCursorInfo()
      and not (drag and drag.IsActive and drag:IsActive())
  end

  local function aliasFor(section)
    local names = themeActive() and sectionNames(database:GetCurrentProfileName())
    local alias = names and names[sectionKey(canvas, section)]
    return type(alias) == "string" and alias or nil
  end

  local headerEnter = backpack.OnHeaderEnter
  function backpack:OnHeaderEnter(section)
    if not themeActive() then return headerEnter(self, section) end
    if not canRename(section) then return end
    local name = aliasFor(section) or section.name
    GameTooltip:SetOwner(section.header, self.side == "LEFT" and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
    GameTooltip:SetText((name:gsub("|", "||")), 1, 1, 1, 1, true)
    GameTooltip:AddLine("Shift-right-click to rename this section.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end

  if not renameAvailable then return end
  backpack.frame:HookScript("OnHide", function()
    StaticPopup_Hide(renamePopup)
  end)
  if backpack.OnHeaderDragStart then
    hooksecurefunc(backpack, "OnHeaderDragStart", function(_, section)
      if themeActive() and not canRename(section) and GameTooltip:IsOwned(section.header) then
        GameTooltip:Hide()
      end
    end)
  end

  local function applyTitle(section)
    if not section.name then return end
    local alias = aliasFor(section)
    local text = alias and alias:gsub("|", "||") or section.name
    if section.title:GetText() ~= text or (alias and section.titleCut) then
      section.title:SetWidth(0)
      section.title:SetText(text)
      section.titleCut = nil
    end
  end

  -- Only change the displayed title. BetterBags uses the original section
  -- name for categorizing items, filing drops, reordering, and sorting.
  local bindSection, placeTitleRow = canvas.section, canvas.placeTitleRow
  function canvas:section(...)
    local section = bindSection(self, ...)
    applyTitle(section)
    return section
  end
  function canvas:placeTitleRow(section)
    -- Theme changes and layout can restore the original or reset a clipped title.
    applyTitle(section)
    return placeTitleRow(self, section)
  end

  local headerClick = backpack.OnHeaderClick
  function backpack:OnHeaderClick(ctx, section, button)
    if not themeActive() or button ~= "RightButton" or not IsShiftKeyDown() or not canRename(section) then
      return headerClick(self, ctx, section, button)
    end
    local profile = database:GetCurrentProfileName()
    local key, originalName = sectionKey(canvas, section), section.name
    GameTooltip:Hide()
    StaticPopup_Hide(renamePopup)
    StaticPopup_Show(renamePopup, nil, nil, {
      name = aliasFor(section) or originalName,
      save = function(value)
        if not themeActive() or database:GetCurrentProfileName() ~= profile then return end
        local name = value:match("^%s*(.-)%s*$")
        saveSectionName(profile, key, name ~= "" and name ~= originalName and name or nil)
        if self.lastSlotInfo then self:Draw(context:New(addonName .. "_RenameSection"), self.lastSlotInfo) end
      end,
    })
  end
end

local function disableBackpackFlash()
  local itemProto = itemFrame and itemFrame.itemProto
  if not constants or not itemProto or not itemProto.ClearFlashItem then return end

  -- The active Next renderer plays its new-item glow directly, independently
  -- of the profile's Flash Stacks setting.
  local function suppress(method)
    local original = itemProto[method]
    if not original then return end
    itemProto[method] = function(item, ctx, ...)
      if item.kind == constants.BAG_KIND.BACKPACK and themeActive() then
        return item:ClearFlashItem(ctx)
      end
      return original(item, ctx, ...)
    end
  end
  suppress("UpdateNewItem")
  suppress("FlashItem")
end

local function itemSlotState(item)
  local info = item and not item.isItemEmpty and item.itemInfo
  if info then
    return info.itemGUID and info.itemGUID ~= "" and info.itemGUID or info.itemID, info.currentItemCount
  end
end

local function trackSlotMove(bagID, slotID)
  local backpack = skinnedBackpack
  local moves = backpack and movePanels[backpack]
  if not moves or not themeActive() or not backpack.frame:IsShown() or not constants.BACKPACK_BAGS[bagID] then return end
  local snapshot = backpack.lastSlotInfo and backpack.lastSlotInfo.itemsBySlotKey
  if not snapshot then return end

  -- The client can report the old slot immediately after pickup or drop.
  -- Compare the displayed slot with BetterBags' next committed read instead.
  local key = bagID .. "_" .. slotID
  local id, count = itemSlotState(snapshot[key])
  moves[key] = { id = id, count = count, expires = GetTime() + 4 }
end

local function useInstantSlotMoves(backpack)
  local canvas, draw = backpack.content, backpack.Draw
  if movePanels[backpack] or not draw or not canvas or not canvas.SetInstant then return end
  local moves = {}
  movePanels[backpack] = moves

  function backpack:Draw(ctx, slotInfo, callback)
    local snap = false
    if not themeActive() or not self.frame:IsShown() or ctx:Get("resetLayout") then
      wipe(moves)
    elseif slotInfo.itemsBySlotKey then
      local now = GetTime()
      for key, move in pairs(moves) do
        if now > move.expires then
          moves[key] = nil
        else
          local id, count = itemSlotState(slotInfo.itemsBySlotKey[key])
          if id ~= move.id or count ~= move.count then
            snap = true
            moves[key] = nil
          end
        end
      end
    end

    if not snap or canvas.instant then return draw(self, ctx, slotInfo, callback) end
    local wasInstant = canvas.instant
    canvas:SetInstant(true)
    local ok, err = pcall(draw, self, ctx, slotInfo, callback)
    canvas:SetInstant(wasInstant)
    if not ok then error(err, 0) end
  end
end

local function useEverythingSlots(backpack)
  local canvas = backpack.content
  if not canvas or manualCanvases[canvas] or not canvas.Bind
    or not backpack.ShowsBlizzardBags or not backpack.ListsGroups
    or not categories or not locale or not sort or not sort.SortItemDataBySlot then
    return
  end

  local everything, recent = locale:G("Everything"), locale:G("Recent Items")
  local bind = canvas.Bind
  function canvas:Bind(ctx, slotInfo, tabID, claims)
    local tab = slotInfo.tabs and slotInfo.tabs[tabID]
    if not themeActive() or not tab or not tab.emptySlotsSorted or not slotInfo.itemsBySlotKey
      or not slotInfo.visibleItemsBySlotKey or backpack:ShowsBlizzardBags()
      or categories:HiddenIn(everything, backpack.kind)
      or (groups and backpack:ListsGroups() and not groups:CategoryBelongsToGroup(backpack.kind, everything, tabID)) then
      return bind(self, ctx, slotInfo, tabID, claims)
    end

    local slots, manualKeys = {}, {}
    local visible, stacks = slotInfo.visibleItemsBySlotKey, slotInfo.stacks
    for key, item in pairs(slotInfo.itemsBySlotKey) do
      if not item.isItemEmpty and (not keyring or item.bagid ~= keyring) then
        -- BetterBags may put several slots behind one visible stack. Use
        -- its category, then draw each of its actual slots and counts.
        local display = visible[key]
        if not display and stacks and item.itemHash then
          local stack = stacks:GetStackInfo(item.itemHash)
          display = stack and visible[stack.rootItem]
        end
        local category = display and (display.itemInfo and display.itemInfo.category or everything)
        if category == everything or (category == recent and display.derived and display.derived.base == everything) then
          local slot = {}
          for field, value in pairs(item) do slot[field] = value end
          local info = {}
          for field, value in pairs(item.itemInfo or {}) do info[field] = value end
          info.category = everything
          slot.stackedCount = nil
          slot.itemInfo = info
          slots[#slots + 1] = slot
          manualKeys[key] = true
        end
      end
    end
    local occupied = #slots
    local holdingLastItem = occupied == 0 and #tab.emptySlotsSorted > 0
      and self.byName[everything] and CursorHasItem()
    if occupied == 0 and not holdingLastItem then
      return bind(self, ctx, slotInfo, tabID, claims)
    end

    for _, empty in ipairs(tab.emptySlotsSorted) do
      local info = empty.itemInfo or {}
      slots[#slots + 1] = {
        isFreeSlot = true,
        bagid = empty.bagid,
        slotid = empty.slotid,
        slotkey = empty.slotkey,
        itemInfo = {
          category = everything,
          emptySlotName = info.emptySlotName,
          emptySlotFamilyIcon = info.emptySlotFamilyIcon,
        },
      }
    end
    table.sort(slots, sort.SortItemDataBySlot)

    local items = {}
    for _, item in ipairs(tab.items or {}) do
      local category = item.itemInfo and item.itemInfo.category or everything
      if category ~= everything and not manualKeys[item.slotkey] then
        items[#items + 1] = item
      end
    end
    for _, slot in ipairs(slots) do items[#items + 1] = slot end

    local sorted = {}
    for _, item in ipairs(slotInfo.sortedItems or {}) do
      if not manualKeys[item.slotkey] then sorted[#sorted + 1] = item end
    end
    -- Pass a view of the committed inventory to this canvas only. Each
    -- slot is claimed once, and other panels keep the original data.
    local layout = setmetatable({
      sortedItems = sorted,
      tabs = { [tabID] = { items = items, categories = tab.categories } },
    }, { __index = slotInfo })
    bind(self, ctx, layout, tabID, claims)
    self.byName[everything].count:SetText(tostring(occupied))
  end
  manualCanvases[canvas] = true
  return true
end

local function groupsInPortrait(backpack)
  return themeActive() and backpack:ListsGroups()
end

local function configurePortraitMenu(backpack)
  if portraitMenus[backpack] then return end
  local menu = backpack.menuButton
  if menu and menu.Entries and locale and context then
    local originalEntries = menu.Entries
    local label = locale:G("Open Options Screen")
    local canToggleBags = backpack.ShowsBlizzardBags and backpack.ToggleBlizzardBags
    function menu:Entries()
      if not themeActive() then return originalEntries(self) end
      local entries = { {
        text = label,
        notCheckable = true,
        func = function() events:SendMessage(context:New(addonName .. "_Options"), "config/Open") end,
      } }
      if canToggleBags then
        entries[#entries + 1] = {
          text = locale:G(backpack:ShowsBlizzardBags() and "Show Categories" or "Show Blizzard Bags"),
          notCheckable = true,
          func = function() backpack:ToggleBlizzardBags(context:New(addonName .. "_BagView")) end,
        }
      end
      return entries
    end
  end

  useStockBagTabs(backpack.tabs)
  local hasGroups = backpack.ListsGroups and backpack.RefreshTabs and backpack.tabs
  if hasGroups then
    hooksecurefunc(backpack, "RefreshTabs", function(panel)
      if groupsInPortrait(panel) then
        panel.tabs.frame:Hide()
      end
    end)
  end
  portraitMenus[backpack] = true
end

local function showCurrencyHint(hint, show)
  -- BetterBags controls visibility on each layout, so suppress only the hint's
  -- alpha and input. The tracked entries and drag-and-drop strip keep working.
  if hint then
    hint:SetAlpha(show and 1 or 0)
    hint:EnableMouse(show)
  end
end

local function syncBackpack(ctx)
  local backpack = themeActive() and betterBags.Bags and betterBags.Bags.Backpack
  if backpack and backpack ~= skinnedBackpack then
    if stoneTexture then stoneTexture:Hide() end
    if portrait then portrait:Hide() end
    if coinBox then coinBox:Hide() end
    if sortButton then sortButton:Hide() end
    showCurrencyHint(currencyHint, true)
    local money = backpack.moneyFrame and backpack.moneyFrame.frame
    local search = backpack.searchBox and backpack.searchBox.frame
    local menuButton = backpack.menuButton and backpack.menuButton.frame
    local strip = backpack.currencyStrip
    stoneTexture = backpack.frame and backpack.body and createStoneTexture(backpack.frame, backpack.body)
    portrait = heldBagLayout and backpack.frame and menuButton and createBackpackPortrait(backpack.frame, menuButton)
    coinBox = hasCoinArt and money and backpack.body and createCoinBox(money, backpack.body)
    sortButton = hasSortArt and context and search and backpack.Sort and backpack.TitleRightClickLabel
      and createSortButton(backpack, search) or nil
    currencyHint = strip and strip.hint
    configurePortraitMenu(backpack)
    skinnedBackpack = backpack
    useInstantOpenAndClose(backpack)
    useInstantSlotMoves(backpack)
    useSectionNames(backpack)
    if useEverythingSlots(backpack) and backpack.lastSlotInfo and (ctx or context) then
      backpack:Draw(ctx or context:New(addonName .. "_EverythingSlots"), backpack.lastSlotInfo)
    end
  end

  local show = backpack ~= nil and backpack == skinnedBackpack
  if not show and StaticPopupDialogs and StaticPopupDialogs[renamePopup] then
    StaticPopup_Hide(renamePopup)
  end
  if not show and skinnedBackpack and movePanels[skinnedBackpack] then
    wipe(movePanels[skinnedBackpack])
  end
  if stoneTexture then stoneTexture:SetShown(show) end
  if portrait then portrait:SetShown(show) end
  if coinBox then coinBox:SetShown(show) end
  if sortButton then sortButton:SetShown(show) end
  showCurrencyHint(currencyHint, not show)
  if skinnedBackpack and skinnedBackpack.RefreshTabs and not betterBags.loggingOut and bagSystem:ActiveDesign() == "next" then
    skinnedBackpack:RefreshTabs()
  end
end

events:RegisterMessage("sonata/NextThemeChanged", syncBackpack)
events:RegisterMessage("bags/DesignChanged", syncBackpack)
hideCombinedKeyring()
disableBackpackFlash()
if constants and constants.BACKPACK_BAGS and C_Container and C_Container.PickupContainerItem then
  hooksecurefunc(C_Container, "PickupContainerItem", trackSlotMove)
end
syncBackpack()
