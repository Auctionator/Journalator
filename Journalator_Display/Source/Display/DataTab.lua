JournalatorDataTabDisplayMixin = {}

function JournalatorDataTabDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end
