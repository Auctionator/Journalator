local function SearchLog(log, cache)
  for _, item in ipairs(log) do
    if not cache[item.source.realm] then
      cache[item.source.realm] = {}
    end
    cache[item.source.realm][item.source.character] = true
  end
end

function Journalator.GetCharactersAndRealms(fromTime)
  local cache = {}

  SearchLog(Journalator.Archiving.GetRange(fromTime, "Invoices"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "Posting"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "Failures"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "Vendoring"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "Fulfilling"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "CraftingOrdersPlaced"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "Questing"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "TradingPostVendoring"), cache)
  SearchLog(Journalator.Archiving.GetRange(fromTime, "LootContainers"), cache)

  return cache
end
