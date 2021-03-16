JournalatorDataTabDisplayMixin = {}

function JournalatorDataTabDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)

  Auctionator.EventBus:Register(self, {
    Journalator.Events.RowClicked
  })

  local SECONDS_IN_A_MONTH = 30 * 24 * 60 * 60
  self.TimePeriodDropDown:InitAgain({
    JOURNALATOR_L_ALL_TIME,
    JOURNALATOR_L_LAST_MONTH,
    JOURNALATOR_L_LAST_WEEK,
    JOURNALATOR_L_LAST_DAY,
    JOURNALATOR_L_LAST_HOUR,
  }, {
    0,
    SECONDS_IN_A_MONTH,
    7 * 24 * 60 * 60,
    24 * 60 * 60,
    60 * 60,
  })
  self.TimePeriodDropDown:SetValue(SECONDS_IN_A_MONTH)
end

function JournalatorDataTabDisplayMixin:RefreshButtonClicked()
  self.DataProvider:Refresh()
end

function JournalatorDataTabDisplayMixin:OnUpdate()
  self.DataProvider:SetFilters({
    searchText = self.SearchFilter:GetText(),
    secondsToInclude = self.TimePeriodDropDown:GetValue()
  })
end

function JournalatorDataTabDisplayMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText(eventData.itemName)
  end
end
