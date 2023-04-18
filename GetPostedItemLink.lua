local itemLinkMap = {}

-- Round deposit (retail and classic) and limit least value to 1s if on retail
local function GetUnitDeposit(deposit, count)
  if Auctionator.Constants.IsClassic then
    return math.floor(deposit / count)
  else
    return math.max(math.floor(deposit / count), 100)
  end
end

local function AddToMap(item)
  itemLinkMap[item.itemName] = itemLinkMap[item.itemName] or {}

  table.insert(itemLinkMap[item.itemName], {
    unitPrice = item.buyout or item.bid,
    unitDeposit = GetUnitDeposit(item.deposit, item.count),
    time = item.time,
    itemLink = item.itemLink
  })
end

-- Size of the writable logs (ie. not read only) when the logs were last scanned
local scannedInfos = 0
-- Last timestamp the logs were scanned for item links
local seenTime = nil
local function MapItemLinks(timeLimit)
  local currentInfos = #Journalator.State.Logs.Posting
  if scannedInfos >= currentInfos and (seenTime ~= nil and seenTime <= timeLimit) then
    return
  end
  scannedInfos = currentInfos
  seenTime = timeLimit

  for index, item in ipairs(Journalator.Archiving.GetRange(timeLimit, "Posting")) do
    AddToMap(item)
  end
end

-- Returns an item link that is probably the one matching an sold item invoice.
--
-- Returns a stripped down item link missing item level information if
-- unitPrice, unitDeposit or timestamp are not supplied
function Journalator.GetPostedItemLink(name, unitPrice, unitDeposit, timestamp, timeLimit)
  MapItemLinks(timeLimit - Journalator.Constants.LINK_INTERVAL)

  if not itemLinkMap[name] then
    return nil
  end

  if unitPrice == nil or unitDeposit == nil or timestamp == nil then
    return Journalator.Utilities.PurgeLevelsFromLink(itemLinkMap[name][1].itemLink)
  end

  for index, item in ipairs(itemLinkMap[name]) do
    if item.time <= timestamp and item.unitDeposit == GetUnitDeposit(unitDeposit, 1) and item.unitPrice == unitPrice then
      if item.itemLink == nil then
        return nil
      end
      return Journalator.Utilities.CleanItemLink(item.itemLink)
    end
  end

  return nil
end
