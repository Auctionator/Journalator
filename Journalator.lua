local CORE_EVENTS = {
  "ADDON_LOADED",
  "PLAYER_ENTERING_WORLD",
}
JournalatorCoreMixin = {}

function JournalatorCoreMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, CORE_EVENTS)
end

function JournalatorCoreMixin:OnEvent(eventName, name)
  if eventName == "ADDON_LOADED" and name == "Journalator" then
    self:UnregisterEvent("ADDON_LOADED")
    Journalator.InitializeBase()
  elseif eventName == "PLAYER_ENTERING_WORLD" then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    Journalator.InitializeMonitoring()
  end
end
