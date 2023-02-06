JournalatorLootContainersMonitorMixin = {}

function JournalatorLootContainersMonitorMixin:OnLoad()
  self.isLootReady = false
  self.currentContainer = nil
  self.waiting = {}
  self.slotsLooted = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "LOOT_READY",
    "LOOT_SLOT_CLEARED",
    "LOOT_CLOSED",
  })
end

function JournalatorLootContainersMonitorMixin:OnEvent(eventName, ...)
  if eventName == "LOOT_READY" then
    self:QueueLooted()
    self:CacheLootAvailable()
  elseif eventName == "LOOT_SLOT_CLEARED" then
    local slot = ...
    self:TagLooted(slot)
  else
    self:QueueLooted()
    self:AddToLogs()
    self.waiting = {}
  end
end

local function ConvertSourceInfo(slot)
  local sources = {GetLootSourceInfo(slot)}
  local converted = {}

  for i = 1, #sources, 2 do
    table.insert(converted, {
      guid = sources[i],
      quantity = sources[i + 1],
    })
  end
  return converted
end

local LootSlotType = Enum.LootSlotType

-- Classic Era
if LootSlotType == nil then
  LootSlotType = {
    None = LOOT_SLOT_NONE,
    Item = LOOT_SLOT_ITEM,
    Money = LOOT_SLOT_MONEY,
    Currency = LOOT_SLOT_CURRENCY,
  }
end

function JournalatorLootContainersMonitorMixin:CacheLootAvailable()
  self.currentContainer = {}
  for slot = 1, GetNumLootItems() do
    local texture, itemName, quantity, currencyID, itemQuality, locked, isQuestItem, questID, isActive, isCoin = GetLootSlotInfo(slot)

    local link = GetLootSlotLink(slot)
    local sources = ConvertSourceInfo(slot)
    local slotType = GetLootSlotType(slot)

    local item
    if slotType == LootSlotType.Money then
      item = {
        type = LootSlotType.Money,
        sources = sources,
        looted = false,
        slot = slot,
      }
    elseif slotType == LootSlotType.Currency then
      item = {
        type = LootSlotType.Currency,
        currencyID = currencyID,
        sources = sources,
        looted = false,
        slot = slot,
      }
    elseif slotType == LootSlotType.Item then
      item = {
        type = LootSlotType.Item,
        itemLink = link,
        questID = questID,
        sources = sources,
        looted = false,
        slot = slot,
      }
    end

    if item then
      table.insert(self.currentContainer, item)
    end
  end
  Journalator.Debug.Message("loot container cached", #self.currentContainer)
end

local function AccumulateSources(sources)
  local total = 0
  for _, s in ipairs(sources) do
    total = total + s.quantity
  end
  return total
end

local function DebugPrintItem(prefix, item)
  if item.type == LootSlotType.Item then
    Journalator.Debug.Message(prefix, item.slot, item.type, #item.sources, item.itemLink)
  elseif item.type == LootSlotType.Money then
    Journalator.Debug.Message(prefix, item.slot, item.type, #item.sources, GetMoneyString(AccumulateSources(item.sources), true))
  elseif item.type == LootSlotType.Currency then
    local quantity = AccumulateSources(item.sources)
    Journalator.Debug.Message(prefix, item.slot, item.type, #item.sources, C_CurrencyInfo.GetCurrencyLink(item.currencyID, quantity), quantity)
  else
    Journalator.Debug.Message(prefix, "missing type")
  end
end

function JournalatorLootContainersMonitorMixin:TagLooted(slot)
  assert(self.currentContainer)
  for _, item in ipairs(self.currentContainer) do
    if item.slot == slot and not item.looted then
      DebugPrintItem("loot slot cleared", item)
      item.looted = true
    end
  end
end

function JournalatorLootContainersMonitorMixin:QueueLooted()
  if self.currentContainer == nil then
    return
  end

  for _, item in ipairs(self.currentContainer) do
    if item.looted then
      table.insert(self.waiting, item)
    end
  end

  self.currentContainer = nil
end

local function GroupByGUID(waiting)
  local groups = {}
  for _, item in ipairs(waiting) do
    for _, source in ipairs(item.sources) do
      if not groups[source.guid] then
        groups[source.guid] = {}
      end
      table.insert(groups[source.guid], {
        type = item.type,
        currencyID = item.currencyID,
        questID = item.questID,
        itemLink = item.itemLink,
        quantity = source.quantity,
      })
    end
  end

  return groups
end

function JournalatorLootContainersMonitorMixin:AddToLogs()
  if #self.waiting == 0 then
    return
  end
  Journalator.Debug.Message("loot add to logs", #self.waiting)

  local map = C_Map.GetBestMapForUnit("player")

  local groups = GroupByGUID(self.waiting)
  for guid, items in pairs(groups) do
    local result = {
      name = "",
      map = map,
      money = 0,
      items = {},
      currencies = {},
      source = Journalator.State.Source
    }
    for _, i in ipairs(items) do
      if i.type == LootSlotType.Money then
        result.money = result.money + i.quantity
      elseif i.type == LootSlotType.Currency then
        table.insert(result.currencies, {
          currencyID = i.currencyID,
          quantity = i.quantity,
        })
      elseif i.type == LootSlotType.Item then
        table.insert(result.items, {
          itemLink = i.itemLink,
          quantity = i.quantity,
        })
      end
    end

    Journalator.Debug.Message("loot guid", guid)
    if guid:find("Creature") ~= nil then
      result.type = "npc"
      result.npcID = tonumber(guid:match("^%w+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%w+$"))
      Journalator.GetNPCNameFromGUID(guid, function(name)
        result.name = name
        result.time = time()
        Journalator.AddToLogs({ LootContainers = { result } })
      end)
    elseif guid:find("GameObject") ~= nil then
      result.type = "world"
      result.objectID = tonumber(guid:match("^%w+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%w+$"))
      result.time = time()
      Journalator.AddToLogs({ LootContainers = { result } })
    elseif guid:find("Item") ~= nil then
      result.type = "item"
      local item = Item:CreateFromItemID(C_Item.GetItemIDByGUID(guid))
      item:ContinueOnItemLoad(function()
        result.itemLink = C_Item.GetItemLinkByGUID(guid)
        result.name = (GetItemInfo(result.itemLink))
        result.time = time()

        Journalator.AddToLogs({ LootContainers = { result } })
      end)
    end
  end
end
