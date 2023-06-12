JournalatorTabbedViewMixin = {}

function JournalatorTabbedViewMixin:OnLoad()
  local lastTab = nil
  for index, tab in ipairs(self.Tabs) do
    tab:ClearAllPoints()
    if lastTab == nil then
      tab:SetPoint("BOTTOMLEFT", 20, 8)
    else
      tab:SetPoint("LEFT", lastTab, "RIGHT", -15, 0)
    end
    lastTab = tab
  end
  self.Filters = self:GetParent().Filters

  PanelTemplates_SetNumTabs(self, #self.Tabs)
end

function JournalatorTabbedViewMixin:OnShow()
  for index, view in ipairs(self.Views) do
    if view:IsVisible() then
      PanelTemplates_SetTab(self, index)
      break
    end
  end
end

function JournalatorTabbedViewMixin:GetCurrentDataView()
  for _, view in ipairs(self.Views) do
    if view:IsShown() and view.DataProvider ~= nil then
      return view
    end
  end
end

function JournalatorTabbedViewMixin:HasDisplayMode(displayMode)
  for index, tab in ipairs(self.Tabs) do
    if tab.displayMode == displayMode then
      return true
    end
  end
  return false
end

function JournalatorTabbedViewMixin:SetDisplayMode(displayMode)
  for index, tab in ipairs(self.Tabs) do
    if tab.displayMode == displayMode then
      PanelTemplates_SetTab(self, index)
      if self:GetParent().SetTitle then -- Dragonflight
        self:GetParent():SetTitle(tab.title)
      else
        self:GetParent().TitleText:SetText(tab.title)
      end
      break
    end
  end

  for _, view in ipairs(self.Views) do
    view:SetShown(view.displayMode == displayMode)
  end
end
