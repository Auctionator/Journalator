JournalatorLogViewMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

function JournalatorLogViewMixin:OnCloseClicked()
  self:Hide()
end
