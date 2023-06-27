local BASIC_MAIL_SENT_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_COD,
    headerParameters = { "moneyIn" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_SEND_COST,
    headerParameters = { "sendCost" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "sendCost" },
    width = 150,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_RECIPIENT,
    headerParameters = { "recipient" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "recipient" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_SENDER,
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

JournalatorBasicMailSentDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorBasicMailSentDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()
  local results = {}
  for index, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "BasicMailSent")) do
    local filterItem = {
      itemName = item.subject,
      time = item.time,
      source = item.source,
    }
    if self:Filter(filterItem) then
      local processedItem = {
        searchTerm = item.subject,
        itemName = item.subject,
        moneyOut = item.money,
        moneyIn = item.cod,
        sendCost = item.sendCost,
        rawDay = item.time,
        sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        realmID = item.source.realmID,
        recipient = Journalator.Utilities.AddRealmToPlayerName(item.recipient, item.source),
        subject = item.subject,
        text = item.text,
        index = index,
        value = -item.money,
        selected = self:IsSelected(index),
      }
      table.insert(results, processedItem)
    end
  end
  self:AppendEntries(results, true)
end

function JournalatorBasicMailSentDataProviderMixin:GetTableLayout()
  return BASIC_MAIL_SENT_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  recipient = Auctionator.Utilities.StringComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorBasicMailSentDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_BASIC_MAIL_SENT", "columns_basic_mail_sent", {})

function JournalatorBasicMailSentDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_BASIC_MAIL_SENT)
end

function JournalatorBasicMailSentDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewBasicMailRowTemplate"
end
