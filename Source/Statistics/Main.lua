local STATISTICS_VERSION = 4

Journalator.Statistics = {}

function Journalator.Statistics.InitializeCache()
  if JOURNALATOR_STATISTICS == nil or JOURNALATOR_STATISTICS.Version ~= STATISTICS_VERSION then
    Journalator.Archiving.LoadUpTo(0, function()
      Journalator.Statistics.ComputeFullCache()
      Journalator.Utilities.Message(JOURNALATOR_L_FINISHED_COMPUTING_STATISTICS)
    end)
  end

  Auctionator.EventBus:Register({
    ReceiveEvent = function(_, _, newEntries)
      if JOURNALATOR_STATISTICS ~= nil then
        Journalator.Statistics.UpdateCache(newEntries)
      end
    end
  }, {
    Journalator.Events.LogsUpdated,
  })
end

local function AutoCreateCacheEntry(itemName, realm)
  if not JOURNALATOR_STATISTICS.Items[itemName] then
    JOURNALATOR_STATISTICS.Items[itemName] = {}
  end
  if not JOURNALATOR_STATISTICS.Items[itemName][realm] then
    JOURNALATOR_STATISTICS.Items[itemName][realm] = {
      failures = 0,
      successes = 0,
      lastSold = nil,
      lastBought = nil,
    }
  end
  return JOURNALATOR_STATISTICS.Items[itemName][realm]
end

function Journalator.Statistics.UpdateCache(newEntries)
  for key, entries in pairs(newEntries) do
    if key == "Invoices" then
      for _, item in ipairs(entries) do
        if item.invoiceType == "seller" then
          local cache = AutoCreateCacheEntry(item.itemName, item.source.realm)
          cache.successes = cache.successes + item.count
          cache.lastSold = {
            value = item.value / item.count,
            time = item.time
          }

        elseif item.invoiceType == "buyer" then
          -- Store item id specific entry for items purchased in addition to
          -- name only entry so that different DF quality items show the right
          -- last bought price
          Auctionator.Utilities.DBKeyFromLink(item.itemLink, function(dbKeys)
            for _, key in ipairs(dbKeys) do
              local cache = AutoCreateCacheEntry(dbKeys[1], item.source.realm)
              if not cache.lastBought or cache.lastBought.time < item.time then
                cache.lastBought = {
                  value = item.value / item.count,
                  time = item.time
                }
              end
            end
          end)

          -- Store by item name so that the API works and battle pets get last
          -- bought prices
          local cache = AutoCreateCacheEntry(item.itemName, item.source.realm)
          cache.lastBought = {
            value = item.value / item.count,
            time = item.time
          }
        end
        JOURNALATOR_STATISTICS.RealmConversion[Journalator.Utilities.NormalizeRealmName(item.source.realm)] = item.source.realm
      end

    elseif key == "Failures" then
      for _, item in ipairs(entries) do
        local cache = AutoCreateCacheEntry(item.itemName, item.source.realm)
        cache.failures = cache.failures + item.count
        JOURNALATOR_STATISTICS.RealmConversion[Journalator.Utilities.NormalizeRealmName(item.source.realm)] = item.source.realm
      end
    end
  end
end

local function reverseArray(array)
  local result = {}
  for index = #array, 1, -1 do
    table.insert(result, array[index])
  end

  return result
end
function Journalator.Statistics.ComputeFullCache()
  JOURNALATOR_STATISTICS = {
    Version = STATISTICS_VERSION,
    Items = {},
    RealmConversion = {}
  }

  Journalator.Statistics.UpdateCache({
    Invoices = reverseArray(Journalator.Archiving.GetRange(0, "Invoices")),
    Failures = reverseArray(Journalator.Archiving.GetRange(0, "Failures")),
  })
end

function Journalator.Statistics.GetByNormalizedRealmName(itemName, normalizedRealmName)
  if JOURNALATOR_STATISTICS.Items[itemName] ~= nil then
    return JOURNALATOR_STATISTICS.Items[itemName][JOURNALATOR_STATISTICS.RealmConversion[normalizedRealmName]]
  else
    return nil
  end
end
