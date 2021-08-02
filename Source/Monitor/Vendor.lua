JournalatorVendorMonitorMixin = {}

local function GetSalesIDFromLocation(location)
  if location:IsValid() then
    return C_Item.GetItemGUID(location) .. " " .. C_Item.GetStackCount(location)
  end
end

local function GetSalesIDFromBagAndSlot(bag, slot)
  local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
  return GetSalesIDFromLocation(location)
end

local function IsSalesIDInBag(salesID)
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      if GetSalesIDFromBagAndSlot(bag, slot) == salesID then
        return true
      end
    end
  end
  return false
end

local function GetAllSalesIDs()
  local result = {}
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local salesID = GetSalesIDFromBagAndSlot(bag, slot)
      if salesID ~= nil then
        table.insert(result, salesID)
      end
    end
  end

  return result
end

local function IsAnyNewSalesIDs(oldSalesIDs)
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local salesID = GetSalesIDFromBagAndSlot(bag, slot)
      if salesID ~= nil and tIndexOf(oldSalesIDs, salesID) == nil then
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
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE"
  })
  self:RegisterRightClickToSellHandlers()
  self:RegisterDragToSellHandlers()

  self:RegisterBuybackHandlers()

  self:RegisterPurchaseHandlers()
end

function JournalatorVendorMonitorMixin:OnUpdate()
  self:CheckCursorItemsForDragging()
end

function JournalatorVendorMonitorMixin:RegisterRightClickToSellHandlers()
  hooksecurefunc(_G, "UseContainerItem", function(bag, slot)
    if not self.merchantShown then
      return
    end

    local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)

    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then
      return
    end
    local salesID = GetSalesIDFromBagAndSlot(bag, slot)
    item:ContinueOnItemLoad(function()
      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.expectedToUpdate[salesID] = {
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
end

function JournalatorVendorMonitorMixin:UpdateCursorItem()
  self.lastCursorItem = nil

  if not self.merchantShown then
    return
  end

  local itemLocation = C_Cursor.GetCursorItem()
  if itemLocation then
    local salesID = GetSalesIDFromLocation(itemLocation)
    local itemLink = C_Item.GetItemLink(itemLocation)
    local itemCount = C_Item.GetStackCount(itemLocation)

    self.expectedToUpdate[salesID] = nil

    local item = Item:CreateFromItemLocation(itemLocation)
    item:ContinueOnItemLoad(function()
      -- If this item has been queued to be sold, it should no longer be on the
      -- cursor and in the queue, we just reset the queue so it works to check
      -- it.
      if self.expectedToUpdate[salesID] ~= nil then
        return
      end

      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.lastCursorItem = {
        salesID = salesID,
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
end

function JournalatorVendorMonitorMixin:RegisterDragToSellHandlers()
  hooksecurefunc(_G, "PickupMerchantItem", function(index)
    if not self.merchantShown then
      return
    end

    if self.lastCursorItem ~= nil and C_Cursor.GetCursorItem() == nil then
      self.expectedToUpdate[self.lastCursorItem.salesID] = self.lastCursorItem.item
    end
    self.lastCursorItem = nil
  end)

  -- Handle pickups by other addons
  hooksecurefunc(_G, "PickupGuildBankItem", function()
    self:UpdateCursorItem()
  end)
  hooksecurefunc(_G, "PickupInventoryItem", function()
    self:UpdateCursorItem()
  end)
  hooksecurefunc(_G, "PickupBagFromSlot", function()
    self:UpdateCursorItem()
  end)
  hooksecurefunc(_G, "PickupItem", function()
    self:UpdateCursorItem()
  end)
  hooksecurefunc(_G, "PickupContainerItem", function()
    self:UpdateCursorItem()
  end)
end

function JournalatorVendorMonitorMixin:CheckCursorItemsForDragging()
  self:UpdateCursorItem()
end

function JournalatorVendorMonitorMixin:RegisterBuybackHandlers()
  hooksecurefunc(_G, "BuybackItem", function(index)
    if not self.merchantShown then
      return
    end

    local name, _, price, quantity = GetBuybackItemInfo(index)
    local link = GetBuybackItemLink(index)

    self.expectedToUpdate["buy"] = {
      vendorType = "buyback",
      itemName = name,
      count = quantity,
      unitPrice = price / quantity,
      itemLink = link,
      time = time(),
      source = Journalator.State.Source,
    }
    self.lastScannedSalesIDs = GetAllSalesIDs()
  end)
end

function JournalatorVendorMonitorMixin:RegisterPurchaseHandlers()
  hooksecurefunc(_G, "BuyMerchantItem", function(index, quantity)
    if not self.merchantShown then
      return
    end

    quantity = quantity or 1

    local name, _, price, stackSize, numInStock = GetMerchantItemInfo(index)
    local link = GetMerchantItemLink(index)

    if price ~= 0 and numInStock ~= 0 then
      self.expectedToUpdate["buy"] = {
        vendorType = "purchase",
        itemName = name,
        count = quantity,
        unitPrice = price / stackSize,
        itemLink = link,
        time = time(),
        source = Journalator.State.Source,
      }
      self.lastScannedSalesIDs = GetAllSalesIDs()
    end
  end)
end

function JournalatorVendorMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MERCHANT_SHOW" then
    self:SetScript("OnUpdate", self.OnUpdate)
    self.merchantShown = true

  elseif eventName == "MERCHANT_CLOSED" then
    self:SetScript("OnUpdate", nil)
    self.expectedToUpdate = {}
    self.merchantShown = false

  elseif eventName == "MERCHANT_CLOSED" then

  elseif eventName == "MERCHANT_UPDATE" or eventName == "BAG_UPDATE" then
    for salesID, item in pairs(self.expectedToUpdate) do
      -- Check if an item sold to the vendor has disappeared from the player's
      -- bag
      if item.vendorType == "sell" and not IsSalesIDInBag(salesID) then
        table.insert(Journalator.State.Logs.Vendoring, item)
        self.expectedToUpdate[salesID] = nil

      -- Check if any new item has appeared in the player's bag (which is enough
      -- to check if a buyback item has been bought back)
      elseif (item.vendorType == "purchase" or item.vendorType == "buyback")
          and IsAnyNewSalesIDs(self.lastScannedSalesIDs) then
        table.insert(Journalator.State.Logs.Vendoring, item)
        self.lastScannedSalesIDs = GetAllSalesIDs()
        self.expectedToUpdate[salesID] = nil
      end
    end
  end
end
