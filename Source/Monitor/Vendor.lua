JournalatorVendorMonitorMixin = {}

local EQUIPMENT_SLOT_CAP = 19

local function GetGUIDFromLocation(location)
  if C_Item.DoesItemExist(location) then
    return C_Item.GetItemGUID(location)
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

local function GetCountLinkFromBagAndSlot(bag, slot)
  if C_Container then
    local info = C_Container.GetContainerItemInfo(bag, slot)

    if info then
      return info.stackCount, info.hyperlink
    else
      return nil
    end
  else
    local _, count, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
    return count, link
  end
end

local function GetSlots(bag)
  if C_Container then
    return C_Container.GetContainerNumSlots(bag)
  else
    return GetContainerNumSlots(bag)
  end
end

local function GetRefundInfo(bag, slot, isEquipped)
  if C_Container then
    local info = C_Container.GetContainerItemPurchaseInfo(bag, slot, isEquipped)
    return info.money, info.refundSeconds
  else
    local money, _, refundSec = GetContainerItemPurchaseInfo(bag, slot, isEquipped)
    return money, refundSec
  end
end

local function IsGUIDInPossession(guid)
  -- Check if an item in a bag has disappeared/been sold.
  for bag = 0, 4 do
    -- Start the slots at 0 in include the container's item
    for slot = 0, GetSlots(bag) do
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
    for slot = 0, GetSlots(bag) do
      local guid = GetGUIDFromBagAndSlot(bag, slot)
      if guid ~= nil then
        local count, itemLink = GetCountLinkFromBagAndSlot(bag, slot)
        result[guid] = {count = count, itemLink = itemLink}
      end
    end
  end

  --We don't check equipped items as you can't buy directly to an equipment slot

  return result
end

-- Assumes GetItemInfo data is loaded
-- Returns true if a bag has the space for all of slotSizeNeeded*itemLink
local function IsLargeEnoughSlotAvailable(itemLink, slotSizeNeeded)
  local stackSize = select(8, GetItemInfo(itemLink))

  for bag = 0, 4 do
    local available = 0

    for slot = 1, GetSlots(bag) do
      local itemCount, slotLink = GetCountLinkFromBagAndSlot(bag, slot)
      if itemCount == 0 or itemCount == nil then
        available = available + stackSize
      elseif itemLink == slotLink then
        available = available + stackSize - itemCount
      end
    end

    if available >= slotSizeNeeded then
      return true
    end
  end

  return false
end

local MERCHANT_EVENTS = {
  "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE"
}

local PURCHASE_VALIDATION_EVENTS = {
  "BAG_UPDATE"
}

function JournalatorVendorMonitorMixin:OnLoad()
  self:ResetQueues()

  FrameUtil.RegisterFrameForEvents(self, MERCHANT_EVENTS)
  self:RegisterRightClickToSellHandlers()
  self:RegisterDragToSellHandlers()
  self:RegisterRefundHandlers()

  self:RegisterBuybackHandlers()

  self:RegisterPurchaseHandlers()
end

function JournalatorVendorMonitorMixin:OnUpdate()
  self:UpdateCursorItem()

  self:CheckPurchaseQueueForBagSpace()
end

function JournalatorVendorMonitorMixin:ResetQueues()
  -- Used to detect the successful sale or purchase of items
  -- Keeping a queue is necessary as addons automating merchants can make bulk
  -- purchases (reagents) and sales (e.g. of junk) which aren't fulfilled
  -- immediately.
  self.sellQueue = {}
  self.purchaseQueue = {}
end

function JournalatorVendorMonitorMixin:RegisterRightClickToSellHandlers()
  local function ProcessDetails(bag, slot)
    if not self.merchantShown then
      return
    end

    local itemCount, itemLink = GetCountLinkFromBagAndSlot(bag, slot)
    if itemLink == nil then
      return
    end

    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then
      return
    end

    local guid = GetGUIDFromBagAndSlot(bag, slot)
    item:ContinueOnItemLoad(function()
      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.sellQueue[guid] = {
        vendorType = "sell",
        itemName = (GetItemInfo(itemLink)),
        count = itemCount,
        unitPrice = vendorPrice,
        itemLink = itemLink,
        time = time(),
        source = Journalator.State.Source,
      }
    end)
  end
  --Detect when an attempt to sell an item is done by right-clicking an item in
  --a bag. This handler also works for addon automated sales.
  if C_Container then -- Dragonflight
    hooksecurefunc(C_Container, "UseContainerItem", ProcessDetails)
  else
    hooksecurefunc(_G, "UseContainerItem", ProcessDetails)
  end
