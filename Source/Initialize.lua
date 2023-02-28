local function SetupMonitors()
  CreateFrame("Frame", "JNRMailMonitor", nil, "JournalatorMailMonitorTemplate")
  CreateFrame("Frame", "JNRPostingMonitor", nil, "JournalatorPostingMonitorTemplate")
  CreateFrame("Frame", "JNRVendorMonitor", nil, "JournalatorVendorMonitorTemplate")

  if not Auctionator.Constants.IsClassic then
    CreateFrame("Frame", "JNRCraftingOrderPlacingMonitor", nil, "JournalatorCraftingOrderPlacingMonitorTemplate")
    CreateFrame("Frame", "JNRCraftingOrderFulfillingMonitor", nil, "JournalatorCraftingOrderFulfillingMonitorTemplate")
  end

  local repMonitor = CreateFrame("Frame", "JNRReputationMonitor", nil, "JournalatorReputationMonitorTemplate")
  if Auctionator.Constants.IsClassic then
    CreateFrame("Frame", "JNRQuestsMonitor", nil, "JournalatorQuestsClassicMonitorTemplate")
  else
    CreateFrame("Frame", "JNRQuestsMonitor", nil, "JournalatorQuestsMainlineMonitorTemplate")
  end
  JNRQuestsMonitor:SetReputationMonitor(repMonitor)

  if not Auctionator.Constants.IsClassic then
    CreateFrame("Frame", "JNRTradingPostMonitor", nil, "JournalatorTradingPostMonitorTemplate")
  end

  CreateFrame("Frame", "JNRLootContainersMonitor", nil, "JournalatorLootContainersMonitorTemplate")
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
