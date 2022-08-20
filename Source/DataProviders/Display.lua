JournalatorDisplayDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorDisplayDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200 --Reduce flickering when updating the display

  Auctionator.EventBus:Register(self, {
    Journalator.Events.FiltersChanged
  })
end

function JournalatorDisplayDataProviderMixin:OnShow()
  self:Refresh()
end

function JournalatorDisplayDataProviderMixin:ReceiveEvent(eventName, ...)
  if eventName == Journalator.Events.FiltersChanged then
    if self:IsVisible() then
      self.onPreserveScroll()
      self:Refresh()
    end
  end
end

-- Load/refresh the current view with the current filters
function JournalatorDisplayDataProviderMixin:Refresh()
  error("This should be overridden.")
end

function JournalatorDisplayDataProviderMixin:Filter(item)
  return self:GetParent():GetParent().Filters:Filter(item)
end

function JournalatorDisplayDataProviderMixin:GetTimeForRange()
  return self:GetParent():GetParent().Filters:GetTimeForRange()
end

-- Every entry is considered unique (unlike in Auctionator when that isn't
-- always true)
function JournalatorDisplayDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

function JournalatorDisplayDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end

