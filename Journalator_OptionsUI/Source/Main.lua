function Journalator.Config.Show()
  if InterfaceOptionsFrame ~= nil then
    InterfaceOptionsFrame:Show()
    InterfaceOptionsFrame_OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  else
    Settings.OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  end
end
