JournalatorLogViewBasicMailRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

JournalatorLogViewBasicMailRowMixin.Populate = JournalatorLogViewResultsRowMixin.Populate
JournalatorLogViewBasicMailRowMixin.OnClick = JournalatorLogViewResultsRowMixin.OnClick

function JournalatorLogViewBasicMailRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

  GameTooltip:SetText(self.rowData.subject)

  if self.rowData.text ~= "" then
    GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(self.rowData.text))
  end

  GameTooltip:Show()
end

function JournalatorLogViewBasicMailRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)

  GameTooltip:Hide()
end
