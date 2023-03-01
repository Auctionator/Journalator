function Journalator.API.ComposeError(callerID, message)
  error(
    "Contact the maintainer of " .. callerID ..
    " to resolve this problem. Details: " .. message
  )
end

-- TODO: Maintain authorization keys for add-ons to prevent false callerIDs
function Journalator.API.CheckID(callerID)
  if type(callerID) ~= "string" or callerID == "" then
    error("Invalid callerID. Use the name of your add-on.")
  end
end

function Journalator.API.v1.GetRealmFailureCountByItemName(callerID, itemName)
  Journalator.API.CheckID(callerID)
  if type(itemName) ~= "string" then
    Journalator.API.ComposeError(callerID, "Usage Journalator.API.v1.GetRealmFailureCountByItemName(string, string)")
  end

  local failures = 0
  for _, realm in ipairs(Journalator.Utilities.GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil then
      failures = failures + realmData.failures
    end
  end

  return failures
end

function Journalator.API.v1.GetRealmSuccessCountByItemName(callerID, itemName)
  assert(type(callerID) == "string")
  if type(itemName) ~= "string" then
    Journalator.API.ComposeError(callerID, "Usage Journalator.API.v1.GetRealmSuccessCountByItemName(string, string)")
  end

  local successes = 0
  for _, realm in ipairs(Journalator.Utilities.GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil then
      successes = successes + realmData.successes
    end
  end

  return successes
end

function Journalator.API.v1.GetRealmLastSoldByItemName(callerID, itemName)
  assert(type(callerID) == "string")
  if type(itemName) ~= "string" then
    Journalator.API.ComposeError(callerID, "Usage Journalator.API.v1.GetRealmLastSoldByItemName(string, string)")
  end

  local lastSold = nil
  local lastSoldTime
  for _, realm in ipairs(Journalator.Utilities.GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil and realmData.lastSold ~= nil and (lastSoldTime == nil or lastSoldTime < realmData.lastSold.time) then
      lastSold = realmData.lastSold.value
      lastSoldTime = realmData.lastSold.time
    end
  end

  return lastSold
end

function Journalator.API.v1.GetRealmLastBoughtByItemName(callerID, itemName)
  assert(type(callerID) == "string")
  if type(itemName) ~= "string" then
    Journalator.API.ComposeError(callerID, "Usage Journalator.API.v1.GetRealmLastBoughtByItemName(string, string)")
  end

  local lastBought = nil
  local lastBoughtTime
  for _, realm in ipairs(Journalator.Utilities.GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(itemName, realm)
    if realmData ~= nil and realmData.lastBought ~= nil and (lastBoughtTime == nil or lastBoughtTime < realmData.lastBought.time) then
      lastBought = realmData.lastBought.value
      lastBoughtTime = realmData.lastBought.time
    end
  end

  return lastBought
end

function Journalator.API.v1.GetRealmLastBoughtByItemLink(callerID, itemLink)
  assert(type(callerID) == "string")
  if type(itemLink) ~= "string" then
    Journalator.API.ComposeError(callerID, "Usage Journalator.API.v1.GetRealmLastBoughtByItemLink(string, string)")
  end

  local dbKey
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeys)
    dbKey = dbKeys[1]
  end)
  if dbKey == nil then
    Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
  end

  local lastBought = nil
  local lastBoughtTime
  for _, realm in ipairs(Journalator.Utilities.GetRealmNames()) do
    local realmData = Journalator.Statistics.GetByNormalizedRealmName(dbKey, realm)
    if realmData ~= nil and realmData.lastBought ~= nil and (lastBoughtTime == nil or lastBoughtTime < realmData.lastBought.time) then
      lastBought = realmData.lastBought.value
      lastBoughtTime = realmData.lastBought.time
    end
  end

  return lastBought
end
