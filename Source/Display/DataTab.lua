JournalatorDataTabDisplayMixin = {}

function JournalatorDataTabDisplayMixin:OnLoad()
  self.DataProvider:SetFilters(self:GetParent().Filters:GetFilters())
  self.ResultsListing:Init(self.DataProvider)
end

function JournalatorDataTabDisplayMixin:OnUpdate()
  self.DataProvider:SetFilters(self:GetParent().Filters:GetFilters())

  self:GetParent().Filters:UpdateMinTime(self.DataProvider:GetTimeForRange())
end
