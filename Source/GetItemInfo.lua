local itemInfoMap = {}

local function GetUnitDeposit(deposit, count)
  if Auctionator.Constants.IsClassic then
    return math.floor(deposit / count)
  else
    return math.max(math.floor(deposit / count), 100)
  end
end

local function AddToMap(item)
  itemInfoMap[item.itemName] = itemInfoMap[item.itemName] or {}

  table.insert(itemInfoMap[item.itemName], {
    unitPrice = item.buyout or item.bid,
    unitDeposit = GetUnitDeposit(item.deposit, item.count),
    time = item.time,
    itemLink = item.itemLink
  })
end

local scannedInfos = 0
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

-- Returns an item link, given a unit price.
-- If no unit price is known pass in 0.
function Journalator.GetItemInfo(name, unitPrice, unitDeposit, timestamp, timeLimit)
  MapItemLinks(timeLimit - Journalator.Constants.LINK_INTERVAL)

  if not itemInfoMap[name] then
    return nil
  end

  for index, item in ipairs(itemInfoMap[name]) do
    if item.time <= timestamp and item.unitDeposit == unitDeposit and item.unitPrice == unitPrice then
      return Journalator.Utilities.CleanItemLink(item.itemLink)
    end
  end

  return nil
end
