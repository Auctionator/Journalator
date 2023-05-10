-- Tracks loot from items which you right-click to loot and collect all the
-- items instantly, unlike the normal loot containers where some kind of
-- interaction or additional API call is needed to finish looting the items.
JournalatorLootRightClickToOpenMonitorMixin = {}

function JournalatorLootRightClickToOpenMonitorMixin:OnLoad()
  if not C_TooltipInfo then
    return
  end

  self.currentContainer = nil

  FrameUtil.RegisterFrameForEvents(self, {
    "ITEM_LOCKED",
    "ITEM_UNLOCKED",
    "SHOW_LOOT_TOAST",
    "LOOT_CLOSED",
  })
end

local function IsRightClickToOpen(bag, slot)
  if bag == nil or slot == nil then
    return false
  end

  local containerItemInfo = C_Container.GetContainerItemInfo(bag, slot)
  return containerItemInfo ~= nil and containerItemInfo.hasLoot
end

function JournalatorLootRightClickToOpenMonitorMixin:OnEvent(eventName, ...)
  if eventName == "ITEM_LOCKED" then
    self:Start(...)

  elseif eventName == "ITEM_UNLOCKED" then
    self:RemoveContainer()

  elseif eventName == "SHOW_LOOT_TOAST" then
    self:ProcessToast(...)

  elseif eventName == "LOOT_CLOSED" then
    self:Finish()
  end
end

function JournalatorLootRightClickToOpenMonitorMixin:Start(bag, slot)
  -- Expensive check for right-click-open status, only run this when necessary
  if not IsRightClickToOpen(bag, slot) then
    return
  end

  local itemLink = C_Container.GetContainerItemInfo(bag, slot).hyperlink

  Journalator.Debug.Message("loot right-click-to-open matched", bag, slot, itemLink)

  self.currentContainer = {
    bag = bag,
    slot = slot,
    itemLink = itemLink,
    items = {},
    currencies = {},
    money = 0,
  }
end

function JournalatorLootRightClickToOpenMonitorMixin:ProcessToast(...)
  if self.currentContainer == nil then
    return
  end

  local typeIdentifier, itemLink, quantity, specID, sex, isPersonal, lootSource, lessAwesome, isUpgraded, isCorrupted = ...
  Journalator.Debug.Message("loot right-click-to-open toast source", lootSource)

  -- Testing indicates that 3 is the correct value for item containers
  if lootSource ~= 3 then
    return
  end

  -- Finally, we know its a container and this loot probably corresponds to it
  if typeIdentifier == "money" then
    Journalator.Debug.Message("loot right-click-to-open money", itemLink, GetMoneyString(quantity, true))
    self.currentContainer.money = self.currentContainer.money + quantity
  elseif typeIdentifier == "item" then
    Journalator.Debug.Message("loot right-click-to-open item", itemLink, quantity)
    table.insert(self.currentContainer.items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  elseif typeIdentifier == "currency" then
    local currencyID = tonumber(itemLink:match("|H%w+:(%d+)"))
    Journalator.Debug.Message("loot right-click-to-open currency", currencyID, quantity)
    table.insert(self.currentContainer.currencies, {
      currencyID = currencyID,
      quantity = quantity,
    })
  else
    Journalator.Debug.Message("loot right-click-to-open unknown", typeIdentifier, itemLink, quantity)
  end
end

function JournalatorLootRightClickToOpenMonitorMixin:Finish()
  if self.currentContainer == nil then
    return
  end

  -- Check that something has come out of the container
  if self.currentContainer.money > 0 or #self.currentContainer.items > 0 or #self.currentContainer.currencies > 0 then
    Journalator.Debug.Message("loot right-click-to-open container with stuff")

    local result = {
      type = "item",
      name = "",
      map = C_Map.GetBestMapForUnit("player"),
      itemLink = self.currentContainer.itemLink,
      money = self.currentContainer.money,
      items = self.currentContainer.items,
      currencies = self.currentContainer.currencies,
      source = Journalator.State.Source
    }

    -- Get the container's item name
    local item = Item:CreateFromItemLink(result.itemLink)
    item:ContinueOnItemLoad(function()
      result.name = item:GetItemName()
      result.time = time()
      Journalator.Debug.Message("loot right-click-to-open complete + name", result.name)
      Journalator.AddToLogs({ LootContainers = { result } })
    end)
  else
    Journalator.Debug.Message("loot right-click-to-open nothing queued")
  end
  self:RemoveContainer()
end

function JournalatorLootRightClickToOpenMonitorMixin:RemoveContainer()
  self.currentContainer = nil
end
