JournalatorInvoiceLogViewMixin = {}

function JournalatorInvoiceLogViewMixin:OnLoad()
  self.ResultsListing:Init(self.DataProvider)
end
