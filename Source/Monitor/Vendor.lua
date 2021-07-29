JournalatorVendorMonitorMixin = {}

local function GetGUIDFromBagAndSlot(bag, slot)
  local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
  if location:IsValid() then
    local guid = C_Item.GetItemGUID(location)
    return guid
  end
end

local function IsGUIDInBag(guid)
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      if GetGUIDFromBagAndSlot(bag, slot) == guid then
        return true
      end
    end
  end
  return false
end

function JournalatorVendorMonitorMixin:OnLoad()
  -- Used to detect the successful sale of an item
  self.expectedToUpdate = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE"
  })

  hooksecurefunc(_G, "UseContainerItem", function(bag, slot)
    if not self.merchantShown then
      return
    end

    local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)

    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then
      return
    end
    local guid = GetGUIDFromBagAndSlot(bag, slot)
    item:ContinueOnItemLoad(function()
      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.expectedToUpdate[guid] = {
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
  MerchantFrame:HookScript("OnEnter", function()
    local itemLocation = C_Cursor.GetCursorItem()
    if itemLocation ~= nil then
      local guid = C_Item.GetItemGUID(itemLocation)
      local itemLink = C_Item.GetItemLink(itemLocation)
      local itemCount = C_Item.GetStackCount(itemLocation)
      local item = Item:CreateFromItemLocation(itemLocation)
      item:ContinueOnItemLoad(function()
        local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
        self.lastCursorItem = {
          guid = guid,
          item = {
            vendorType = "sell",
            itemName = Journalator.Utilities.GetNameFromLink(itemLink),
            count = itemCount,
            unitPrice = vendorPrice,
            itemLink = itemLink,
            time = time(),
            source = Journalator.State.Source,
          },
        }
      end)
    end
  end)
  MerchantFrame:HookScript("OnLeave", function()
    self.lastCursorItem = nil
  end)
  hooksecurefunc(_G, "PickupMerchantItem", function(index)
    if self.lastCursorItem ~= nil then
      self.expectedToUpdate[self.lastCursorItem.guid] = self.lastCursorItem.item
      self.lastCursorItem = nil
    end
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
    self.expectedToUpdate = {}
    self.merchantShown = false
  elseif eventName == "MERCHANT_UPDATE" then
    for guid, item in pairs(self.expectedToUpdate) do
      if item.vendorType == "sell" and not IsGUIDInBag(guid) then
        table.insert(Journalator.State.Logs.Vendoring, item)
        self.expectedToUpdate[guid] = nil
      end
    end
  end
end
