local function InitializeBase()
  Journalator.MinimapIcon.Initialize()

  Journalator.CacheIgnoredCharacters()

  Journalator.ToggleView = function()
    if JNRView == nil then
      CreateFrame("Frame", "JNRView", UIParent, "JournalatorDisplayTemplate")
    end

    JNRView:SetShown(not JNRView:IsShown())
  end

  Journalator_CompartmentButton = function(addonName, button)
    if button == "RightButton" then
      Journalator.Config.Show()
    else
      Journalator.ToggleView()
    end
  end
end

local CORE_EVENTS = {
  "ADDON_LOADED",
}
local coreFrame = CreateFrame("Frame")

FrameUtil.RegisterFrameForEvents(coreFrame, CORE_EVENTS)
coreFrame:SetScript("OnEvent", function(self, eventName, name)
  if eventName == "ADDON_LOADED" and name == "Journalator_Display" then
    self:UnregisterEvent("ADDON_LOADED")
    InitializeBase()
  end
end)
