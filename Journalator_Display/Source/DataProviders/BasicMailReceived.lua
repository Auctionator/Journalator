local BASIC_MAIL_RECEIVED_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_COD,
    headerParameters = { "moneyOut" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_SENDER,
    headerParameters = { "sender" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "sender" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_RECIPIENT,
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

JournalatorBasicMailReceivedDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorBasicMailReceivedDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "BasicMailReceived")) do
    local filterItem = {
      itemName = item.subject,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local processedItem = {
        searchTerm = item.subject,
        itemName = item.subject,
        moneyIn = item.money,
        moneyOut = item.cod,
        rawDay = item.time,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        realmID = item.source.realmID,
        sender = Journalator.Utilities.AddRealmToPlayerName(item.sender, item.source),
        index = index,
        value = item.money - item.cod,
        selected = self:IsSelected(index),
      }
      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorBasicMailReceivedDataProviderMixin:GetTableLayout()
  return BASIC_MAIL_RECEIVED_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  sender = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorBasicMailReceivedDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_BASIC_MAIL_RECEIVED", "columns_basic_mail_recieved", {})

function JournalatorBasicMailReceivedDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_BASIC_MAIL_RECEIVED)
end
