local QUESTING_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorQuestingDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorQuestingDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Questing")) do
    local filterItem = {
      itemName = item.questName,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local processedItem = {
        itemName = item.questName,
        money = item.rewardMoney,
        rawDay = item.time,
        itemLink = "quest:" .. item.questID,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        items = item.rewardItems,
        currencies = item.rewardCurrencies,
        itemCount = #item.rewardItems,
        currencyCount = #item.rewardCurrencies,
        experience = item.experience,
        experiencePretty = FormatLargeNumber(item.experience),
      }

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorQuestingDataProviderMixin:GetTableLayout()
  return QUESTING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  money = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorQuestingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_QUESTING", "columns_questing", {})

function JournalatorQuestingDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_QUESTING)
end

function JournalatorQuestingDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewQuestingRowTemplate"
end
