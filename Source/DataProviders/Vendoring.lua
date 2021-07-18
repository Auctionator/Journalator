local VENDORING_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemNamePretty" },
    width = 300,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_UNIT_PRICE,
    headerParameters = { "unitPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "unitPrice" }
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
    headerText = AUCTIONATOR_L_QUANTITY,
    headerParameters = { "count" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "count" },
    width = 100
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_DATE,
    headerParameters = { "rawDay" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" }
  },
}

JournalatorVendoringDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorVendoringDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Vendoring")) do
    if self:Filter(item) then
      local moneyIn = 0
      local moneyOut = 0
      local itemNamePretty = item.itemName

      if item.vendorType == "sell" then
        moneyIn = item.unitPrice * item.count
      else
        moneyOut = -item.unitPrice * item.count
      end

      if item.itemLink then
        itemNamePretty = Journalator.ApplyQualityColor(item.itemName, item.itemLink)
      end

      table.insert(results, {
        itemName = item.itemName,
        itemNamePretty = itemNamePretty,
        moneyIn = moneyIn,
        moneyOut = moneyOut,
        total = item.unitPrice * item.count,
        count = item.count,
        unitPrice = item.unitPrice,
        rawDay = item.time,
        date = SecondsToTime(time() - item.time),
        itemLink = item.itemLink,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
      })
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorVendoringDataProviderMixin:GetTableLayout()
  return VENDORING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  total = Auctionator.Utilities.NumberComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorVendoringDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Auctionator.Config.Create("JOURNALATOR_COLUMNS_VENDORING", "journalator_columns_vendoring", {})

function JournalatorVendoringDataProviderMixin:GetColumnHideStates()
  return Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_COLUMNS_VENDORING)
end
