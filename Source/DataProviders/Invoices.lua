local INVOICES_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Name",
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
    width = 300,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "In (including AH cut)",
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Out",
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" }
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = "Unit Price (excluding AH cut)",
    headerParameters = { "unitPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "unitPrice" }
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

JournalatorInvoicesDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorInvoicesDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
end

local SECONDS_IN_A_MONTH = 30 * 24 * 60 * 60

function JournalatorInvoicesDataProviderMixin:OnShow()
  self:Reset()
  local results = {}
  local monthlyTotal = 0
  for _, item in ipairs(JOURNALATOR_LOGS.Invoices) do
    local moneyIn, moneyOut
    if item.invoiceType == "seller" then
      moneyIn = item.value + item.deposit - item.consignment
    else
      moneyOut = -item.value
    end
    local timeSinceEntry = time() - item.time

    table.insert(results, {
      itemName = item.itemName,
      moneyIn = moneyIn,
      moneyOut = moneyOut,
      count = item.count,
      unitPrice = item.value/item.count,
      rawDay = item.time,
      date = SecondsToTime(timeSinceEntry),
    })

    if timeSinceEntry < SECONDS_IN_A_MONTH then
      if moneyIn ~= nil then
        monthlyTotal = monthlyTotal + moneyIn
      else
        monthlyTotal = monthlyTotal + moneyOut
      end
    end
  end
  if monthlyTotal < 0 then
    self:GetParent().StatusText:SetText("You lost " .. Auctionator.Utilities.CreateMoneyString(-monthlyTotal) .. " this month")
  else
    self:GetParent().StatusText:SetText("You gained " .. Auctionator.Utilities.CreateMoneyString(monthlyTotal) .. "this month")
  end
  self:AppendEntries(results, true)
end

function JournalatorInvoicesDataProviderMixin:GetTableLayout()
  return INVOICES_DATA_PROVIDER_LAYOUT
end

function JournalatorInvoicesDataProviderMixin:UniqueKey(entry)
  return tostring(tostring(entry.price) .. tostring(entry.rawDay))
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  invoiceType = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  count = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
}

function JournalatorInvoicesDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function JournalatorInvoicesDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end
