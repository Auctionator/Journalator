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

  Auctionator.EventBus:RegisterSource(self, "JournalatorFiltersContainer")

  self.filters = self:GetFilters()
  self.pending = false
end

function JournalatorFiltersContainerMixin:OnShow()
  self:UpdateRealms()
end

function JournalatorFiltersContainerMixin:OnUpdate()
  self:UpdateMinTime(self:GetTimeForRange())
  self:CheckFiltersChanged(self:GetFilters())
end

function JournalatorFiltersContainerMixin:UpdateRealms()
  local realmsAndChars = Journalator.GetCharactersAndRealms(self.earliestRangeTime)

  local realms = Journalator.Utilities.GetSortedKeys(realmsAndChars)

  self.RealmDropDown:SetRealms(realms, true)
end

function JournalatorFiltersContainerMixin:CheckFiltersChanged(filters)
  local prevFilters = self.filters
  for key, val in pairs(prevFilters) do
    if (type(filters[key]) == "function" and filters[key]()) or
       (type(filters[key]) ~= "function" and filters[key] ~= val)
       then
      self.filters = filters
      Auctionator.EventBus:Fire(self, Journalator.Events.FiltersChanged)
      break
    end
  end
end

function JournalatorFiltersContainerMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText("\"" .. eventData.itemName .. "\"")
  end
end

function JournalatorFiltersContainerMixin:GetTimeForRange()
  local secondsToInclude = self.TimePeriodDropDown:GetValue()
  if secondsToInclude == 0 then
    return 0
  else
    return time() - secondsToInclude
  end
end

function JournalatorFiltersContainerMixin:Filter(item)
  local check = true

  if self.filters.secondsToInclude ~= 0 then
    check = check and (time() - item.time) <= self.filters.secondsToInclude
  end

  -- Work around one-time error when source data wasn't saved
  if item.source == nil then
    return false
  end

  check = check and self.filters.realm(item.source.realm)

  if self.filters.faction ~= "" then
    check = check and self.filters.faction == item.source.faction
  end

  -- Ignore broken results caused by WoW API not returning a valid name inside
  -- the item link (code that generated them has been replaced, but some may
  -- still exist in Journalator item logs)
  if item.itemName == nil then
    return false
  end

  check = check and (self.filters.search(item.itemName) or (item.playerName and self.filters.search(item.playerName)))

  return check
end

-- Returns a function that will check if an item name matches any of the current
-- search terms.
function JournalatorFiltersContainerMixin:GetSearch()
  local searchTexts = {strsplit("\a", (self.SearchFilter:GetText():lower():gsub("%|%|", "\a")))}
  local searchTerms = {}
  for _, text in ipairs(searchTexts) do
    local exact = text:match("^\"(.*)\"$")
    if exact ~= nil then
      table.insert(searchTerms, {text = exact, isExact = true})
    else
      table.insert(searchTerms, {text = text, isExact = false})
    end
  end

  return function(itemName)
    if itemName == nil then -- Not using function-based filter change check
      return false
    end

    local lower = string.lower(itemName)
    for _, term in ipairs(searchTerms) do
      if term.isExact then
        if lower == term.text then
          return true
        end
      else
        if string.find(lower, term.text, 1, true) then
          return true
        end
      end
    end
    return false
  end
end

function JournalatorFiltersContainerMixin:GetFilters()
  return {
    search = self:GetSearch(),
    searchText = self.SearchFilter:GetText(), -- Used to check if filter changes
    secondsToInclude = self.TimePeriodDropDown:GetValue(),
    realm = function(realmName) return self.RealmDropDown:GetValue(realmName) end,
    faction = self.FactionDropDown:GetValue(),
  }
end

function JournalatorFiltersContainerMixin:UpdateMinTime(newTime)
  if newTime < self.earliestRangeTime then
    self.earliestRangeTime = newTime
    if not self.pending then
      self.pending = true
      Journalator.Archiving.LoadUpTo(self:GetTimeForRange(), function()
        self:UpdateRealms()
        self.pending = false
      end)
    end
  end
end
