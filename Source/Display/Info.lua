JournalatorInfoDisplayMixin = {}

function JournalatorInfoDisplayMixin:OnShow()
end

function JournalatorInfoDisplayMixin:OpenOptions()
  InterfaceOptionsFrame:Show()
  InterfaceOptionsFrame_OpenToCategory(JOURNALATOR_L_JOURNALATOR)
end
