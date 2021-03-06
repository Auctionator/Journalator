JournalatorDisplayMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

function JournalatorDisplayMixin:OnCloseClicked()
  self:Hide()
end
