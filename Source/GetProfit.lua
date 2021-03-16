function Journalator.GetProfit(startTime, endTime)
  local profit = 0
  -- Incoming and outgoing gold from sales and purchases
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if item.time >= startTime and item.time <= endTime then
      if item.invoiceType == "seller" then
        profit = profit + item.value + item.deposit - item.consignment
      else
        profit = profit - item.value
      end
    end
  end

  -- Lost gold from deposits
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if item.time >= startTime and item.time <= endTime then
      profit = profit - item.deposit
    end
  end

  return profit
end
