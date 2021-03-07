JournalatorTabButtonMixin = {}

function JournalatorTabButtonMixin:OnShow()
  PanelTemplates_TabResize(self, 50, nil, 20)
  PanelTemplates_DeselectTab(self)
end

function JournalatorTabButtonMixin:OnClick()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
  CallMethodOnNearestAncestor(self, "SetDisplayMode", self.displayMode)
end
