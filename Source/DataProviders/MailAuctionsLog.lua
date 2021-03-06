local MAIL_AUCTIONS_LOG_PROVIDER_LAYOUT ={
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
    headerText = "In",
    headerParameters = { "moneyIn" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyIn" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Out",
    headerParameters = { "moneyOut" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyOut" }
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

JournalatorMailAuctionsLogProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorMailAuctionsLogProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
end

function JournalatorMailAuctionsLogProviderMixin:OnShow()
  self:Reset()
  local results = {}
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    local moneyIn, moneyOut
    if item.invoiceType == "seller" then
      moneyIn = item.value
    else
      moneyOut = item.value
    end
    table.insert(results, {
      itemName = item.itemName,
      moneyIn = moneyIn,
      moneyOut = moneyOut,
      count = item.count,
      unitPrice = item.value/item.count,
      rawDay = item.time,
      date = Auctionator.Utilities.PrettyDate(item.time),
    })
  end
  self:AppendEntries(results, true)
end

function JournalatorMailAuctionsLogProviderMixin:GetTableLayout()
  return MAIL_AUCTIONS_LOG_PROVIDER_LAYOUT
end

function JournalatorMailAuctionsLogProviderMixin:UniqueKey(entry)
  return tostring(tostring(entry.price) .. tostring(entry.rawDay))
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  invoiceType = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorMailAuctionsLogProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function JournalatorMailAuctionsLogProviderMixin:GetRowTemplate()
  return "AuctionatorResultsRowTemplate"
end
