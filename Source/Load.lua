function Journalator.Load()
  JOURNALATOR_MAIL_AUCTIONS_LOG = JOURNALATOR_MAIL_AUCTIONS_LOG or {}
  JOURNALATOR_LOGS = JOURNALATOR_LOGS or {
    Version = 1,
    Invoices = {},
    Posting = {},
  }
  if JOURNALATOR_LOGS.Version ~= 1 then
    error("Unexpected log version")
  end

  CreateFrame("Frame", "JNRMonitor", nil, "JournalatorMailMonitorTemplate")
  CreateFrame("Frame", "JNRView", UIParent, "JournalatorLogViewTemplate")
  JNRView:Hide()

  Journalator.SlashCmd.Initialize()
  Journalator.Source = {
    realm = GetRealmName(),
    character = GetUnitName("player"),
  }
end
