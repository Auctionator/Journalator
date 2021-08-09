JournalatorDataTabDisplayMixin = {}

function JournalatorDataTabDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)

  Auctionator.EventBus:Register(self, {
    Journalator.Events.RowClicked
  })

  -- Used to only scan segments already open for realms and characters
  self.earliestRangeTime = time()

  local SECONDS_IN_A_MONTH = 30 * 24 * 60 * 60
  self.TimePeriodDropDown:InitAgain({
    JOURNALATOR_L_ALL_TIME,
    JOURNALATOR_L_LAST_YEAR,
    JOURNALATOR_L_LAST_6_MONTHS,
    JOURNALATOR_L_LAST_3_MONTHS,
    JOURNALATOR_L_LAST_MONTH,
    JOURNALATOR_L_LAST_WEEK,
    JOURNALATOR_L_LAST_DAY,
    JOURNALATOR_L_LAST_HOUR,
  }, {
    0,
    SECONDS_IN_A_MONTH * 12,
    SECONDS_IN_A_MONTH * 6,
    SECONDS_IN_A_MONTH * 3,
    SECONDS_IN_A_MONTH,
    7 * 24 * 60 * 60,
    24 * 60 * 60,
    60 * 60,
  })
  self.TimePeriodDropDown:SetValue(SECONDS_IN_A_MONTH)
end

function JournalatorDataTabDisplayMixin:RefreshButtonClicked()
  self.DataProvider:Refresh()
  self:UpdateRealms()
end

function JournalatorDataTabDisplayMixin:OnShow()
  self:UpdateRealms()
end

function JournalatorDataTabDisplayMixin:UpdateRealms()
  local prevRealm = self.RealmDropDown:GetValue() or ""

  local realmsAndChars = Journalator.GetCharactersAndRealms(self.earliestRangeTime)

  local realms = Journalator.Utilities.GetSortedKeys(realmsAndChars)
  local realmValues = Journalator.Utilities.GetSortedKeys(realmsAndChars)
  table.insert(realms, 1, JOURNALATOR_L_ALL_REALMS)
  table.insert(realmValues, 1, "")

  self.RealmDropDown:InitAgain(realms, realmValues)
  self.RealmDropDown:SetValue(prevRealm)
end

function JournalatorDataTabDisplayMixin:OnUpdate()
  self.DataProvider:SetFilters({
    searchText = self.SearchFilter:GetText(),
    secondsToInclude = self.TimePeriodDropDown:GetValue(),
    realm = self.RealmDropDown:GetValue(),
  })

  local newTime = self.DataProvider:GetTimeForRange()
  if newTime < self.earliestRangeTime then
    self.earliestRangeTime = newTime
    self:UpdateRealms()
  end

end

function JournalatorDataTabDisplayMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText(eventData.itemName)
  end
end
