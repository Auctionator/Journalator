JournalatorInvoiceDisplayMixin = {}

function JournalatorInvoiceDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end
