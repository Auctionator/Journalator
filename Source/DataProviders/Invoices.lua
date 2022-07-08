local INVOICES_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_IN_INCLUDING_AH_CUT,
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
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
    headerText = JOURNALATOR_L_PLAYER,
    headerParameters = { "otherPlayer" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "otherPlayer" }
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
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" }
  },
}

JournalatorInvoicesDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorInvoicesDataProviderMixin:Refresh()
  self:Reset()

  local results = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Invoices")) do
    if self:Filter(item) then
      local moneyIn = 0
      local moneyOut = 0
      if item.invoiceType == "seller" then
        moneyIn = item.value + item.deposit - item.consignment
      else
        moneyOut = -item.value
      end
      local timeSinceEntry = time() - item.time

      local itemNamePretty = item.itemName
      local itemLink = item.itemLink or Journalator.GetItemInfo(item.itemName, item.deposit, item.count)
      if itemLink then
        itemNamePretty = Journalator.ApplyQualityColor(item.itemName, itemLink)
      end

      local otherPlayer = Journalator.Utilities.AddRealmToPlayerName(item.playerName, item.source)
      if otherPlayer == nil then
        if item.invoiceType == "seller" then
          otherPlayer = GRAY_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_MULTIPLE_BUYERS)
        else
          otherPlayer = GRAY_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_MULTIPLE_SELLERS)
        end
      end

      local sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source)

      table.insert(results, {
        itemName = item.itemName,
        itemNamePretty = itemNamePretty,
        moneyIn = moneyIn,
        moneyOut = moneyOut,
        count = item.count,
        unitPrice = math.floor(item.value/item.count),
        rawDay = item.time,
        date = SecondsToTime(timeSinceEntry),
        otherPlayer = otherPlayer,
        sourceCharacter = sourceCharacter,
        itemLink = itemLink,
      })
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorInvoicesDataProviderMixin:GetTableLayout()
  return INVOICES_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  invoiceType = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
  otherPlayer = Auctionator.Utilities.StringComparator,
}

function JournalatorInvoicesDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_INVOICES", "columns_invoices", {})

function JournalatorInvoicesDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_INVOICES)
end

