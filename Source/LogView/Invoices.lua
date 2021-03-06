JournalatorInvoiceLogViewMixin = {}

function JournalatorInvoiceLogViewMixin:OnLoad()
  self.HistoricalPriceListing:Init(self.HistoricalPriceProvider)
end
