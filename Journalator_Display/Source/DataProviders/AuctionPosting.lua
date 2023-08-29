local POSTING_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_TOTAL,
    headerParameters = { "total" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "total" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_DEPOSIT,
    headerParameters = { "deposit" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "deposit" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_UNIT_PRICE,
    headerParameters = { "unitPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "unitPrice" },
    width = 150,
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorAuctionPostingDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorAuctionPostingDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Posting")) do
    if self:Filter(item) then
      local processedItem = {
        searchTerm = item.itemName,
        itemName = item.itemName,
        itemNamePretty = item.itemName,
        total = (item.buyout or item.bid) * item.count,
        count = item.count,
        unitPrice = (item.buyout or item.bid),
        rawDay = item.time,
        deposit = item.deposit,
        itemLink = item.itemLink,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        index = index,
        value = -item.deposit,
        selected = self:IsSelected(index),
      }

      if processedItem.itemLink ~= nil then
        processedItem.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(processedItem.itemNamePretty, processedItem.itemLink)
        processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
        processedItem.itemName = Journalator.Utilities.AddTierToBasicName(processedItem.itemName, processedItem.itemLink)
      end
      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorAuctionPostingDataProviderMixin:GetTableLayout()
  return POSTING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  total = Auctionator.Utilities.NumberComparator,
  deposit = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorAuctionPostingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_POSTING", "columns_posting", {})

function JournalatorAuctionPostingDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_POSTING)
end
