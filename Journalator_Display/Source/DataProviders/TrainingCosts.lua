local TRAINING_COSTS_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TRAINER,
    headerParameters = { "trainerType" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "trainerType" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_GROUP,
    headerParameters = { "group" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "group" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_ITEM,
    headerParameters = { "item" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "item" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_REQUIREMENTS,
    headerParameters = { "requirements" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "requirements" },
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" },
    width = 150,
  },
}

JournalatorTrainingCostsDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorTrainingCostsDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "TrainingCosts")) do
    local filterItem = {
      itemName = item.item,
      source = item.source,
      time = item.time,
    }
    if self:Filter(filterItem) then
      table.insert(results, {
        searchTerm = item.item,
        moneyOut = item.money,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        trainerType = item.trainer.group,
        group = item.group,
        item = item.item,
        requirements = item.requirements,
        itemLink = item.itemLink,
        rawDay = item.time,
        value = -item.money,
        selected = self:IsSelected(index),
        index = index,
      })
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorTrainingCostsDataProviderMixin:GetTableLayout()
  return TRAINING_COSTS_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  moneyOut = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  trainerType = Auctionator.Utilities.StringComparator,
  group = Auctionator.Utilities.StringComparator,
  item = Auctionator.Utilities.StringComparator,
  requirements = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorTrainingCostsDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_TRAINING_COSTS", "columns_training_costs", {})

function JournalatorTrainingCostsDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_TRAINING_COSTS)
end
