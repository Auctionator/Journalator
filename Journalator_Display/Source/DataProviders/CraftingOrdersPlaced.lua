local CO_PLACED_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_TYPE,
    headerParameters = { "orderType" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "orderType" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_GUILD,
    headerParameters = { "guildName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "guildName" },
    defaultHide = true,
  },
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
    headerText = JOURNALATOR_L_TIP,
    headerParameters = { "tipAmount" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "tipAmount" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_POSTING_FEE,
    headerParameters = { "postingFee" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "postingFee" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_CUSTOMER_NOTE,
    headerParameters = { "customerNote" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "customerNote" },
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
    headerText = JOURNALATOR_L_TIME_ELAPSED,
    headerParameters = { "rawDay" },
    cellTemplate = "JournalatorTimeCellTemplate",
    cellParameters = { "rawDay" }
  },
}

JournalatorCraftingOrdersPlacedDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorCraftingOrdersPlacedDataProviderMixin:Refresh()
  if Auctionator.Constants.IsClassic then
    -- Nothing to do, no crafting orders
    return
  end

  self.onPreserveScroll()
  self:Reset()

  local TYPES_TO_TYPE_STRING = {
    [Enum.CraftingOrderType.Public] = JOURNALATOR_L_PUBLIC,
    [Enum.CraftingOrderType.Guild] = JOURNALATOR_L_GUILD,
    [Enum.CraftingOrderType.Personal] = JOURNALATOR_L_PERSONAL,
  }

  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "CraftingOrdersPlaced")) do
    if self:Filter(item) then
      local processedItem = {
        orderType = TYPES_TO_TYPE_STRING[item.orderType],
        searchTerm = item.itemName,
        itemName = item.itemName,
        itemNamePretty = item.itemName,
        tipAmount = item.tipAmount,
        postingFee = item.postingFee,
        rawDay = item.time,
        itemLink = item.itemLink,
        guildName = item.guildName or "",
        customerNote = item.customerNote,
        customerReagents = item.customerReagents,
        isRecraft = item.isRecraft,
        recraftItemLink = item.recraftItemLink,
        otherPlayer = Journalator.Utilities.AddRealmToPlayerName(item.playerName, item.source),
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        index = index,
        value =  - item.postingFee,
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
  self:AppendEntries(results, true)
end

function JournalatorCraftingOrdersPlacedDataProviderMixin:GetTableLayout()
  return CO_PLACED_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  orderType = Auctionator.Utilities.StringComparator,
  guildName = Auctionator.Utilities.StringComparator,
  itemName = Auctionator.Utilities.StringComparator,
  tipAmount = Auctionator.Utilities.NumberComparator,
  postingFee = Auctionator.Utilities.NumberComparator,
  customerNote = Auctionator.Utilities.StringComparator,
  otherPlayer = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorCraftingOrdersPlacedDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_CO_PLACED", "columns_crafting_orders_placed", {})

function JournalatorCraftingOrdersPlacedDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_CO_PLACED)
end

function JournalatorCraftingOrdersPlacedDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewCraftingOrdersRowTemplate"
end
