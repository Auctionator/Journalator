function Journalator.GetProfit(startTime, endTime, filter)
  filter = filter or function() return true end
  local incoming = 0
  local outgoing = 0
  local invoices = Journalator.Archiving.GetRange(startTime, "Invoices")
  -- Incoming and outgoing gold from sales and purchases
  for _, item in ipairs(invoices) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        if item.invoiceType == "seller" then
          incoming = incoming + item.value + item.deposit - item.consignment
        else
          outgoing = outgoing + item.value
        end
      end
    end
  end

  -- Lost gold from deposits
  local postings = Journalator.Archiving.GetRange(startTime, "Posting")
  for _, item in ipairs(postings) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        outgoing = outgoing + item.deposit
      end
    end
  end

  local vendoring = Journalator.Archiving.GetRange(startTime, "Vendoring")
  for _, item in ipairs(vendoring) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        if item.vendorType == "sell" then
          incoming = incoming + item.unitPrice * item.count
        else
          outgoing = outgoing + item.unitPrice * item.count
        end
      end
    end
  end

  return incoming - outgoing, incoming, outgoing
end
