local CORE_EVENTS = {
  "ADDON_LOADED"
}
JournalatorLDBCoreMixin = {}

function JournalatorLDBCoreMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, CORE_EVENTS)
end

function JournalatorLDBCoreMixin:OnEvent(eventName, name)
  if eventName == "ADDON_LOADED" and name == "Journalator-LDB" then
    FrameUtil:UnregisterFrameForEvents(self, CORE_EVENTS)
    Journalator_LDB_Initialize()
  end
end
