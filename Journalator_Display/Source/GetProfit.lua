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

  local vendorRepairs = Journalator.Archiving.GetRange(startTime, "VendorRepairs")
  for _, item in ipairs(vendorRepairs) do
    local filterItem = {
      itemName = "",
      time = item.time,
      source = item.source,
    }
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        outgoing = outgoing + item.money
      end
    end
  end

  local taxis = Journalator.Archiving.GetRange(startTime, "Taxis")
  for _, item in ipairs(taxis) do
    local filterItem = {
      itemName = item.zone,
      time = item.time,
      source = item.source,
    }
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        outgoing = outgoing + item.money
      end
    end
  end

  local fulfillings = Journalator.Archiving.GetRange(startTime, "Fulfilling")
  for _, item in ipairs(fulfillings) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        incoming = incoming + item.tipAmount - item.consortiumCut
      end
    end
  end

  local quests = Journalator.Archiving.GetRange(startTime, "Questing")
  for _, item in ipairs(quests) do
    local filterItem = {
      itemName = item.questName,
      time = item.time,
      source = item.source,
    }
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        incoming = incoming + item.rewardMoney
        if item.requiredMoney then
          outgoing = outgoing + item.requiredMoney
        end
      end
    end
  end

  local looting = Journalator.Archiving.GetRange(startTime, "LootContainers")
  for _, item in ipairs(looting) do
    local filterItem = {
      time = item.time,
      source = item.source,
    }
    if item.type == "item" then
      filterItem.itemName = item.name
    elseif item.type == "npc" then
      filterItem.itemName = item.name
    else
      filterItem.itemName = JOURNALATOR_L_WORLD_OBJECT
    end
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        incoming = incoming + item.money
      end
    end
  end

  local wowTokens = Journalator.Archiving.GetRange(startTime, "WoWTokens")
  for _, item in ipairs(wowTokens) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        outgoing = outgoing + item.value
      end
    end
  end

  return incoming - outgoing, incoming, outgoing
end

function Journalator.GetDetailedProfits(startTime, endTime, filter)
  filter = filter or function() return true end

  local sales = 0
  local purchases = 0
  local lostDeposits = 0
  local lostFees = 0

  local invoices = Journalator.Archiving.GetRange(startTime, "Invoices")
  -- Incoming and outgoing gold from sales and purchases
  for _, item in ipairs(invoices) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        if item.invoiceType == "seller" then
          sales = sales + item.value
          lostFees = lostFees + item.consignment
          lostDeposits = lostDeposits - item.deposit
        else
          purchases = purchases + item.value
        end
      end
    end
  end

  -- Lost gold from deposits
  local postings = Journalator.Archiving.GetRange(startTime, "Posting")
  for _, item in ipairs(postings) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        lostDeposits = lostDeposits + item.deposit
      end
    end
  end

  local vendoring = Journalator.Archiving.GetRange(startTime, "Vendoring")
  for _, item in ipairs(vendoring) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        if item.vendorType == "sell" then
          sales = sales + item.unitPrice * item.count
        else
          purchases = purchases + item.unitPrice * item.count
        end
      end
    end
  end

  local vendorRepairs = Journalator.Archiving.GetRange(startTime, "VendorRepairs")
  for _, item in ipairs(vendorRepairs) do
    local filterItem = {
      itemName = "",
      time = item.time,
      source = item.source,
    }
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        purchases = purchases + item.money
      end
    end
  end

  local taxis = Journalator.Archiving.GetRange(startTime, "Taxis")
  for _, item in ipairs(taxis) do
    local filterItem = {
      itemName = item.zone,
      time = item.time,
      source = item.source,
    }
    if filterItem.time >= startTime and filterItem.time <= endTime then
      if filter(filterItem) then
        purchases = purchases + item.money
      end
    end
  end

  local fulfillings = Journalator.Archiving.GetRange(startTime, "Fulfilling")
  for _, item in ipairs(fulfillings) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        sales = sales + item.tipAmount - item.consortiumCut
      end
    end
  end

  local wowTokens = Journalator.Archiving.GetRange(startTime, "WoWTokens")
  for _, item in ipairs(wowTokens) do
    if item.time >= startTime and item.time <= endTime then
      if filter(item) then
        purchases = purchases + item.value
      end
    end
  end

  return sales, purchases, lostFees, math.max(0, lostDeposits), (sales - purchases - lostDeposits - lostFees)
end