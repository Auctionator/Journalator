local QUESTS_BY_QUEST_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
    width = 350,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_MONEY,
    headerParameters = { "rewardMoney" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "rewardMoney" },
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
    headerText = JOURNALATOR_L_EXPERIENCE,
    headerParameters = { "experience" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "experiencePretty" },
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

JournalatorQuestsByQuestDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorQuestsByQuestDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Questing")) do
    local filterItem = {
      itemName = item.questName,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local link
      if not Auctionator.Constants.IsClassic then
        link = "quest:" .. item.questID
      end
      local processedItem = {
        itemName = item.questName,
        rewardMoney = item.rewardMoney,
        requiredMoney = item.requiredMoney,
        rawDay = item.time,
        itemLink = link,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        items = item.rewardItems,
        currencies = item.rewardCurrencies,
        itemCount = #item.rewardItems,
        currencyCount = #item.rewardCurrencies,
        reputationChanges = item.reputationChanges,
        experience = item.experience,
        experiencePretty = FormatLargeNumber(item.experience),
        index = index,
        value = (item.rewardMoney or 0) - (item.requiredMoney or 0),
        selected = self:IsSelected(index),
      }

      local mapInfo = item.map and C_Map.GetMapInfo(item.map)
      if mapInfo then
        processedItem.zone = mapInfo.name
      else
        processedItem.zone = ""
      end

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorQuestsByQuestDataProviderMixin:GetTableLayout()
  return QUESTS_BY_QUEST_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  rewardMoney = Auctionator.Utilities.NumberComparator,
  itemCount = Auctionator.Utilities.NumberComparator,
  currencyCount = Auctionator.Utilities.NumberComparator,
  experience = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorQuestsByQuestDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_QUESTS_BY_QUEST", "columns_questing", {})

function JournalatorQuestsByQuestDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_QUESTS_BY_QUEST)
end

function JournalatorQuestsByQuestDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewQuestingRowTemplate"
end
