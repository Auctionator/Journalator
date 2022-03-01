Journalator.Tooltips = {}

local function GetSaleRate(itemName)
  local cache = JOURNALATOR_STATISTICS[itemName]

  if cache == nil or (cache.successes == 0 and cache.failures == 0) then
    return AUCTIONATOR_L_UNKNOWN
  else
    return Journalator.Utilities.PrettyPercentage(
      cache.successes / (cache.failures + cache.successes) * 100
    )
  end
end

local function GetFailureCount(itemName)
  local cache = JOURNALATOR_STATISTICS[itemName]

  if cache == nil then
    return "0"
  else
    return tostring(cache.failures)
  end
end

local function GetLastSold(itemName)
  local cache = JOURNALATOR_STATISTICS[itemName]

  if cache == nil then
    return nil
  else
    return cache.lastSold
  end
end

local function GetLastBought(itemName)
  local cache = JOURNALATOR_STATISTICS[itemName]

  if cache == nil then
    return nil
  else
    return cache.lastBought
  end
end

function Journalator.Tooltips.AnyEnabled()
  return JOURNALATOR_STATISTICS ~= nil and (
    Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE) or
    Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES) or
    Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD) or
    Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT)
    )
end

function Journalator.Tooltips.GetSalesInfo(itemName)
  local salesRate, failedString, lastSold, lastBought

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE) then
    salesRate = GetSaleRate(itemName)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES) then
    failedString = GetFailureCount(itemName)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD) then
    lastSold = GetLastSold(itemName)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT) then
    lastBought = GetLastBought(itemName)
  end

  return salesRate, failedString, lastSold, lastBought
end
