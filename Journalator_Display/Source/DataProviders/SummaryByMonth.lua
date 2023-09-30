local SUMMARY_DATA_PROVIDER_LAYOUT ={
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_DATE,
    headerParameters = { "itemName" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "itemName" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_IN,
    headerParameters = { "moneyIn" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyIn" },
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = JOURNALATOR_L_OUT,
    headerParameters = { "moneyOut" },
    cellTemplate = "JournalatorPriceCellTemplate",
    cellParameters = { "moneyOut" },
  },
}

JournalatorSummaryByMonthDataProviderMixin = CreateFromMixins(JournalatorDisplayDataProviderMixin)

function JournalatorSummaryByMonthDataProviderMixin:Refresh()
  self.onPreserveScroll()
  self:Reset()

  local startTime = self:GetTimeForRange()
  local d = date("*t")
  local dayOffset = - 24 * 60 * 60 + C_DateAndTime.GetSecondsUntilDailyReset()
  d.day = 1
  local monthStart = time(d) + dayOffset
  d = date("*t", monthStart)

  local results = {}

  while monthStart >= JOURNALATOR_ARCHIVE_TIMES[1] and monthStart >= startTime do
    local monthEnd = CopyTable(d)
    monthEnd.month = monthEnd.month + 1
    if monthEnd.month > 12 then
      monthEnd.month = 1
      monthEnd.year = monthEnd.year + 1
    end
    local _, incoming, outgoing = Journalator.GetProfit(monthStart, time(monthEnd), function(item)
      return self:Filter(item)
    end)
    if incoming ~= 0 or outgoing ~= 0 then
      local month = _G["AUCTIONATOR_L_MONTH_" .. d.month]
      table.insert(results, {
        itemName = month,
        moneyIn = incoming,
        moneyOut = -outgoing,
        index = index,
      })
    end

    d.month = d.month - 1
    if d.month == 0 then
      d.year = d.year - 1
      d.month = 12
    end
    monthStart = time(d)
  end

  self:AppendEntries(results, true)
end

function JournalatorSummaryByMonthDataProviderMixin:GetTableLayout()
  return SUMMARY_DATA_PROVIDER_LAYOUT
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  moneyIn = Auctionator.Utilities.NumberComparator,
  moneyOut = Auctionator.Utilities.NumberComparator,
}

function JournalatorSummaryByMonthDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

Journalator.Config.Create("COLUMNS_SUMMARY_BY_MONTH", "columns_summary_by_month", {})

function JournalatorSummaryByMonthDataProviderMixin:GetColumnHideStates()
  return Journalator.Config.Get(Journalator.Config.Options.COLUMNS_SUMMARY_BY_MONTH)
end

function JournalatorSummaryByMonthDataProviderMixin:GetRowTemplate()
  return "AuctionatorResultsRowTemplate"
end
