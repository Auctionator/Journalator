Journalator.Tooltips = {}

local function GetSaleRate(itemName)
  local sold, failed = 0, 0
  for _, item in ipairs(Journalator.Archiving.GetRange(0, "Failures")) do
    if item.itemName == itemName then
      failed = failed + item.count
    end
  end

  for _, item in ipairs(Journalator.Archiving.GetRange(0, "Invoices")) do
    if item.invoiceType == "seller" and item.itemName == itemName then
      sold = sold + item.count
    end
  end

  if sold == 0 and failed == 0 then
    return AUCTIONATOR_L_UNKNOWN
  else
    return Journalator.Utilities.PrettyPercentage(sold/(sold + failed) * 100)
  end
end

local function GetFailureCount(itemName)
  local failedCount = 0
  for _, item in ipairs(Journalator.Archiving.GetRange(0, "Failures")) do
    if item.itemName == itemName then
      failedCount = failedCount + item.count
    end
  end
  return tostring(failedCount)
end

local function GetLastSold(itemName)
  local invoices = Journalator.Archiving.GetRange(0, "Invoices")
  for index = #invoices, 1, -1 do
    local item = invoices[index]
    if item.invoiceType == "seller" and item.itemName == itemName then
      return item.value / item.count
    end
  end
end

local function GetLastBought(itemName)
  local invoices = Journalator.Archiving.GetRange(0, "Invoices")
  for index = #invoices, 1, -1 do
    local item = invoices[index]
    if item.invoiceType == "buyer" and item.itemName == itemName then
      return item.value / item.count
    end
  end
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
