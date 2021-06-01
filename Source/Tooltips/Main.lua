Journalator.Tooltips = {}

local function GetSaleRate(itemName)
  local sold, posted = 0, 0
  for _, item in ipairs(JOURNALATOR_LOGS.Posting) do
    if item.itemName == itemName then
      posted = posted + item.count
    end
  end

  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if item.invoiceType == "seller" and item.itemName == itemName then
      sold = sold + item.count
    end
  end

  if posted == 0 and sold == 0 then
    return AUCTIONATOR_L_UNKNOWN
  elseif posted == 0 then
    return "100%"
  else
    return Journalator.Utilities.PrettyPercentage(sold/posted * 100)
  end
end

local function GetFailureCount(itemName)
  local failedCount = 0
  for _, item in ipairs(JOURNALATOR_LOGS.Failures) do
    if item.itemName == itemName then
      failedCount = failedCount + item.count
    end
  end
  return tostring(failedCount)
end

local function GetLastSold(itemName)
  for index = #JOURNALATOR_LOGS.Invoices, 1, -1 do
    local item = JOURNALATOR_LOGS.Invoices[index]
    if item.invoiceType == "seller" and item.itemName == itemName then
      return item.value / item.count
    end
  end
end

local function GetLastBought(itemName)
  for index = #JOURNALATOR_LOGS.Invoices, 1, -1 do
    local item = JOURNALATOR_LOGS.Invoices[index]
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

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SALE) then
    lastSold = GetLastSold(itemName)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_PURCHASE) then
    lastBought = GetLastBought(itemName)
  end

  return salesRate, failedString, lastSold, lastBought
end
