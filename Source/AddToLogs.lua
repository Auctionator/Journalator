function Journalator.AddToLogs(newEntries)
  Journalator.Archiving.AutogenerateStore()

  for key, list in pairs(newEntries) do
    for _, value in ipairs(list) do
      table.insert(Journalator.State.Logs[key], value)
    end
  end
  Auctionator.EventBus:Fire(Journalator.AddToLogs, Journalator.Events.LogsUpdated, newEntries)
end

Auctionator.EventBus:RegisterSource(Journalator.AddToLogs, "Journalator.AddToLogs")
