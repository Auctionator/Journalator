JournalatorDisplayTabMixin = {}

function JournalatorDisplayTabMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)

  Auctionator.EventBus:Register(self, {
    Journalator.Events.RowClicked
  })
end

function JournalatorDisplayTabMixin:RefreshButtonClicked()
  self.DataProvider:Refresh()
end

function JournalatorDisplayTabMixin:OnUpdate()
  self.DataProvider:SetFilters({
    searchText = self.SearchFilter:GetText(),
  })
end

function JournalatorDisplayTabMixin:ReceiveEvent(eventName, eventData)
  if eventName == Journalator.Events.RowClicked and self:IsVisible() then
    self.SearchFilter:SetText(eventData.itemName)
  end
end
