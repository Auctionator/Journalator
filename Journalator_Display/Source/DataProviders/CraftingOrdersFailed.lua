local CO_FAILED_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_REASON,
    headerParameters = { "reason" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "reason" },
  },
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

JournalatorCraftingOrdersFailedDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

local typesToText = {
  ["cancel"] = JOURNALATOR_L_CANCELLED,
  ["reject"] = JOURNALATOR_L_REJECTED,
  ["expire"] = JOURNALATOR_L_EXPIRED,
}

function JournalatorCraftingOrdersFailedDataProviderMixin:Refresh()
  if Auctionator.Constants.IsClassic then
    -- Nothing to do, no crafting orders
    return
  end

  self.onPreserveScroll()
  self:Reset()

  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "CraftingOrdersFailed")) do
    local filterItem = {
      itemName = item.recipeName,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local processedItem = {
        searchTerm = filterItem.itemName,
        itemName = filterItem.itemName,
        rawDay = item.time,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        index = index,
        selected = self:IsSelected(index),
      }
      processedItem.reason = typesToText[item.failType]
      if processedItem.reason == nil then
        processedItem.reason = JOURNALATOR_L_OTHER
      end

      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorCraftingOrdersFailedDataProviderMixin:GetTableLayout()
  return CO_FAILED_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  reason = Auctionator.Utilities.StringComparator,
  itemName = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorCraftingOrdersFailedDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_CO_FAILED", "columns_crafting_orders_failed", {})

function JournalatorCraftingOrdersFailedDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_CO_FAILED)
end

function JournalatorCraftingOrdersFailedDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end
