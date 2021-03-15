JournalatorDisplayMixin = {}

function JournalatorDisplayMixin:OnLoad()
  PanelTemplates_SetNumTabs(self, #self.Tabs)
  table.insert(UISpecialFrames, self:GetName())

  self:SetupExportCSVDialog()
end

function JournalatorDisplayMixin:OnShow()
  self:SetDisplayMode(self.Tabs[1].displayMode)
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

function JournalatorDisplayMixin:RefreshButtonClicked()
  local view = self:GetCurrentDataView()

  if view ~= nil then
    view.DataProvider:Refresh()
  end
end
