local POSTING_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_TOTAL,
    headerParameters = { "total" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "total" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_DEPOSIT,
    headerParameters = { "deposit" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "deposit" }
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
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" }
  },
}

JournalatorPostingDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorPostingDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  for _, item in ipairs(JOURNALATOR_LOGS.Posting) do
    local processedItem = {
      itemName = item.itemName,
      itemNamePretty = item.itemName,
      total = item.buyout * item.count,
      count = item.count,
      unitPrice = item.buyout,
      rawDay = item.time,
      deposit = item.deposit,
      date = SecondsToTime(time() - item.time),
      itemLink = item.itemLink or Journalator.GetItemInfo(item.itemName, item.deposit, item.count),
    }

    if processedItem.itemLink ~= nil then
      processedItem.itemNamePretty = Journalator.ApplyQualityColor(item.itemName, processedItem.itemLink)
    end
    table.insert(results, processedItem)
  end
  self:AppendEntries(results, true)
end

function JournalatorPostingDataProviderMixin:GetTableLayout()
  return POSTING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  total = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorPostingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end
