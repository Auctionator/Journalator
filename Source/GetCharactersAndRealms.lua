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

  return cache
end
