local addonName, skin = ...
local profileName = "Forever Backpack"

function skin.RegisterProfileImport(betterBags, themeName)
  local database = betterBags:GetModule("Database", true)
  local constants = betterBags:GetModule("Constants", true)
  local bagSystem = betterBags:GetModule("BagSystem", true)
  local context = betterBags:GetModule("Context", true)
  if not database or not database.GetData or not database.GetCurrentProfileName
    or not database.SwitchToProfile or not constants then return end

  local function migrateMerchantSetting(saved, profiles)
    if saved.stockMerchantMigrated or not bagSystem or not bagSystem.SetVendorEnabled
      or not database.GetNextVendorEnabled or not context then return true end

    local current = database:GetCurrentProfileName()
    local active = profiles[current]
    if active and active.nextTheme == themeName and database:GetNextVendorEnabled() then
      -- BetterBags can give the stock frame back between merchant visits.
      if (MerchantFrame and MerchantFrame:IsShown())
        or (betterBags.Vendor and betterBags.Vendor.atMerchant) then return false end
      if not bagSystem:SetVendorEnabled(context:New(addonName .. "_StockMerchant"), false) then
        return false
      end
    end

    for name, profile in pairs(profiles) do
      if name ~= current and profile.nextTheme == themeName then
        profile.nextVendorEnabled = false
      end
    end
    saved.stockMerchantMigrated = true
    ImmersiveBagSkinDB = saved
    return true
  end

  local backpack = constants.BAG_KIND.BACKPACK
  local function selectProfile(saved, profiles)
    if saved.betterBagsProfileSetupComplete then return true end

    -- Earlier versions imported the preset without selecting it. Honor a
    -- deliberate deletion or rename after that import.
    if saved.betterBagsProfileImported and profiles[profileName] == nil then
      saved.betterBagsProfileSetupComplete = true
      return true
    end

    local name, suffix = profileName, 2
    while profiles[name] and profiles[name].nextTheme ~= themeName do
      name = format("%s (%d)", profileName, suffix)
      suffix = suffix + 1
    end
    if profiles[name] == nil then
      profiles[name] = {
        nextEnabled = true,
        nextTheme = themeName,
        nextVendorEnabled = false,
        nextSize = "small",
        nextSectionSortSplit = true,
        views = { [backpack] = constants.BAG_VIEW.SECTION_GRID },
        categoryFilters = {
          [backpack] = {
            Type = false,
            Subtype = false,
            Expansion = false,
            TradeSkill = false,
            RecentItems = false,
            GearSet = false,
            EquipmentLocation = false,
          },
        },
        showAllFreeSpace = { [backpack] = true },
        newItems = { [backpack] = { showNewItemFlash = false } },
      }
    end

    local switched = database:GetCurrentProfileName() ~= name
    if switched and not database:SwitchToProfile(name) then return false end
    ImmersiveBagSkinDB = saved
    saved.betterBagsProfileImported = true
    saved.betterBagsProfileSetupComplete = true
    return true, switched
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  local scheduled
  frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" then
      if loadedAddon ~= addonName then return end
      self:UnregisterEvent(event)
      if not IsLoggedIn() then return end
    end
    if scheduled then return end
    scheduled = true
    C_Timer.After(0, function()
      scheduled = false
      if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
      end
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
      local saved = ImmersiveBagSkinDB
      if type(saved) ~= "table" then saved = {} end
      local aceDB = database:GetData()
      local profiles = aceDB and aceDB.profiles
      if type(profiles) ~= "table" then return end
      if not migrateMerchantSetting(saved, profiles) then
        self:RegisterEvent("MERCHANT_CLOSED")
        return
      end
      self:UnregisterEvent("MERCHANT_CLOSED")
      local complete, switched = selectProfile(saved, profiles)
      if complete then self:UnregisterAllEvents() end
      -- Some BetterBags modules read their profile in OnInitialize. Follow
      -- its profile picker's reload so those modules see the new settings.
      if switched then ReloadUI() end
    end)
  end)
end
