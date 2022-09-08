JournalatorConfigBasicOptionsFrameMixin = {}

function JournalatorConfigBasicOptionsFrameMixin:OnLoad()
  self:SetParent(SettingsPanel or InterfaceOptionsFrame)
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
  self.TooltipSaleRate:SetChecked(Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_SALE_RATE))
  self.TooltipFailures:SetChecked(Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_FAILURES))
  self.TooltipLastSold:SetChecked(Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_SOLD))
  self.TooltipLastBought:SetChecked(Journalator.Config.Get(Journalator.Config.Options.TOOLTIP_LAST_BOUGHT))

  self.GroupJunk:SetChecked(Journalator.Config.Get(Journalator.Config.Options.VENDORING_GROUP_JUNK))

  self.ShowDetailedStatus:SetChecked(Journalator.Config.Get(Journalator.Config.Options.SHOW_DETAILED_STATUS))

  self.ShowMinimapIcon:SetChecked(not Journalator.Config.Get(Journalator.Config.Options.MINIMAP_ICON).hide)

  self.DebugMode:SetChecked(Journalator.Config.Get(Journalator.Config.Options.DEBUG))
end

function JournalatorConfigBasicOptionsFrameMixin:Save()
  Journalator.Config.Set(Journalator.Config.Options.TOOLTIP_SALE_RATE, self.TooltipSaleRate:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.TOOLTIP_FAILURES, self.TooltipFailures:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.TOOLTIP_LAST_SOLD, self.TooltipLastSold:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.TOOLTIP_LAST_BOUGHT, self.TooltipLastBought:GetChecked())

  Journalator.Config.Set(Journalator.Config.Options.VENDORING_GROUP_JUNK, self.GroupJunk:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.SHOW_DETAILED_STATUS, self.ShowDetailedStatus:GetChecked())

  Journalator.Config.Get(Journalator.Config.Options.MINIMAP_ICON).hide = not self.ShowMinimapIcon:GetChecked()
  Journalator.MinimapIcon.UpdateShown()

  Journalator.Config.Set(Journalator.Config.Options.DEBUG, self.DebugMode:GetChecked())
end

function JournalatorConfigBasicOptionsFrameMixin:ComputeFullStatisticsClicked()
  Journalator.Archiving.LoadUpTo(0, function()
    Journalator.Statistics.ComputeFullCache()
    Journalator.Utilities.Message(JOURNALATOR_L_FINISHED_COMPUTING_STATISTICS)
  end)
end


function JournalatorConfigBasicOptionsFrameMixin:Cancel()

end
