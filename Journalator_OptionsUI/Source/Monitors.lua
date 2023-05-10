JournalatorConfigMonitorsOptionsFrameMixin = {}

function JournalatorConfigMonitorsOptionsFrameMixin:OnLoad()
  self:SetParent(SettingsPanel or InterfaceOptionsFrame)
  self.name = JOURNALATOR_L_CONFIG_MONITORS
  self.parent = JOURNALATOR_L_JOURNALATOR

  self:Show()

  self.cancel = function()
    self:Cancel()
  end

  self.okay = function()
    self:Save()
  end

  InterfaceOptions_AddCategory(self, JOURNALATOR_L_JOURNALATOR)

  -- Hide options that don't apply to classic
  if Auctionator.Constants.IsClassic then
    self.CraftingOrders:Hide()
    self.TradingPost:Hide()
    self.Questing:SetPoint("TOPLEFT", self.Vendoring, "BOTTOMLEFT")
    self.WoWTokens:Hide()
  end
end

function JournalatorConfigMonitorsOptionsFrameMixin:OnShow()
  -- auction house
  self.AuctionHouse:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_AUCTION_HOUSE))
  -- vendors
  self.Vendoring:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_VENDORING))
  -- crafting orders
  self.CraftingOrders:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_CRAFTING_ORDERS))
  -- trading post
  self.TradingPost:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_TRADING_POST))
  -- quest rewards
  self.Questing:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_QUESTING))
  -- looting/loot containers
  self.Looting:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_LOOTING))
  -- purchasing wow tokens for gold
  self.WoWTokens:SetChecked(Journalator.Config.Get(Journalator.Config.Options.MONITOR_WOW_TOKENS))
end

function JournalatorConfigMonitorsOptionsFrameMixin:Save()
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_AUCTION_HOUSE, self.AuctionHouse:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_VENDORING, self.Vendoring:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_CRAFTING_ORDERS, self.CraftingOrders:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_TRADING_POST, self.TradingPost:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_QUESTING, self.Questing:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_LOOTING, self.Looting:GetChecked())
  Journalator.Config.Set(Journalator.Config.Options.MONITOR_WOW_TOKENS, self.WoWTokens:GetChecked())
end

function JournalatorConfigMonitorsOptionsFrameMixin:Cancel()

end
