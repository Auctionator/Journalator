local function SearchLog(log, cache)
  for _, item in ipairs(log) do
    if not cache[item.source.realm] then
      cache[item.source.realm] = {}
    end
    cache[item.source.realm][item.source.character] = true
  end
end

function Journalator.GetCharactersAndRealms()
  local cache = {}

  for key, log in pairs(JOURNALATOR_LOGS) do
    if key ~= "Version" then
      SearchLog(log, cache)
    end
  end

  return cache
end
