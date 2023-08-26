local TRADES_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_PLAYER,
    headerParameters = { "otherPlayer" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "otherPlayer" },
    width = 350,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_ITEMS_IN,
    headerParameters = { "itemsInCount" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemsInCount" },
    width = 100
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_ITEMS_OUT,
    headerParameters = { "itemsOutCount" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemsOutCount" },
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorTradesDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorTradesDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()

  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Trades")) do
    local filterItem = {
      itemName = item.player,
      time = item.time,
      source = item.source,
      playerCheck = item.player,
    }
    if self:Filter(filterItem) then
      local processedItem = {
        searchTerm = item.player,
        otherPlayer = item.player,
        rawDay = item.time,
        itemsInCount = #item.itemsIn,
        itemsOutCount = #item.itemsOut,
        itemsIn = item.itemsIn,
        itemsOut = item.itemsOut,
        moneyIn = item.moneyIn,
        moneyOut = -item.moneyOut,
        value = item.moneyIn - item.moneyOut,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        index = index,
        selected = self:IsSelected(index),
      }

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorTradesDataProviderMixin:GetTableLayout()
  return TRADES_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  reason = Auctionator.Utilities.StringComparator,
  itemName = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorTradesDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_TRADES", "columns_trades", {})

function JournalatorTradesDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_TRADES)
end

function JournalatorTradesDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewTradesRowTemplate"
end
