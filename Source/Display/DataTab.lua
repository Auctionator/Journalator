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
  self:UpdateRealms()
end

function JournalatorDataTabDisplayMixin:OnShow()
  self:UpdateRealms()
end

function JournalatorDataTabDisplayMixin:UpdateRealms()
  local realmsAndChars = Journalator.GetCharactersAndRealms()

  local realms = Journalator.Utilities.GetSortedKeys(realmsAndChars)
  local realmValues = Journalator.Utilities.GetSortedKeys(realmsAndChars)
  table.insert(realms, 1, JOURNALATOR_L_ALL_REALMS)
  table.insert(realmValues, 1, "")

  self.RealmDropDown:InitAgain(realms, realmValues)
  self.RealmDropDown:SetValue("")
end

function JournalatorDataTabDisplayMixin:OnUpdate()
  self.DataProvider:SetFilters({
    searchText = self.SearchFilter:GetText(),
    secondsToInclude = self.TimePeriodDropDown:GetValue(),
    realm = self.RealmDropDown:GetValue(),
  })
end

function JournalatorDataTabDisplayMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText(eventData.itemName)
  end
end
