local TAXIS_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_START,
    headerParameters = { "origin" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "origin" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_END,
    headerParameters = { "target" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "target" },
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" },
    width = 150,
  },
}

JournalatorTaxisDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorTaxisDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Taxis")) do
    local filterItem = {
      itemName = item.zone,
      source = item.source,
      time = item.time,
    }
    if self:Filter(filterItem) then
      table.insert(results, {
        searchTerm = item.zone,
        moneyOut = item.money,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        realmID = item.source.realmID,
        zone = item.zone,
        target = item.target,
        origin = item.origin,
        rawDay = item.time,
        value = -item.money,
        selected = self:IsSelected(index),
        index = index,
      })
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorTaxisDataProviderMixin:GetTableLayout()
  return TAXIS_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  moneyOut = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  origin = Auctionator.Utilities.StringComparator,
  target = Auctionator.Utilities.StringComparator,
  zone = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorTaxisDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_TAXIS", "columns_taxis", {})

function JournalatorTaxisDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_TAXIS)
end
