local LOOTING_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemNamePretty" },
    width = 350,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_MONEY,
    headerParameters = { "money" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "money" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_ITEMS,
    headerParameters = { "itemCount" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemCount" },
    width = 100
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_CURRENCIES,
    headerParameters = { "currencyCount" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "currencyCount" },
    width = 100
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_SOURCE,
    headerParameters = { "sourceCharacter" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "sourceCharacter" },
    defaultHide = true,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_ZONE,
    headerParameters = { "zone" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "zone" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorLootingDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorLootingDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  local count = 1
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "LootContainers")) do
    local name
    if item.type == "item" then
      name = item.name
    elseif item.type == "npc" then
      name = item.name
    else
      name = (item.name ~= "" and item.name) or JOURNALATOR_L_WORLD_OBJECT
    end
    local filterItem = {
      itemName = name,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local link
      if item.type == "item" then
        link = item.itemLink
      elseif item.type == "npc" then
        link = ("unit:Creature-0-0-0-0-%d"):format(item.npcID)
      end
      local processedItem = {
        itemName = name,
        itemNamePretty = name,
        itemLink = link,
        money = item.money,
        rawDay = item.time,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        items = item.items,
        currencies = item.currencies,
        itemCount = #item.items,
        currencyCount = #item.currencies,
      }

      local mapInfo = C_Map.GetMapInfo(item.map)
      if mapInfo then
        processedItem.zone = mapInfo.name
      else
        processedItem.zone = ""
      end

      if item.type == "item" and processedItem.itemLink then
        processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
      elseif item.type == "npc" then
        processedItem.itemNamePretty = LIGHTYELLOW_FONT_COLOR:WrapTextInColorCode(processedItem.itemNamePretty)
      elseif item.type == "world" then
        processedItem.itemNamePretty = BLUE_FONT_COLOR:WrapTextInColorCode(processedItem.itemNamePretty)
      end

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorLootingDataProviderMixin:GetTableLayout()
  return LOOTING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  money = Auctionator.Utilities.NumberComparator,
  itemCount = Auctionator.Utilities.NumberComparator,
  currencyCount = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorLootingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_LOOTING", "columns_questing", {})

function JournalatorLootingDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_LOOTING)
end

function JournalatorLootingDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewLootingRowTemplate"
end
