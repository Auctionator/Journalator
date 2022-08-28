Journalator.Tooltips = {}

local function GetRealmNames()
  local connected = GetAutoCompleteRealms()
  if #connected > 0 then
    return connected
  else
    return { GetNormalizedRealmName() }
  end
end

local function GetSaleRate(itemName)
  local successes = 0
  local failures = 0
  for _, realm in ipairs(GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil then
      successes = successes + realmData.successes
      failures = failures + realmData.failures
    end
  end

  if successes == 0 and failures == 0 then
    return AUCTIONATOR_L_UNKNOWN
  else
    return Journalator.Utilities.PrettyPercentage(
      successes / (failures + successes) * 100
    )
  end
end

local function GetFailureCount(itemName)
  local failures = 0
  for _, realm in ipairs(GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil then
      failures = failures + realmData.failures
    end
  end

  return tostring(failures)
end

local function GetLastSold(itemName)
  local lastSold = nil
  local lastSoldTime
  for _, realm in ipairs(GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil and realmData.lastSold ~= nil and (lastSoldTime == nil or lastSoldTime < realmData.lastSold.time) then
      lastSold = realmData.lastSold.value
      lastSoldTime = realmData.lastSold.time
    end
  end

  return lastSold
end

local function GetLastBought(itemName)
  local lastBought = nil
  local lastBoughtTime
  for _, realm in ipairs(GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil and realmData.lastBought ~= nil and (lastBoughtTime == nil or lastBoughtTime < realmData.lastBought.time) then
      lastBought = realmData.lastBought.value
      lastBoughtTime = realmData.lastBought.time
    end
  end

  return lastBought
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
