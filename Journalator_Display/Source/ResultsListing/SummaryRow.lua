JournalatorLogSummaryViewRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function JournalatorLogSummaryViewRowMixin:OnClick(button)
  Auctionator.EventBus
    :RegisterSource(self, "JournalatorLogSummaryViewRowMixin")
    :Fire(self, Journalator.Events.RequestTabSwitch, self.rowData.tabDetails)
    :UnregisterSource(self)
end
