local function SetupMonitors()
  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_AUCTION_HOUSE) then
    CreateFrame("Frame", "JNRMailMonitor", nil, "JournalatorMailMonitorTemplate")
    CreateFrame("Frame", "JNRPostingMonitor", nil, "JournalatorPostingMonitorTemplate")
  else
    Journalator.Debug.Message("AH monitoring disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_VENDORING) then
    CreateFrame("Frame", "JNRVendorMonitor", nil, "JournalatorVendorMonitorTemplate")
  else
    Journalator.Debug.Message("vendor monitoring disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_CRAFTING_ORDERS) then
    if not Auctionator.Constants.IsClassic then
      CreateFrame("Frame", "JNRCraftingOrderPlacingMonitor", nil, "JournalatorCraftingOrderPlacingMonitorTemplate")
      CreateFrame("Frame", "JNRCraftingOrderFulfillingMonitor", nil, "JournalatorCraftingOrderFulfillingMonitorTemplate")
    end
  else
    Journalator.Debug.Message("crafting orders monitoring disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_QUESTING) then
    local repMonitor = CreateFrame("Frame", "JNRReputationMonitor", nil, "JournalatorReputationMonitorTemplate")
    if Auctionator.Constants.IsClassic then
      CreateFrame("Frame", "JNRQuestsMonitor", nil, "JournalatorQuestsClassicMonitorTemplate")
    else
      CreateFrame("Frame", "JNRQuestsMonitor", nil, "JournalatorQuestsMainlineMonitorTemplate")
    end
    JNRQuestsMonitor:SetReputationMonitor(repMonitor)
  else
    Journalator.Debug.Message("quest monitoring disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_TRADING_POST) then
    if not Auctionator.Constants.IsClassic then
      CreateFrame("Frame", "JNRTradingPostMonitor", nil, "JournalatorTradingPostMonitorTemplate")
    end
  else
    Journalator.Debug.Message("trading post monitor disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_LOOTING) then
    CreateFrame("Frame", "JNRLootContainersMonitor", nil, "JournalatorLootContainersMonitorTemplate")
  else
    Journalator.Debug.Message("looting monitor disabled")
  end

  if Journalator.Config.Get(Journalator.Config.Options.MONITOR_WOW_TOKENS) then
    if not Auctionator.Constants.IsClassic then
      CreateFrame("Frame", "JNRWoWTokensMonitor", nil, "JournalatorWoWTokensMonitorTemplate")
    end
  else
    Journalator.Debug.Message("wow token monitor disabled")
  end
end

function Journalator.InitializeBase()
  Journalator.Config.InitializeData()

  Journalator.Archiving.Initialize()

  Journalator.State.CurrentVersion = GetAddOnMetadata("Journalator", "Version")

  Journalator.SlashCmd.Initialize()

  Journalator.Statistics.InitializeCache()

  Journalator.MinimapIcon.Initialize()

  Journalator.ToggleView = function()
    if JNRView == nil then
      CreateFrame("Frame", "JNRView", UIParent, "JournalatorDisplayTemplate")
    end

    JNRView:SetShown(not JNRView:IsShown())
  end
end

function Journalator.InitializeMonitoring()
  local faction = UnitFactionGroup("player")
  Journalator.State.Source = {
    realm = GetRealmName(),
    character = GetUnitName("player"),
    faction = faction,
  }

  SetupMonitors()
end
