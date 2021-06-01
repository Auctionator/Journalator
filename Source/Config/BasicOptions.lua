JournalatorConfigBasicOptionsFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function JournalatorConfigBasicOptionsFrameMixin:OnLoad()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:OnLoad()")

  self.name = JOURNALATOR_L_JOURNALATOR

  self:SetupPanel()
end

function JournalatorConfigBasicOptionsFrameMixin:OnShow()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:OnShow()")

  self.TooltipSaleRate:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE))
  self.TooltipFailures:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES))
  self.TooltipLastSold:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD))
  self.TooltipLastBought:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT))
end

function JournalatorConfigBasicOptionsFrameMixin:Save()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE, self.TooltipSaleRate:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES, self.TooltipFailures:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD, self.TooltipLastSold:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT, self.TooltipLastBought:GetChecked())
end

function JournalatorConfigBasicOptionsFrameMixin:Cancel()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:Cancel()")
end
