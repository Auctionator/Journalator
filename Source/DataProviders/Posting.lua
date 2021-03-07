local POSTING_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Name",
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
    width = 300,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Total",
    headerParameters = { "total" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "total" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Deposit",
    headerParameters = { "deposit" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "deposit" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Unit Price",
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
    headerText = AUCTIONATOR_L_DATE,
    headerParameters = { "rawDay" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" }
  },
}

JournalatorPostingDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorPostingDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
end

function JournalatorPostingDataProviderMixin:OnShow()
  self:Reset()
  local results = {}
  for _, item in ipairs(JOURNALATOR_LOGS.Posting) do
    table.insert(results, {
      itemName = item.itemName,
      total = item.buyout * item.count,
      count = item.count,
      unitPrice = item.buyout,
      rawDay = item.time,
      deposit = item.deposit,
      date = SecondsToTime(time() - item.time),
    })
  end
  self:AppendEntries(results, true)
end

function JournalatorPostingDataProviderMixin:GetTableLayout()
  return POSTING_DATA_PROVIDER_LAYOUT
end

function JournalatorPostingDataProviderMixin:UniqueKey(entry)
  return tostring(tostring(entry.price) .. tostring(entry.rawDay))
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

function JournalatorPostingDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end
