JournalatorDisplayDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorDisplayDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200 --Reduce flickering when updating the display

  self.filters = {
    searchText = "", -- Text to filter item.itemName by
    secondsToInclude = 0, -- Time period to be included in the view
  }
end

function JournalatorDisplayDataProviderMixin:OnShow()
  self:Refresh()
end

-- Load/refresh the current view with the current filters
function JournalatorDisplayDataProviderMixin:Refresh()
  error("This should be overridden.")
end

-- Only sets the filters (and refreshes the view) if the filters have changed
function JournalatorDisplayDataProviderMixin:SetFilters(filters)
  local prevFilters = self.filters
  for key, val in pairs(prevFilters) do
    if filters[key] ~= val then
      self.filters = filters
      self.onPreserveScroll()
      self:Refresh()
      break
    end
  end
end

function JournalatorDisplayDataProviderMixin:Filter(item)
  local check = true

  if self.filters.secondsToInclude ~= 0 then
    check = check and (time() - item.time) <= self.filters.secondsToInclude
  end

  if self.filters.realm ~= "" then
    check = check and self.filters.realm == item.source.realm
  end

  check = check and string.find(string.lower(item.itemName), string.lower(self.filters.searchText), 1, true)

  return check
end

-- Every entry is considered unique (unlike in Auctionator when that isn't
-- always true)
function JournalatorDisplayDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

function JournalatorDisplayDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end

