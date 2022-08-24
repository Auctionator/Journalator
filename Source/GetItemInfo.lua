local cleanItemLinkMap = {}

local function GetKey(name, deposit, count)
  return name .. "[]" .. (deposit/count)
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
    local key = GetKey(item.itemName, item.deposit, item.count)
    if not cleanItemLinkMap[key] then
      cleanItemLinkMap[key] = CleanItemLink(item.itemLink)
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

function Journalator.GetItemInfo(name, deposit, count, timeLimit)
  MapItemLinks(timeLimit - Journalator.Constants.ARCHIVE_INTERVAL)

  return cleanItemLinkMap[GetKey(name, deposit, count)]
end
