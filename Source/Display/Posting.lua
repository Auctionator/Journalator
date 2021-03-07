JournalatorPostingDisplayMixin = {}

function JournalatorPostingDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end
