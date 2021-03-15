function Journalator.GetProfit(period)
  local profit = 0
  -- Incoming and outgoing gold from sales and purchases
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if time() - item.time <= period then
      if item.invoiceType == "seller" then
        profit = profit + item.value + item.deposit - item.consignment
      else
        profit = profit - item.value
      end
    end
  end

  -- Lost gold from deposits
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if time() - item.time <= period then
      profit = profit - item.deposit
    end
  end

  return profit
end
