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

  self:SetupExportCSVDialog()
end

function JournalatorDisplayMixin:OnShow()
  self:SetDisplayMode(self.Tabs[1].displayMode)
  self:SetProfitText()

  Auctionator.EventBus:Register(self, REFRESH_EVENTS)

  Journalator.Archiving.LoadAll(function()
    self.ProgressBar:Hide()
    local view = self:GetCurrentDataView()
    if view ~= nil then
      Journalator.GetItemInfo_MapFullLinks()
      view.DataProvider:Refresh()
    end
  end, function(current, total)
    self.ProgressBar:SetMinMaxValues(0, total)
    self.ProgressBar:SetValue(current)
    self.ProgressBar.Text:SetFormattedText(JOURNALATOR_L_LOADING_X_X, current, total)
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
  elseif eventName == Journalator.Events.FiltersChanged then
    self:SetProfitText()
  end
end

function JournalatorDisplayMixin:SetProfitText()
  if Journalator.Config.Get(Journalator.Config.Options.SHOW_DETAILED_STATUS) then
    local sales, purchases, lostFees, lostDeposits, total = Journalator.GetDetailedProfits(self.Filters:GetTimeForRange(), time(), function(item)
      return self.Filters:Filter(item)
    end)

    local totalString
    if total < 0 then
      totalString = "-" .. RED_FONT_COLOR:WrapTextInColorCode(GetMoneyString(-total, true))
    else
      totalString = GetMoneyString(total, true)
    end

    self.StatusText:SetText(JOURNALATOR_L_DETAILED_STATUS:format(
      GetMoneyString(sales, true),
      RED_FONT_COLOR:WrapTextInColorCode(GetMoneyString(lostFees, true)),
      RED_FONT_COLOR:WrapTextInColorCode(GetMoneyString(lostDeposits, true)),
      RED_FONT_COLOR:WrapTextInColorCode(GetMoneyString(purchases, true)),
      totalString
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
      self.TitleText:SetText(tab.title)
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
