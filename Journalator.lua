local CORE_EVENTS = {
  "ADDON_LOADED"
}
JournalatorCoreMixin = {}

function JournalatorCoreMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, CORE_EVENTS)
end

function JournalatorCoreMixin:OnEvent(eventName, name)
  if eventName == "ADDON_LOADED" and name == "Journalator" then
    Journalator.Initialize()
  end
end
