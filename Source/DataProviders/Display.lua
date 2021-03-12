JournalatorDisplayDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function JournalatorDisplayDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200
end

function JournalatorDisplayDataProviderMixin:OnShow()
  self:Refresh()
end

function JournalatorDisplayDataProviderMixin:Refresh()
  error("This should be overridden.")
end

function JournalatorDisplayDataProviderMixin:SetFilters(filters)
  self.filters = filters
end

function JournalatorDisplayDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

function JournalatorDisplayDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end

