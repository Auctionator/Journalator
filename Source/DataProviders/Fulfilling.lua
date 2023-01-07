local FULFILLING_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
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
    headerText = JOURNALATOR_L_CRAFTER_NOTE,
    headerParameters = { "crafterNote" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "crafterNote" },
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
    headerText = JOURNALATOR_L_CRAFTER,
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

JournalatorFulfillingDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorFulfillingDataProviderMixin:Refresh()
  if Auctionator.Constants.IsClassic then
    -- Nothing to do, no crafting orders
    return
  end

  self:Reset()

  local TYPES_TO_TYPE_STRING = {
    [Enum.CraftingOrderType.Public] = JOURNALATOR_L_PUBLIC,
    [Enum.CraftingOrderType.Guild] = JOURNALATOR_L_GUILD,
    [Enum.CraftingOrderType.Personal] = JOURNALATOR_L_PERSONAL,
  }

  local results = {}
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Fulfilling")) do
    if self:Filter(item) then
      local processedItem = {
        orderType = TYPES_TO_TYPE_STRING[item.orderType],
        itemName = item.itemName,
        itemNamePretty = item.itemName,
        moneyIn = item.tipAmount - item.consortiumCut,
        rawDay = item.time,
        itemLink = item.itemLink,
        guildName = item.guildName or "",
        customerNote = item.customerNote,
        crafterNote = item.crafterNote,
        otherPlayer = Journalator.Utilities.AddRealmToPlayerName(item.playerName, item.source),
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
      }

      if processedItem.itemLink ~= nil then
        processedItem.itemNamePretty = Journalator.Utilities.AddQualityIconToItemName(processedItem.itemNamePretty, processedItem.itemLink)
        processedItem.itemNamePretty = Journalator.ApplyQualityColor(processedItem.itemNamePretty, processedItem.itemLink)
      end
      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorFulfillingDataProviderMixin:GetTableLayout()
  return FULFILLING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  orderType = Auctionator.Utilities.StringComparator,
  guildName = Auctionator.Utilities.StringComparator,
  itemName = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  customerNote = Auctionator.Utilities.StringComparator,
  crafterNote = Auctionator.Utilities.StringComparator,
  otherPlayer = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorFulfillingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_FULFILLING", "columns_fulfilling", {})

function JournalatorFulfillingDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_FULFILLING)
end
