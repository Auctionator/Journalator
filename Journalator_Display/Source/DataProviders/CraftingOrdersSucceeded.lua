local CO_SUCCEEDED_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_COMMISSION_PAID,
    headerParameters = { "commissionPaid" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "commissionPaid" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_CRAFTER_NOTE,
    headerParameters = { "crafterNote" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "crafterNote" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_CRAFTER,
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorCraftingOrdersSucceededDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorCraftingOrdersSucceededDataProviderMixin:Refresh()
  if Auctionator.Constants.IsClassic then
    -- Nothing to do, no crafting orders
    return
  end

  self.onPreserveScroll()
  self:Reset()

  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "CraftingOrdersSucceeded")) do
    -- Check to filter out corrupted entries from the API returning crafting
    -- order data even when there wasn't an order attached to the mail.
    if item.recipeName ~= "" and item.commissionPaid ~= 0 then
      local filterItem = {
        itemName = item.itemName or item.recipeName,
        time = item.time,
        source = item.source,
      }
      if self:Filter(filterItem) then
        local processedItem = {
          searchTerm = filterItem.itemName,
          itemName = filterItem.itemName,
          itemNamePretty = filterItem.itemName,
          commissionPaid = item.commissionPaid,
          rawDay = item.time,
          itemLink = item.itemLink,
          crafterNote = item.crafterNote,
          otherPlayer = Journalator.Utilities.AddRealmToPlayerName(item.crafterName, item.source),
          sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
          realmID = item.source.realmID,
          index = index,
          value = - item.commissionPaid,
          selected = self:IsSelected(index),
        }

        if processedItem.itemLink ~= nil then
          processedItem.itemName = Journalator.Utilities.AddTierToBasicName(processedItem.itemName, processedItem.itemLink)
          processedItem.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(processedItem.itemNamePretty, processedItem.itemLink)
          processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
        end
        table.insert(results, processedItem)
      end
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorCraftingOrdersSucceededDataProviderMixin:GetTableLayout()
  return CO_SUCCEEDED_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  commissionPaid = Auctionator.Utilities.NumberComparator,
  crafterNote = Auctionator.Utilities.StringComparator,
  otherPlayer = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorCraftingOrdersSucceededDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_CO_SUCCEEDED", "columns_crafting_orders_succeeded", {})

function JournalatorCraftingOrdersSucceededDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_CO_SUCCEEDED)
end

function JournalatorCraftingOrdersSucceededDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end
