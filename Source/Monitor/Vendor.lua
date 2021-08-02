JournalatorVendorMonitorMixin = {}

local EQUIPMENT_SLOT_CAP = 19

local function GetGUIDFromLocation(location)
  if location:IsValid() then
    return C_Item.GetItemGUID(location) .. " " .. C_Item.GetStackCount(location)
  end
end

local function GetGUIDFromBagAndSlot(bag, slot)
  local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
  return GetGUIDFromLocation(location)
end

local function GetGUIDFromEquipmentSlot(slot)
  local location = ItemLocation:CreateFromEquipmentSlot(slot)
  return GetGUIDFromLocation(location)
end

local function IsGUIDInPossession(guid)
  -- Check if an item in a bag has disappeared/been sold.
  for bag = 0, 4 do
    -- Start the slots at 0 in include the container's item
    for slot = 0, GetContainerNumSlots(bag) do
      if GetGUIDFromBagAndSlot(bag, slot) == guid then
        return true
      end
    end
  end

  -- Check if an equipped item has disappeared/been sold
  for equipmentSlot = 1, EQUIPMENT_SLOT_CAP do
    if GetGUIDFromEquipmentSlot(equipmentSlot) == guid then
      return true
    end
  end

  return false
end

local function GetGUIDStackSizes()
  local result = {}

  for bag = 0, 4 do
    -- Start the slots at 0 in include the container's item
    for slot = 0, GetContainerNumSlots(bag) do
      local guid = GetGUIDFromBagAndSlot(bag, slot)
      if guid ~= nil then
        local _, count, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
        result[guid] = {count = count, itemLink = itemLink}
      end
    end
  end

  --We don't check equipped items as you can't buy directly to an equipment slot

  return result
end

function JournalatorVendorMonitorMixin:OnLoad()
  self:ResetExpected()

  FrameUtil.RegisterFrameForEvents(self, {
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE"
  })
  self:RegisterRightClickToSellHandlers()
  self:RegisterDragToSellHandlers()

  self:RegisterBuybackHandlers()

  self:RegisterPurchaseHandlers()
end

function JournalatorVendorMonitorMixin:OnUpdate()
  self:CheckCursorItemsForDragging()
end

  -- Used to detect the successful sale of an item
function JournalatorVendorMonitorMixin:ResetExpected()
  self.expectedToSell = {}
  self.expectedToPurchase = {}
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
    local guid = GetGUIDFromBagAndSlot(bag, slot)
    item:ContinueOnItemLoad(function()
      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.expectedToSell[guid] = {
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
    local guid = GetGUIDFromLocation(itemLocation)
    local itemLink = C_Item.GetItemLink(itemLocation)
    local itemCount = C_Item.GetStackCount(itemLocation)

    self.expectedToSell[guid] = nil

    local item = Item:CreateFromItemLocation(itemLocation)
    item:ContinueOnItemLoad(function()
      -- If this item has been queued to be sold, it should no longer be on the
      -- cursor and in the queue, we just reset the queue so it works to check
      -- it.
      if self.expectedToSell[guid] ~= nil then
        return
      end

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
end

function JournalatorVendorMonitorMixin:RegisterDragToSellHandlers()
  hooksecurefunc(_G, "PickupMerchantItem", function(index)
    if not self.merchantShown then
      return
    end

    if self.lastCursorItem ~= nil and C_Cursor.GetCursorItem() == nil then
      self.expectedToSell[self.lastCursorItem.guid] = self.lastCursorItem.item
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

    self.expectedToSell["buy"] = {
      vendorType = "buyback",
      itemName = name,
      count = quantity,
      unitPrice = price / quantity,
      itemLink = link,
      time = time(),
      source = Journalator.State.Source,
    }
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
      table.insert(self.expectedToPurchase,{
        vendorType = "purchase",
        itemName = name,
        count = quantity,
        unitPrice = price / stackSize,
        itemLink = link,
        time = time(),
        source = Journalator.State.Source,
      })
      -- Sort in descending order. Used to determine which purchases have gone
      -- through.
      table.sort(self.expectedToPurchase, function(a, b)
        if a.itemLink == b.itemLink then
          return b.count < a.count
        else
          return a.itemLink < b.itemLink
        end
      end)
    end
  end)
end

function JournalatorVendorMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MERCHANT_SHOW" then
    self:SetScript("OnUpdate", self.OnUpdate)
    self:RegisterEvent("BAG_UPDATE")

    self:ResetExpected()
    self.oldStackSizes = GetGUIDStackSizes()
    self.merchantShown = true

  elseif eventName == "MERCHANT_CLOSED" then
    self:SetScript("OnUpdate", nil)
    self:UnregisterEvent("BAG_UPDATE")

    self:ResetExpected()
    self.merchantShown = false

  elseif eventName == "MERCHANT_UPDATE" then
    for guid, item in pairs(self.expectedToSell) do
      -- Check if an item sold to the vendor has disappeared from the player's
      -- bag
      if not IsGUIDInPossession(guid) then
        table.insert(Journalator.State.Logs.Vendoring, item)
        self.expectedToSell[guid] = nil
      end
    end

  elseif eventName == "BAG_UPDATE" then
    local newStackSizes = GetGUIDStackSizes()
    local newExpected = {}
    for _, item in ipairs(self.expectedToPurchase) do

      local foundMatch = false

      for guid, details in pairs(newStackSizes) do
        if details.itemLink == item.itemLink then
          if self.oldStackSizes[guid] == nil then
            foundMatch = true
            break
          elseif newStackSizes[guid].count - self.oldStackSizes[guid].count >= item.count then
            foundMatch = true
            self.oldStackSizes[guid].count = self.oldStackSizes[guid].count + item.count
            break
          end
        end
      end

      if foundMatch then
        table.insert(Journalator.State.Logs.Vendoring, item)
      else
        table.insert(newExpected, item)
      end
    end
    self.oldStackSizes = newStackSizes
  end
end
