local QUESTS_BY_ITEM_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_CHARACTER,
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
    headerText = AUCTIONATOR_L_QUANTITY,
    headerParameters = { "count" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "count" },
    width = 100
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorQuestsByItemDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorQuestsByItemDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  local quantity = 0
  for index, entry in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Questing")) do
    -- Need to filter out rewards with no item link data, generated due to
    -- unexpected API results in SoD for Messenger to Darkshire (quest id 145)
    local rewardItems = tFilter(entry.rewardItems, function(i) return i.itemLink ~= nil end, true)
    if #rewardItems > 0 then
      local zone = ""
      if entry.map then
        local mapInfo = C_Map.GetMapInfo(entry.map)
        if mapInfo then
          zone = mapInfo.name
        end
      end
      local sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(entry.source.character, entry.source)

      local sortedItems = CopyTable(entry.rewardItems)
      for _, i in ipairs(sortedItems) do
        i.itemName = Auctionator.Utilities.GetNameFromLink(i.itemLink):gsub(" |A.*|a", "")
        i.source = entry.source
        i.time = entry.time
      end
      table.sort(sortedItems, function(a, b) return a.itemName > b.itemName end)

      for _, i in ipairs(sortedItems) do
        if self:Filter(i) then
          local processedItem = {
            searchTerm = i.itemName,
            itemName = i.itemName,
            itemNamePretty = i.itemName,
            count = i.quantity,
            rawDay = entry.time,
            itemLink = i.itemLink,
            zone = zone,
            sourceCharacter = sourceCharacter,
            index = index,
            value = 0,
            selected = self:IsSelected(index),
          }
          quantity = quantity + i.quantity

          if processedItem.itemLink ~= nil then
            processedItem.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(processedItem.itemNamePretty, processedItem.itemLink)
            processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
            processedItem.itemName = Journalator.Utilities.AddTierToBasicName(processedItem.itemName, processedItem.itemLink)
          end
          table.insert(results, processedItem)
        end
      end
    end
  end
  Auctionator.EventBus:RegisterSource(self, "JournalatorQuestsByItemDataProviderMixin")
    :Fire(self, Journalator.Events.UpdateTotalQuantity, quantity)
    :UnregisterSource(self)
  self:AppendEntries(results, true)
end

function JournalatorQuestsByItemDataProviderMixin:GetTableLayout()
  return QUESTS_BY_ITEM_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  count = Auctionator.Utilities.NumberComparator,
  zone = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorQuestsByItemDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_QUESTS_BY_ITEM", "columns_quests_by_item", {})

function JournalatorQuestsByItemDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_QUESTS_BY_ITEM)
end
