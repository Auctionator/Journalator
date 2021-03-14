JournalatorDisplayTabMixin = {}

function JournalatorDisplayTabMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end

function JournalatorDisplayTabMixin:RefreshButtonClicked()
  self.DataProvider:Refresh()
end

function JournalatorDisplayTabMixin:OnUpdate()
  self.DataProvider:SetFilters({
    searchText = self.SearchFilter:GetText(),
  })
end
