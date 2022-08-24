local STATISTICS_VERSION = 2

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

local function AutoCreateCacheEntry(itemName)
  if not JOURNALATOR_STATISTICS[itemName] then
    JOURNALATOR_STATISTICS[itemName] = {
      failures = 0,
      successes = 0,
      lastSold = nil,
      lastBought = nil,
    }
  end
  return JOURNALATOR_STATISTICS[itemName]
end

function Journalator.Statistics.UpdateCache(newEntries)
  for key, entries in pairs(newEntries) do
    if key == "Invoices" then
      for _, item in ipairs(entries) do
        local cache = AutoCreateCacheEntry(item.itemName)
        if item.invoiceType == "seller" then
          cache.successes = cache.successes + item.count
          cache.lastSold = item.value / item.count
        elseif item.invoiceType == "buyer" then
          cache.lastBought = item.value / item.count
        end
      end
    elseif key == "Failures" then
      for _, item in ipairs(entries) do
        local cache = AutoCreateCacheEntry(item.itemName)
        cache.failures = cache.failures + item.count
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
  }

  Journalator.Statistics.UpdateCache({
    Invoices = reverseArray(Journalator.Archiving.GetRange(0, "Invoices")),
    Failures = reverseArray(Journalator.Archiving.GetRange(0, "Failures")),
  })
end
