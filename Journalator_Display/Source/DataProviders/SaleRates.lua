local SALE_RATES_DATA_PROVIDER_LAYOUT ={
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
  self:GetItemLinks(function(...)
    self:ProcessSales(...)
  end)
end

function JournalatorSaleRatesDataProviderMixin:GetItemLinks(callback)
  -- Conversion of item links to Auctionator DB keys for use later when grouping
  self.seenLinks = self.seenLinks or {}

  local timeForRange = self:GetTimeForRange()

  -- Sometimes an entry may not have an item link corresponding to it. This
  -- causes Journalator to fall back to name matching in that case.
  local isNameMatch = {}

  -- Processed log entries with an item link
  local failureLogEntries = {}
  local successLogEntries = {}

  local waiting = 0
  local finished = false

  local function FinishCheck()
    if waiting == 0 and finished then
      callback(isNameMatch, failureLogEntries, successLogEntries, timeForRange)
    end
  end

  -- Work through all the relevant entries and convert item links into
  -- Auctionator DB keys for grouping where possible
  for _, item in ipairs(Journalator.Archiving.GetRange(timeForRange, "Failures")) do
    if self:Filter(item) then
      table.insert(failureLogEntries, CopyTable(item))

      if item.itemLink == nil then
        isNameMatch[item.itemName] = true
      elseif not self.seenLinks[item.itemLink] then
        waiting = waiting + 1
        Auctionator.Utilities.DBKeyFromLink(item.itemLink, function(dbKeys)
          self.seenLinks[item.itemLink] = dbKeys[1]
          waiting = waiting - 1
          FinishCheck()
        end)
      end
    end
  end

  for _, item in ipairs(Journalator.Archiving.GetRange(timeForRange, "Invoices")) do
    local filterItem = {
      itemName = item.itemName,
      time = item.time,
      source = item.source,
      playerCheck = item.playerName,
    }
    if self:Filter(filterItem) then
      if item.invoiceType == "seller" then
        local itemLink = Journalator.GetPostedItemLink(item.itemName, math.floor(item.value / item.count), math.floor(item.deposit / item.count), item.time, timeForRange)

        local tmpEntry = CopyTable(item)
        tmpEntry.itemLink = itemLink

        table.insert(successLogEntries, tmpEntry)
        if itemLink == nil then
          isNameMatch[item.itemName] = true
        else
          if not self.seenLinks[itemLink] then
            waiting = waiting + 1
            Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeys)
              self.seenLinks[itemLink] = dbKeys[1]
              waiting = waiting - 1

              FinishCheck()
            end)
          end
        end
      end
    end
  end

  finished = true
  FinishCheck()
end

-- Groups processed log entries to get sale rates and displays the results
-- isNameMatch: Items to fall back to grouping by name
function JournalatorSaleRatesDataProviderMixin:ProcessSales(isNameMatch, failureLogEntries, successLogEntries, timeForRange)
  self.onPreserveScroll()
  self:Reset()

  local salesCounts = {}

  for _, item in ipairs(failureLogEntries) do
    local key
    -- Apply fallback grouping if necessary
    if isNameMatch[item.itemName] then
      key = item.itemName
    else
      key = self.seenLinks[item.itemLink]
    end

    if salesCounts[key] == nil then
      salesCounts[key] = {
        itemName = item.itemName,
        itemLink = item.itemLink,

        sold = 0,
        totalSaleValue = 0,
        failed = 0,
      }
    end
    salesCounts[key].failed = salesCounts[key].failed + item.count
  end

  for _, item in ipairs(successLogEntries) do
    local key
    -- Apply fallback grouping if necessary
    if isNameMatch[item.itemName] then
      key = item.itemName
    else
      key = self.seenLinks[item.itemLink]
    end

    if salesCounts[key] == nil then
      salesCounts[key] = {
        itemName = item.itemName,
        itemLink = item.itemLink,

        sold = 0,
        totalSaleValue = 0,
        failed = 0,
      }
    end
    salesCounts[key].sold = salesCounts[key].sold + item.count
    salesCounts[key].totalSaleValue = salesCounts[key].totalSaleValue + item.value
  end

  local results = {}
  for _, entry in pairs(salesCounts) do

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

    local item = {
      searchTerm = entry.itemName,
      itemName = entry.itemName,
      itemNamePretty = entry.itemName,
      itemLink = entry.itemLink or Journalator.GetPostedItemLink(entry.itemName, nil, nil, nil, timeForRange),
      saleRate = saleRate,
      saleRatePretty = saleRatePretty,
      meanPrice = meanPrice,
      totalPrice = entry.totalSaleValue,
      sold = entry.sold,
      unsold = entry.failed,
    }

    if item.itemLink ~= nil then
      item.itemNamePretty = Journalator.ApplyQualityColor(item.itemName, item.itemLink)
      -- Check if we matched prices by item link rather than name. If we did
      -- include the quality icon.
      if entry.itemLink ~= nil then
        item.itemName = Journalator.Utilities.AddTierToBasicName(item.itemName, item.itemLink)
        item.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(item.itemNamePretty, item.itemLink)
      end
    end

    table.insert(results, item)
  end

  table.sort(results, function(left, right)
    if left.saleRate == right.saleRate then
      return left.itemName > right.itemName
    else
      return left.saleRate > right.saleRate
    end
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
  totalPrice = Auctionator.Utilities.NumberComparator,
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
