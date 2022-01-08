JournalatorDataTabDisplayMixin = {}

function JournalatorDataTabDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end

function JournalatorDataTabDisplayMixin:RefreshButtonClicked()
  self.DataProvider:Refresh()
  self:GetParent().Filters:UpdateRealms()
end

function JournalatorDataTabDisplayMixin:OnUpdate()
  self.DataProvider:SetFilters(self:GetParent().Filters:GetFilters())

  self:GetParent().Filters:UpdateMinTime(self.DataProvider:GetTimeForRange())
end
