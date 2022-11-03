local cleanItemLinkMap = {}

local function GetKey(name, unitPrice, deposit)
  if not Auctionator.Constants.IsClassic then -- Deposit bottoms out at 1s on retail
    deposit = math.max(deposit, 100)
  end
  return name .. "[]" .. (unitPrice) .. " " .. (deposit)
end

local function CleanItemLink(link)
  if string.match(link, "battlepet") then
    return string.gsub(link, ":%d+:%d+:%d+:%d+:%d+:%d+:%d+|", ":0:0:0:0:0:0:0|")
  elseif link then
    return string.gsub(link, "item:(%d+):.-|", "item:%1|")
  end
end

local function AddToMap(item)
  if item.itemLink then
    local key = GetKey(item.itemName, item.buyout or item.bid, math.floor(item.deposit / item.count))
    if not cleanItemLinkMap[key] then
      cleanItemLinkMap[key] = CleanItemLink(item.itemLink)
    end
    local genericKey = GetKey(item.itemName, 0, 0)
    if not cleanItemLinkMap[genericKey] then
      cleanItemLinkMap[genericKey] = cleanItemLinkMap[key]
    end
  end
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
function Journalator.GetItemInfo(name, unitPrice, unitDeposit, timeLimit)
  MapItemLinks(timeLimit - Journalator.Constants.ARCHIVE_INTERVAL)

  return cleanItemLinkMap[GetKey(name, unitPrice, unitDeposit)]
end
