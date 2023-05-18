function Journalator.Config.Show()
  if Settings and SettingsPanel then
    Settings.OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  elseif InterfaceOptionsFrame ~= nil then
    InterfaceOptionsFrame:Show()
    InterfaceOptionsFrame_OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  end
end
