JournalatorDisplayMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

function JournalatorDisplayMixin:OnCloseClicked()
  self:Hide()
end

function JournalatorDisplayMixin:OnLoad()
  PanelTemplates_SetNumTabs(self, #self.Tabs)
end

function JournalatorDisplayMixin:OnShow()
  self:SetDisplayMode(self.Tabs[1].displayMode)
end

function JournalatorDisplayMixin:SetDisplayMode(displayMode)
  for index, tab in ipairs(self.Tabs) do
    if tab.displayMode == displayMode then
      PanelTemplates_SetTab(self, index)
    end
  end

  for _, view in ipairs(self.Views) do
    view:SetShown(view.displayMode == displayMode)
  end
end
