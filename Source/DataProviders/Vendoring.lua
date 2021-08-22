local VENDORING_DATA_PROVIDER_LAYOUT ={
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
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_UNIT_PRICE,
    headerParameters = { "unitPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "unitPrice" }
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
    headerText = AUCTIONATOR_L_DATE,
    headerParameters = { "rawDay" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" }
  },
}

JournalatorVendoringDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

local JUNK_COLOR = "ff9d9d9d"
local function IsNotJunk(itemLink)
  return Auctionator.Utilities.GetQualityColorFromLink(itemLink) ~= JUNK_COLOR
end

function JournalatorVendoringDataProviderMixin:Refresh()
  self:Reset()
  local results = {}
  -- Used to group junk as one item (when the option is on), to avoid filling up
  -- the view with junk items.
  local junkValue = 0
  for _, item in ipairs(Journalator.Archiving.GetRange(self:GetTimeForRange(), "Vendoring")) do
    if self:Filter(item) then
      local moneyIn = 0
      local moneyOut = 0

      if item.vendorType == "sell" then
        moneyIn = item.unitPrice * item.count
      else
        moneyOut = -item.unitPrice * item.count
      end

      -- If not junk or the group junk option is off, include normally
      if not Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_VENDORING_GROUP_JUNK) or
         IsNotJunk(item.itemLink) then
        table.insert(results, {
          itemName = item.itemName,
          itemNamePretty = Journalator.ApplyQualityColor(item.itemName, item.itemLink),
          moneyIn = moneyIn,
          moneyOut = moneyOut,
          count = item.count,
          unitPrice = item.unitPrice,
          rawDay = item.time,
          date = SecondsToTime(time() - item.time),
          itemLink = item.itemLink,
          sourceCharacter = Journalator.Utilities.AddRealmToPlayerName(item.source.character, item.source),
        })
      else
        junkValue = junkValue + moneyIn - moneyOut
      end
    end
  end

  -- Create junk group item, without any normal details like a date or source.
  if junkValue ~= 0 and Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_VENDORING_GROUP_JUNK) then
    local moneyIn = 0
    local moneyOut = 0
    if junkValue > 0 then
      moneyIn = junkValue
    else
      moneyOut = junkValue
    end

    table.insert(results, 1, {
      itemName = JOURNALATOR_L_JUNK,
      itemNamePretty = "|c"..JUNK_COLOR .. JOURNALATOR_L_JUNK .. "|r",
      moneyIn = moneyIn,
      moneyOut = moneyOut,
      count = 1,
      unitPrice = math.abs(junkValue),
      rawDay = time(),
      date = "",
      itemLink = nil,
      sourceCharacter = "",
    })
  end
  self:AppendEntries(results, true)
end

function JournalatorVendoringDataProviderMixin:GetTableLayout()
  return VENDORING_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  sourceCharacter = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorVendoringDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Auctionator.Config.Create("JOURNALATOR_COLUMNS_VENDORING", "journalator_columns_vendoring", {})

function JournalatorVendoringDataProviderMixin:GetColumnHideStates()
  return Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_COLUMNS_VENDORING)
end
