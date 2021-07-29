JournalatorVendorMonitorMixin = {}

function JournalatorVendorMonitorMixin:OnLoad()
  -- Used to detect the successful sale of an item
  self.expectedToSell = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "BAG_UPDATE", "PLAYER_MONEY"
  })

  hooksecurefunc(_G, "UseContainerItem", function(bag, slot)
    if not self.merchantShown then
      return
    end

    local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)

    local item = Item:CreateFromItemLink(itemLink)
    item:ContinueOnItemLoad(function()
      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.expectedToSell = {
        vendorType = "sell",
        itemName = Journalator.Utilities.GetNameFromLink(itemLink),
        count = itemCount,
        unitPrice = vendorPrice,
        itemLink = itemLink,
        time = time(),
        source = Journalator.State.Source,
      }
    end)
  end)

  hooksecurefunc(_G, "BuybackItem", function(index)
    if not self.merchantShown then
      return
    end

    local name, _, price, quantity = GetBuybackItemInfo(index)
    local link = GetBuybackItemLink(index)

    table.insert(Journalator.State.Logs.Vendoring, {
      vendorType = "buyback",
      itemName = name,
      count = quantity,
      unitPrice = price / quantity,
      itemLink = link,
      time = time(),
      source = Journalator.State.Source,
    })
  end)

  hooksecurefunc(_G, "BuyMerchantItem", function(index, quantity)
    if not self.merchantShown then
      return
    end

    quantity = quantity or 1

    local name, _, price, stackSize, numInStock = GetMerchantItemInfo(index)
    local link = GetMerchantItemLink(index)

    if price ~= 0 and numInStock ~= 0 then
      table.insert(Journalator.State.Logs.Vendoring, {
        vendorType = "purchase",
        itemName = name,
        count = quantity,
        unitPrice = price / stackSize,
        itemLink = link,
        time = time(),
        source = Journalator.State.Source,
      })
    end
  end)
end

function JournalatorVendorMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MERCHANT_SHOW" then
    self.merchantShown = true
  elseif eventName == "MERCHANT_CLOSED" then
    self.merchantShown = false
  elseif eventName == "BAG_UPDATE" then
    self.expectedToSell = nil
  elseif eventName == "PLAYER_MONEY" and self.expectedToSell then
    table.insert(Journalator.State.Logs.Vendoring, self.expectedToSell)
    self.expectedToSell = nil
  end
end
