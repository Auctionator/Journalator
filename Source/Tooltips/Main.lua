function Journalator.Tooltips.GetSalesInfo(itemName)
  local salesRate = nil

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE) then
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
      salesRate = AUCTIONATOR_L_UNKNOWN
    elseif posted == 0 then
      salesRate = "100%"
    else
      salesRate = Journalator.Utilities.PrettyPercentage(sold/posted * 100)
    end
  end

  local failedString = nil

  if Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES) then
    local failedCount = 0
    for _, item in ipairs(JOURNALATOR_LOGS.Failures) do
      if item.itemName == itemName then
        failedCount = failedCount + 1
      end
    end
    failedString = tostring(failedCount)
  end

  return salesRate, failedString
end
