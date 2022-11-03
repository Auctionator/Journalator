Journalator.Tooltips = {}

local function GetSaleRate(itemName)
  local successes = Journalator.API.v1.GetRealmSuccessCountByItemName(JOURNALATOR_L_JOURNALATOR, itemName)
  local failures = Journalator.API.v1.GetRealmFailureCountByItemName(JOURNALATOR_L_JOURNALATOR, itemName)

  if successes == 0 and failures == 0 then
    return AUCTIONATOR_L_UNKNOWN
  else
    return Journalator.Utilities.PrettyPercentage(
      successes / (failures + successes) * 100
    )
  end
end

local function GetFailureCount(itemName)
  return tostring(Journalator.API.v1.GetRealmFailureCountByItemName(JOURNALATOR_L_JOURNALATOR, itemName))
end

local function GetLastSold(itemName)
  return Journalator.API.v1.GetRealmLastSoldByItemName(JOURNALATOR_L_JOURNALATOR, itemName)
end

local function GetLastBought(itemName)
  return Journalator.API.v1.GetRealmLastBoughtByItemName(JOURNALATOR_L_JOURNALATOR, itemName)
end

function Journalator.Tooltips.AnyEnabled()
  return JOURNALATOR_STATISTICS ~= nil and (
    Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_SALE_RATE) or
    Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_FAILURES) or
    Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_SOLD) or
    Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_BOUGHT)
    )
end

function Journalator.Tooltips.GetSalesInfo(itemName)
  local salesRate, failedString, lastSold, lastBought

  if Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_SALE_RATE) then
    salesRate = GetSaleRate(itemName)
  end

  if Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_FAILURES) then
    failedString = GetFailureCount(itemName)
  end

  if Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_SOLD) then
    lastSold = GetLastSold(itemName)
  end

  if Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_BOUGHT) then
    lastBought = GetLastBought(itemName)
  end

  return salesRate, failedString, lastSold, lastBought
end
