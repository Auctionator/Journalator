function Journalator.CacheIgnoredCharacters()
  Journalator.State.IgnoredTransferCharacters = {}

  local ignoreList = Journalator.Config.Get(Journalator.Config.Options.IGNORE_TRANSFERS)

  for _, char in ipairs(ignoreList) do
    local realm = Journalator.Utilities.NormalizeRealmName(char.realm)
    -- Workaround to hide by character name if the character is missing realm
    -- data in the logs and is of the form CharName (*).
    if realm ~= "" then
      Journalator.State.IgnoredTransferCharacters[char.character .. "-" .. realm] = true
    else
      Journalator.State.IgnoredTransferCharacters[char.character] = true
    end
  end
end

function Journalator.CheckCharacter(playerName, source)
  if next(Journalator.State.IgnoredTransferCharacters) == nil then
    return true
  else
    return Journalator.State.IgnoredTransferCharacters[Journalator.Utilities.GetIgnoredCharacterCheckString(playerName, source)] ~= true
  end
end
