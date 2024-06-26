JournalatorDisplayMixin = {}

local REFRESH_EVENTS = {
  Journalator.Events.LogsUpdated,
  Journalator.Events.FiltersChanged,
  Journalator.Events.AddValueForTotal,
  Journalator.Events.RemoveValueFromTotal,
  Journalator.Events.RequestTabSwitch,
  Journalator.Events.UpdateTotalQuantity,
  Journalator.Events.ClearTotalQuantity,
}

function JournalatorDisplayMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  if TSM_API then
    self:SetFrameStrata("HIGH")
  end

  self:RegisterForDrag("LeftButton")

  PanelTemplates_SetNumTabs(self, #self.Tabs)
  table.insert(UISpecialFrames, self:GetName())
  self:ResetRunningTotal()

  self:HideTabs()

  self:SetupExportCSVDialog()
end

function JournalatorDisplayMixin:OnShow()
  local visibleDisplayModes = {}
  local visibleTab
  for _, tab in ipairs(self.Tabs) do
    if tab:IsShown() then
      table.insert(visibleDisplayModes, tab.displayMode)
      if visibleTab == nil  then
        visibleTab = tab
      end
    end
  end

  self:SetTabFromDetails(Journalator.Config.Get(Journalator.Config.Options.DEFAULT_TAB))

  Auctionator.EventBus:Register(self, REFRESH_EVENTS)

  Journalator.Archiving.LoadUpTo(self.Filters:GetTimeForRange(), function()
    self:OnLoadComplete()
    local view = self:GetCurrentDataView()
    if view ~= nil then
      view.DataProvider:Refresh()
    end
  end, function(current, total)
    self:UpdateProgressBar(current, total)
  end)
end

function JournalatorDisplayMixin:OnHide()
  Auctionator.EventBus:Unregister(self, REFRESH_EVENTS)
end

function JournalatorDisplayMixin:ReceiveEvent(eventName, ...)
  if eventName == Journalator.Events.LogsUpdated then
    Journalator.Debug.Message("JournalatorDisplay", eventName)

    self:ResetRunningTotal()

    local view = self:GetCurrentDataView()
    if view ~= nil then
      view.DataProvider:Refresh()
      self.Filters:UpdateRealmsAndCharacters()
    end
  elseif eventName == Journalator.Events.FiltersChanged and not self.ProgressBar:IsShown() then
    Journalator.Archiving.LoadUpTo(self.Filters:GetTimeForRange(), function()
      self:OnLoadComplete()
    end, function(current, total)
      self:UpdateProgressBar(current, total)
    end)

  elseif eventName == Journalator.Events.AddValueForTotal then
    local value = ...
    self.runningTotal = self.runningTotal + value
    self.runningTotalValueCount = self.runningTotalValueCount + 1
    self:UpdateRunningTotal()

  elseif eventName == Journalator.Events.RemoveValueFromTotal then
    local value = ...
    self.runningTotal = self.runningTotal - value
    self.runningTotalValueCount = self.runningTotalValueCount - 1
    self:UpdateRunningTotal()
  elseif eventName == Journalator.Events.RequestTabSwitch then
    local details = ...
    self:SetTabFromDetails(details)
  elseif eventName == Journalator.Events.ClearTotalQuantity then
    self.TotalQuantity:SetText("")
  elseif eventName == Journalator.Events.UpdateTotalQuantity then
    self.TotalQuantity:SetText(JOURNALATOR_L_TOTAL_QUANTITY_X:format(...))
  end
end

function JournalatorDisplayMixin:SetTabFromDetails(details)
  self:SetDisplayMode(details.root, details.child)
end

function JournalatorDisplayMixin:OnLoadComplete()
  self.ProgressBar:Hide()
  self:SetProfitText()
end

function JournalatorDisplayMixin:UpdateProgressBar(current, total)
  self.ProgressBar:Show()
  self.ProgressBar:SetMinMaxValues(0, total)
  self.ProgressBar:SetValue(current)
  self.ProgressBar.Text:SetFormattedText(JOURNALATOR_L_LOADING_X_X, current, total)
end

local function ApplyNegativeToMoneyString(amount)
  if amount < 0 then
    return RED_FONT_COLOR:WrapTextInColorCode("-" .. GetMoneyString(-amount, true))
  else
    return GetMoneyString(amount, true)
  end
end

function JournalatorDisplayMixin:SetProfitText()
  if Journalator.Config.Get(Journalator.Config.Options.SHOW_DETAILED_STATUS) then
    local sales, purchases, lostFees, lostDeposits, total = Journalator.GetDetailedProfits(self.Filters:GetTimeForRange(), time(), function(item)
      return self.Filters:Filter(item)
    end)

    self.StatusText:SetText(JOURNALATOR_L_DETAILED_STATUS:format(
      ApplyNegativeToMoneyString(sales),
      ApplyNegativeToMoneyString(-lostFees),
      ApplyNegativeToMoneyString(-lostDeposits),
      ApplyNegativeToMoneyString(-purchases),
      ApplyNegativeToMoneyString(total)
    ))
  else
    local monthlyTotal, incoming, outgoing = Journalator.GetProfit(self.Filters:GetTimeForRange(), time(), function(item)
      return self.Filters:Filter(item)
    end)
    if monthlyTotal < 0 then
      self.StatusText:SetText(JOURNALATOR_L_YOU_LOST_X_WITH_XX:format(
        GetMoneyString(-monthlyTotal, true),
        GetMoneyString(incoming, true),
        GetMoneyString(outgoing, true)
      ))
    else
      self.StatusText:SetText(JOURNALATOR_L_YOU_GAINED_X_WITH_XX:format(
        GetMoneyString(monthlyTotal, true),
        GetMoneyString(incoming, true),
        GetMoneyString(outgoing, true)
      ))
    end
  end
end

function JournalatorDisplayMixin:ResetRunningTotal()
  self.runningTotal = 0
  self.runningTotalValueCount = 0
  self:UpdateRunningTotal()
  Auctionator.EventBus
    :RegisterSource(self, "JournalatorDisplay")
    :Fire(self, Journalator.Events.ResetTotal)
    :UnregisterSource(self)
end

function JournalatorDisplayMixin:UpdateRunningTotal()
  if self.runningTotalValueCount == 0 then
    self.RunningTotalButton:SetText("")
    self.TotalQuantity:Show()
  else
    self.TotalQuantity:Hide()
    self.RunningTotalButton:SetText(JOURNALATOR_L_RUNNING_TOTAL_X:format(ApplyNegativeToMoneyString(self.runningTotal)))
  end
  self.RunningTotalButton:SetWidth(self.RunningTotalButton:GetTextWidth())
end

function JournalatorDisplayMixin:SetDisplayMode(displayMode, childMode)
  self.exportCSVDialog:Hide()

  for index, tab in ipairs(self.Tabs) do
    if tab.displayMode == displayMode then
      PanelTemplates_SetTab(self, index)
      if self.SetTitle then -- Dragonflight
        self:SetTitle(tab.title)
      else
        self.TitleText:SetText(tab.title)
      end
      break
    end
  end

  for _, view in ipairs(self.Views) do
    view:SetShown(view.displayMode == displayMode)

    if view:IsShown() and view.SetDisplayMode then
      if childMode == nil or childMode == "" or not view:HasDisplayMode(childMode) then
        view:SetDisplayMode(view.Tabs[1].displayMode)
      else
        view:SetDisplayMode(childMode)
      end
    end
  end

  self.ExportCSV:SetShown(self:GetCurrentDataView() ~= nil)
  self.StatusText:SetShown(self:GetCurrentDataView() ~= nil)
  self.RunningTotalButton:SetShown(self:GetCurrentDataView() ~= nil)
  self.Filters:SetShown(self:GetCurrentDataView() ~= nil)
end

function JournalatorDisplayMixin:HideTabs()
  self.AuctionHouseTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_AUCTION_HOUSE))
  self.AuctionHouseContainer.WoWTokensTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_WOW_TOKENS) and C_WowTokenPublic.GetCommerceSystemStatus())

  self.VendoringTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_VENDORING))
  self.VendorsContainer.TradingPostTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_TRADING_POST) and not Auctionator.Constants.IsClassic)

  self.CraftingOrdersTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_CRAFTING_ORDERS) and not Auctionator.Constants.IsClassic)


  self.QuestingTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_QUESTING))

  self.LootingTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_LOOTING))

  self.BasicMailTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_LOOTING))

  self.TradesTab:SetShown(Journalator.Config.Get(Journalator.Config.Options.MONITOR_TRADES))

  self.Tabs = tFilter(self.Tabs, function(tab) return tab:IsShown() end, true)

  local lastTab = nil
  for index, tab in ipairs(self.Tabs) do
    tab:ClearAllPoints()
    if lastTab == nil then
      tab:SetPoint("BOTTOMLEFT", 20, -30)
    else
      tab:SetPoint("LEFT", lastTab, "RIGHT", -15, 0)
    end
    lastTab = tab
  end

  PanelTemplates_SetNumTabs(self, #self.Tabs)
end

function JournalatorDisplayMixin:SetupExportCSVDialog()
  self.exportCSVDialog = CreateFrame("Frame", "JournalatorExportCSVTextFrame", self, "AuctionatorExportTextFrame")
  self.exportCSVDialog:SetPoint("CENTER")
end

function JournalatorDisplayMixin:GetCurrentDataView()
  for _, view in ipairs(self.Views) do
    if view:IsShown() then
      if view.DataProvider ~= nil then
        return view
      elseif view.Views then
        return view:GetCurrentDataView()
      end
    end
  end
end

function JournalatorDisplayMixin:GetCurrentView()
  for _, view in ipairs(self.Views) do
    if view:IsShown() then
      return view
    end
  end
end

function JournalatorDisplayMixin:ExportCSVClicked()
  local view = self:GetCurrentDataView()

  if view ~= nil then
    view.DataProvider:GetCSV(function(result)
      self.exportCSVDialog:SetExportString(result)
      self.exportCSVDialog:Show()
    end)
  end
end
