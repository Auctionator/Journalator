local TRADING_POST_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemNamePretty" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_PRICE,
    headerParameters = { "price" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "price" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_IS_REFUND,
    headerParameters = { "isRefund" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "isRefund" },
    width = 100
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorTradingPostDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorTradingPostDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "TradingPostVendoring")) do
    if self:Filter(item) then
      local processedItem = {
        itemName = item.itemName,
        itemNamePretty = item.itemName,
        price = item.price,
        itemLink = item.itemLink,
        rawDay = item.time,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        index = index,
        value = 0,
        selected = self:IsSelected(index),
      }

      if item.isRefund then
        processedItem.isRefund = AUCTIONATOR_L_UNDERCUT_YES
      else
        processedItem.isRefund = AUCTIONATOR_L_UNDERCUT_NO
      end

      if processedItem.itemLink ~= nil then
        processedItem.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(processedItem.itemNamePretty, processedItem.itemLink)
        processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
      end
      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorTradingPostDataProviderMixin:GetTableLayout()
  return TRADING_POST_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  price = Auctionator.Utilities.NumberComparator,
  isRefund = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorTradingPostDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_TRADING_POST", "columns_trading_post", {})

function JournalatorTradingPostDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_TRADING_POST)
end
