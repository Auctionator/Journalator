JournalatorFiltersContainerMixin = {}

function JournalatorFiltersContainerMixin:OnLoad()
  -- Used to only scan segments already open for realms and characters
  self.earliestRangeTime = time()

  Auctionator.EventBus:Register(self, {
    Journalator.Events.RowClicked
  })

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

  self.FactionDropDown:InitAgain({
    JOURNALATOR_L_ALL_FACTIONS,
    FACTION_ALLIANCE,
    FACTION_HORDE,
  }, {
    "",
    "Alliance",
    "Horde",
  })
end

function JournalatorFiltersContainerMixin:OnShow()
  self:UpdateRealms()
end

function JournalatorFiltersContainerMixin:UpdateRealms()
  local realmsAndChars = Journalator.GetCharactersAndRealms(self.earliestRangeTime)

  local realms = Journalator.Utilities.GetSortedKeys(realmsAndChars)

  self.RealmDropDown:SetRealms(realms, true)
end

function JournalatorFiltersContainerMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText(eventData.itemName)
  end
end

function JournalatorFiltersContainerMixin:GetFilters()
  return {
    searchText = self.SearchFilter:GetText(),
    secondsToInclude = self.TimePeriodDropDown:GetValue(),
    realm = function(realmName) return self.RealmDropDown:GetValue(realmName) end,
    faction = self.FactionDropDown:GetValue(),
  }
end

function JournalatorFiltersContainerMixin:UpdateMinTime(newTime)
  if newTime < self.earliestRangeTime then
    self.earliestRangeTime = newTime
    self:UpdateRealms()
  end
end
