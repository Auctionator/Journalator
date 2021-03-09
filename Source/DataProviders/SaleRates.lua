local SALE_RATES_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
    width = 300,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_SALE_RATE,
    headerParameters = { "saleRate" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "saleRatePretty" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_MEAN_PRICE,
    headerParameters = { "meanPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "meanPrice" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_AMOUNT_SOLD,
    headerParameters = { "sold" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "sold" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_AMOUNT_UNSOLD,
    headerParameters = { "unsold" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "unsold" },
  },
}

JournalatorSaleRatesDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorSaleRatesDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200
end

function JournalatorSaleRatesDataProviderMixin:OnShow()
  self:Refresh()
end

function JournalatorSaleRatesDataProviderMixin:Refresh()
  self:Reset()

  local postedCounts = {}
  for _, item in ipairs(JOURNALATOR_LOGS.Posting) do
    if postedCounts[item.itemName] == nil then
      postedCounts[item.itemName] = {
        sold = 0,
        totalSaleValue = 0,
        posted = 0,
      }
    end
    postedCounts[item.itemName].posted = postedCounts[item.itemName].posted + item.count
  end

  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    if item.invoiceType == "seller" then
      if postedCounts[item.itemName] == nil then
        postedCounts[item.itemName] = {
          sold = 0,
          totalSaleValue = 0,
          posted = 0,
        }
      end
      postedCounts[item.itemName].sold = postedCounts[item.itemName].sold + item.count
      postedCounts[item.itemName].totalSaleValue = postedCounts[item.itemName].totalSaleValue + item.value
    end
  end

  local results = {}
  for key, entry in pairs(postedCounts) do

    local saleRate, saleRatePretty, meanPrice
    if entry.posted == 0 then
      saleRate = 100
      saleRatePretty = "100%"
    else
      saleRate = 100 * entry.sold / entry.posted
      saleRatePretty = tostring(math.floor(saleRate)) .. "%"
    end

    if entry.sold == 0 then
      meanPrice = nil
    else
      meanPrice = math.floor(entry.totalSaleValue / entry.sold)
    end

    table.insert(results, {
      itemName = key,
      saleRate = saleRate,
      saleRatePretty = saleRatePretty,
      meanPrice = meanPrice,
      sold = entry.sold,
      unsold = math.max(0, entry.posted - entry.sold),
    })
  end

  table.sort(results, function(left, right)
    return left.saleRate < right.saleRate
  end)
  self:AppendEntries(results, true)
end

function JournalatorSaleRatesDataProviderMixin:GetTableLayout()
  return SALE_RATES_DATA_PROVIDER_LAYOUT
end

function JournalatorSaleRatesDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  saleRate = Auctionator.Utilities.NumberComparator,
  meanPrice = Auctionator.Utilities.NumberComparator,
  sold = Auctionator.Utilities.NumberComparator,
  unsold = Auctionator.Utilities.NumberComparator,
}

function JournalatorSaleRatesDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function JournalatorSaleRatesDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end
