JournalatorConfigBasicOptionsFrameMixin = {}

function JournalatorConfigBasicOptionsFrameMixin:OnLoad()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:OnLoad()")

  self.name = JOURNALATOR_L_JOURNALATOR

  self.cancel = function()
    self:Cancel()
  end

  self.okay = function()
    self:Save()
  end

  InterfaceOptions_AddCategory(self, "Journalator")
end

function JournalatorConfigBasicOptionsFrameMixin:OnShow()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:OnShow()")

  self.TooltipSaleRate:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE))
  self.TooltipFailures:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES))
  self.TooltipLastSold:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD))
  self.TooltipLastBought:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT))

  self.GroupJunk:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_VENDORING_GROUP_JUNK))

  self.ShowMinimapIcon:SetChecked(not Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_MINIMAP_ICON).hide)
end

function JournalatorConfigBasicOptionsFrameMixin:Save()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_SALE_RATE, self.TooltipSaleRate:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_FAILURES, self.TooltipFailures:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_SOLD, self.TooltipLastSold:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_TOOLTIP_LAST_BOUGHT, self.TooltipLastBought:GetChecked())

  Auctionator.Config.Set(Auctionator.Config.Options.JOURNALATOR_VENDORING_GROUP_JUNK, self.GroupJunk:GetChecked())

  Auctionator.Config.Get(Auctionator.Config.Options.JOURNALATOR_MINIMAP_ICON).hide = not self.ShowMinimapIcon:GetChecked()
  Journalator.MinimapIcon.UpdateShown()
end

function JournalatorConfigBasicOptionsFrameMixin:ComputeFullStatisticsClicked()
  Journalator.Archiving.LoadAll(function()
    Journalator.Statistics.ComputeFullCache()
    Journalator.Utilities.Message(JOURNALATOR_L_FINISHED_COMPUTING_STATISTICS)
  end)
end


function JournalatorConfigBasicOptionsFrameMixin:Cancel()
  Auctionator.Debug.Message("JournalatorConfigBasicOptionsFrameMixin:Cancel()")
end
