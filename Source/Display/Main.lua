JournalatorDisplayMixin = {}

local REFRESH_EVENTS = {
  Journalator.Events.LogsUpdated,
  Journalator.Events.FiltersChanged,
}

function JournalatorDisplayMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")

  PanelTemplates_SetNumTabs(self, #self.Tabs)
  table.insert(UISpecialFrames, self:GetName())

  if Auctionator.Constants.IsClassic then
    self:HideCraftingOrderTabs()
  end

  self:SetupExportCSVDialog()
end

function JournalatorDisplayMixin:OnShow()
  self:SetDisplayMode(self.Tabs[1].displayMode)

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

function JournalatorDisplayMixin:ReceiveEvent(eventName)
  if eventName == Journalator.Events.LogsUpdated then
    Journalator.Debug.Message("JournalatorDisplay", eventName)
    local view = self:GetCurrentDataView()
    if view ~= nil then
      view.DataProvider:Refresh()
      self.Filters:UpdateRealms()
    end
  elseif eventName == Journalator.Events.FiltersChanged and not self.ProgressBar:IsShown() then
    Journalator.Archiving.LoadUpTo(self.Filters:GetTimeForRange(), function()
      self:OnLoadComplete()
    end, function(current, total)
      self:UpdateProgressBar(current, total)
    end)
  end
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

function JournalatorDisplayMixin:SetDisplayMode(displayMode)
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
  end

  self.ExportCSV:SetShown(self:GetCurrentDataView() ~= nil)
  self.StatusText:SetShown(self:GetCurrentDataView() ~= nil)
  self.Filters:SetShown(self:GetCurrentDataView() ~= nil)
end

function JournalatorDisplayMixin:HideCraftingOrderTabs()
  local startTab = self.CraftingOrdersPlacedTab
  local endTab = self.FulfillingTab
  local endTabIndex = tIndexOf(self.Tabs, endTab)

  local nextTab = self.Tabs[endTabIndex + 1]
  nextTab:ClearAllPoints()
  nextTab:SetPoint(startTab:GetPoint(1))

  self.FulfillingTab:Hide()
end

function JournalatorDisplayMixin:SetupExportCSVDialog()
  self.exportCSVDialog = CreateFrame("Frame", "JournalatorExportCSVTextFrame", self, "AuctionatorExportTextFrame")
  self.exportCSVDialog:SetPoint("CENTER")
end

function JournalatorDisplayMixin:GetCurrentDataView()
  for _, view in ipairs(self.Views) do
    if view:IsShown() and view.DataProvider ~= nil then
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
