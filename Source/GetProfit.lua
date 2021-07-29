function Journalator.GetProfit(startTime, endTime)
  local incoming = 0
  local outgoing = 0
  local invoices = Journalator.Archiving.GetRange(startTime, "Invoices")
  -- Incoming and outgoing gold from sales and purchases
  for _, item in ipairs(invoices) do
    if item.time >= startTime and item.time <= endTime then
      if item.invoiceType == "seller" then
        incoming = incoming + item.value + item.deposit - item.consignment
      else
        outgoing = outgoing + item.value
      end
    end
  end

  -- Lost gold from deposits
  for _, item in ipairs(invoices) do
    if item.time >= startTime and item.time <= endTime then
      outgoing = outgoing + item.deposit
    end
  end

  local profit = 0

  return incoming - outgoing, incoming, outgoing
end
