JournalatorInvoiceDisplayMixin = {}

function JournalatorInvoiceDisplayMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
  print(self.StatusText, self)
end
