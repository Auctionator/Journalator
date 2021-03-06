JournalatorLogViewMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

function JournalatorLogViewMixin:OnLoad()
  self.HistoricalPriceListing:Init(self.HistoricalPriceProvider)
end

function JournalatorLogViewMixin:OnCloseClicked()
  self:Hide()
end
