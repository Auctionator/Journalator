local SALE_RATES_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
    width = 350,
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
    cellParameters = { "meanPrice" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TOTAL,
    headerParameters = { "totalPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "totalPrice" },
    width = 150,
    defaultHide = true,
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

JournalatorSaleRatesDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorSaleRatesDataProviderMixin:Refresh()
  self:Reset()

  local salesCounts = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Failures")) do
    if self:Filter(item) then
      if salesCounts[item.itemName] == nil then
        salesCounts[item.itemName] = {
          sold = 0,
          totalSaleValue = 0,
          failed = 0,
        }
      end
      salesCounts[item.itemName].failed = salesCounts[item.itemName].failed + item.count
    end
  end

  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Invoices")) do
    if self:Filter(item) then
      if item.invoiceType == "seller" then
        if salesCounts[item.itemName] == nil then
          salesCounts[item.itemName] = {
            sold = 0,
            totalSaleValue = 0,
            failed = 0,
          }
        end
        salesCounts[item.itemName].sold = salesCounts[item.itemName].sold + item.count
        salesCounts[item.itemName].totalSaleValue = salesCounts[item.itemName].totalSaleValue + item.value
      end
    end
  end

  local results = {}
  for key, entry in pairs(salesCounts) do

    local saleRate, saleRatePretty, meanPrice
    if entry.failed == 0 then
      saleRate = 100
    else
      saleRate = entry.sold/(entry.sold + entry.failed) * 100
    end
    saleRatePretty = Journalator.Utilities.PrettyPercentage(saleRate)

    if entry.sold == 0 then
      meanPrice = 0
    else
      meanPrice = math.floor(entry.totalSaleValue / entry.sold)
    end

    totalPrice = entry.totalSaleValue

    table.insert(results, {
      itemName = key,
      saleRate = saleRate,
      saleRatePretty = saleRatePretty,
      meanPrice = meanPrice,
      totalPrice = totalPrice,
      sold = entry.sold,
      unsold = entry.failed,
    })
  end

  table.sort(results, function(left, right)
    return left.saleRate > right.saleRate
  end)
  self:AppendEntries(results, true)
end

function JournalatorSaleRatesDataProviderMixin:GetTableLayout()
  return SALE_RATES_DATA_PROVIDER_LAYOUT
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

Journalator.Config.Create("COLUMNS_SALE_RATES", "columns_sale_rates", {})

function JournalatorSaleRatesDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_SALE_RATES)
end