end

-- Used to identify the item selected/being dragged by the cursor
-- The selected item may be sold, destroyed, repositioned in the bag, or left
-- as-is.
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

    -- If the item is currently selected by the cursor it will be locked in the
    -- bag, so it isn't currently waiting for a sale of it to process.
    self.sellQueue[guid] = nil

    local item = Item:CreateFromItemLocation(itemLocation)
    item:ContinueOnItemLoad(function()
      -- If this item has been queued to be sold, it should no longer be on the
      -- cursor and in the queue, we just reset the queue so it works to check
      -- it.
      if self.sellQueue[guid] ~= nil then
        return
      end

      local vendorPrice = select(Auctionator.Constants.ITEM_INFO.SELL_PRICE, GetItemInfo(itemLink))
      self.lastCursorItem = {
        guid = guid,
        item = {
          vendorType = "sell",
          itemName = (GetItemInfo(itemLink)),
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
  -- Handle case when the cursor is used to select and sell an item
  hooksecurefunc(_G, "PickupMerchantItem", function(index)
    if not self.merchantShown then
      return
    end

    if self.lastCursorItem ~= nil and C_Cursor.GetCursorItem() == nil then
      self.sellQueue[self.lastCursorItem.guid] = self.lastCursorItem.item
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
  if C_Container then
    hooksecurefunc(C_Container, "PickupContainerItem", function()
      self:UpdateCursorItem()
    end)
  else
    hooksecurefunc(_G, "PickupContainerItem", function()
      self:UpdateCursorItem()
    end)
  end
end

-- Used to log refund amounts for heirlooms (and probably a few other refundable
-- items)
function JournalatorVendorMonitorMixin:RegisterRefundHandlers()
  local function ProcessDetails(bag, slot, isEquipped)
    if not self.merchantShown then
      return
    end

    local money, refundSec = GetRefundInfo(bag, slot, isEquipped)

    local itemCount, itemLink = GetCountLinkFromBagAndSlot(bag, slot)

    if itemLink == nil or refundSec == nil then
      return
    end

    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then
      return
    end

    local guid = GetGUIDFromBagAndSlot(bag, slot)
    item:ContinueOnItemLoad(function()
      self.sellQueue[guid] = {
        vendorType = "sell",
        itemName = (GetItemInfo(itemLink)),
        count = itemCount,
        unitPrice = money,
        itemLink = itemLink,
        time = time(),
        source = Journalator.State.Source,
      }
      DevTools_Dump(self.sellQueue[guid])
    end)
  end
  if C_Container then --Dragonflight
    hooksecurefunc(C_Container, "ContainerRefundItemPurchase", ProcessDetails)
  else
    hooksecurefunc(_G, "ContainerRefundItemPurchase", ProcessDetails)
  end
end

function JournalatorVendorMonitorMixin:UpdateForCompletedSales()
  -- Checks if an item sold to a vendor has disappeared from the player's bag or
  -- equipped items.
  for guid, item in pairs(self.sellQueue) do
    if not IsGUIDInPossession(guid) then
      Journalator.AddToLogs({ Vendoring = {item} })
      self.sellQueue[guid] = nil
    end
  end
end

-- Handle items being repurchased from the vendor aftering having been sold
-- earlier.
function JournalatorVendorMonitorMixin:RegisterBuybackHandlers()
  hooksecurefunc(_G, "BuybackItem", function(index)
    if not self.merchantShown then
      return
    end

    local name, _, price, quantity = GetBuybackItemInfo(index)
    local link = GetBuybackItemLink(index)

    if link == nil then
      return
    end

    -- There is no duplicate check for the same item being clicked multiple
    -- times, as even if there are duplicates, the code checking for a
    -- successful buyback uses guids for the items in the bag to detect newly
    -- purchased ones - avoiding the duplicates.
    table.insert(self.purchaseQueue, {
      vendorType = "buyback",
      itemName = name,
      count = quantity,
      unitPrice = price / quantity,
      itemLink = link,
      time = time(),
      source = Journalator.State.Source,
    })
    self:SortPurchaseQueue()
  end)
end

-- Handle normal purchase of items. This even works when the cursor is used to
-- drag and item from the vendor into a bag.
function JournalatorVendorMonitorMixin:RegisterPurchaseHandlers()
  hooksecurefunc(_G, "BuyMerchantItem", function(index, quantity)
    if not self.merchantShown then
      return
    end

    quantity = quantity or 1

    local name, _, price, stackSize, numInStock = GetMerchantItemInfo(index)
    local link = GetMerchantItemLink(index)
    local maxStackSize = GetMerchantItemMaxStack(index)
    local extraCurrenciesNeeded = GetMerchantItemCostInfo(index)

    if
      -- Has an item link (some timewalking items don't)
      link ~= nil
      -- Has a copper/silver/gold price
      and price ~= 0
      -- Ignore special currencies (simplifies further calculations)
      and extraCurrenciesNeeded == 0
      -- In stock, and not buying more than on sale
      and (numInStock == -1 or numInStock >= quantity)
      -- Buying more than a maxed out stack fails with "Internal Bag Error"
      and maxStackSize >= quantity
    then
      table.insert(self.purchaseQueue, {
        vendorType = "purchase",
        itemName = name,
        count = quantity,
        unitPrice = price / stackSize,
        itemLink = link,
        time = time(),
        source = Journalator.State.Source,
      })
      self:SortPurchaseQueue()
    end
  end)
end

function JournalatorVendorMonitorMixin:SortPurchaseQueue()
  -- Sort in descending order by stack size, grouped by item. Used to determine
  -- which purchases have gone through, and affects the order in which items are
  -- added to the vendor logs, by slotting each stack into the new stacks added,
  -- largest to smallest.
  table.sort(self.purchaseQueue, function(a, b)
    if a.itemLink == b.itemLink then
      return b.count < a.count
    else
      return a.itemLink < b.itemLink
    end
  end)
end

function JournalatorVendorMonitorMixin:UpdateForCompletedPurchases()
  local newStackSizes = GetGUIDStackSizes()
  local newQueue = {}
  for _, item in ipairs(self.purchaseQueue) do

    local foundMatch = false

    -- Identify stack with new items in it corresponding to the purchase.
    for guid, details in pairs(newStackSizes) do
      if details.itemLink == item.itemLink then
        if self.oldStackSizes[guid] == nil then
          foundMatch = true
          self.oldStackSizes[guid] = {itemLink = item.itemLink, count = item.count}
          break
        elseif newStackSizes[guid].count - self.oldStackSizes[guid].count >= item.count then
          foundMatch = true
          -- We've accounted for the items, so update the old stack size count
          -- so that we can identify other stacks for other purchases.
          self.oldStackSizes[guid].count = self.oldStackSizes[guid].count + item.count
          break
        end
      end
    end

    if foundMatch then
      Journalator.AddToLogs({ Vendoring = {item} })
    else
      -- Didn't find an appropriate stack of the item in the bag, so leave the
      -- purchase queued.
      table.insert(newQueue, item)
    end
  end

  self.oldStackSizes = newStackSizes
  self.purchaseQueue = newQueue
end

-- Used to remove items from the purchase queue when there is no space for them
-- in a bag
-- Calculating in advance whether a given item will fit when multiple items
-- can be purchased at once is awkward, so we check afterwards to see if ANY of
-- the items can fit independently. So when one item does get added to the bag
-- the remaining items will either fit (and get purchased), or not, and get
-- removed from the queue..
function JournalatorVendorMonitorMixin:CheckPurchaseQueueForBagSpace()
  local newQueue = {}
  for index, item in ipairs(self.purchaseQueue) do
    if GetItemInfo(item.itemLink) == nil or
        IsLargeEnoughSlotAvailable(item.itemLink, item.count) then
      table.insert(newQueue, item)
    end
  end

  self.purchaseQueue = newQueue
end

function JournalatorVendorMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MERCHANT_SHOW" then
    self:SetScript("OnUpdate", self.OnUpdate)
    FrameUtil.RegisterFrameForEvents(self, PURCHASE_VALIDATION_EVENTS)

    self:ResetQueues()
    self.oldStackSizes = GetGUIDStackSizes()
    self.merchantShown = true

  elseif eventName == "MERCHANT_CLOSED" then
    self:SetScript("OnUpdate", nil)
    FrameUtil.UnregisterFrameForEvents(self, PURCHASE_VALIDATION_EVENTS)

    self:ResetQueues()
    self.merchantShown = false

  elseif eventName == "MERCHANT_UPDATE" then
    self:UpdateForCompletedSales()

  elseif eventName == "BAG_UPDATE" then
    self:UpdateForCompletedSales()
    self:UpdateForCompletedPurchases()
  end
end
