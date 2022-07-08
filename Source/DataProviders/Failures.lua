local FAILURES_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TYPE_OF_FAILURE,
    headerParameters = { "failedType" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "failedType" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_NAME,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemNamePretty" },
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

local FAILED_TYPE_TO_TEXT = {
  ["expired"] = JOURNALATOR_L_EXPIRED,
  ["cancelled"] = JOURNALATOR_L_CANCELLED,
}

JournalatorFailuresDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorFailuresDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Failures")) do
    if self:Filter(item) then
      local processedItem = {
        itemName = item.itemName,
        itemNamePretty = item.itemName,
        failedType = FAILED_TYPE_TO_TEXT[item.failedType],
        count = item.count,
        rawDay = item.time,
        date = SecondsToTime(time() - item.time),
        itemLink = item.itemLink,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
      }

      if processedItem.itemLink ~= nil then
        processedItem.itemNamePretty = Journalator.ApplyQualityColor(item.itemName, processedItem.itemLink)
      end

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorFailuresDataProviderMixin:GetTableLayout()
  return FAILURES_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  failedType = Auctionator.Utilities.StringComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorFailuresDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_FAILURES", "columns_failures", {})

function JournalatorFailuresDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_FAILURES)
end
