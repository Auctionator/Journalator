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

local scannedInfos = 0
local function MapItemLinks()
  local currentInfos = #JOURNALATOR_LOGS.Posting + #JOURNALATOR_LOGS.Invoices
  if scannedInfos >= currentInfos then
    return
  end
  scannedInfos = currentInfos

  for index, item in ipairs(JOURNALATOR_LOGS.Posting) do
    if item.itemLink ~= nil then
      local key = GetKey(item.itemName, item.deposit, item.count)
      if not cleanItemLinkMap[key] then
        cleanItemLinkMap[key] = CleanItemLink(item.itemLink)
      end
    end
  end
end

function Journalator.GetItemInfo(name, deposit, count)
  MapItemLinks()

  return cleanItemLinkMap[GetKey(name, deposit, count)]
end
