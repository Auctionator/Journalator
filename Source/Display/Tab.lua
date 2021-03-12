JournalatorDisplayTabMixin = {}

function JournalatorDisplayTabMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end
