local VENDOR_REPAIRS_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_CHARACTER,
    headerParameters = { "sourceCharacter" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "sourceCharacter" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorVendorRepairsDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorVendorRepairsDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "VendorRepairs")) do
    local filterItem = {
      itemName = "",
      source = item.source,
      time = item.time,
    }
    if self:Filter(filterItem) then
      table.insert(results, {
        moneyOut = item.money,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        rawDay = item.time,
        value = -item.money,
        selected = self:IsSelected(index),
        index = index,
      })
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorVendorRepairsDataProviderMixin:GetTableLayout()
  return VENDOR_REPAIRS_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  moneyOut = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorVendorRepairsDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_VENDOR_REPAIRS", "columns_vendor_repairs", {})

function JournalatorVendorRepairsDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_VENDOR_REPAIRS)
end
