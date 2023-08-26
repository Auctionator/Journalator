function Journalator.CacheIgnoredCharacters()
  Journalator.State.IgnoredTransferCharacters = {}

  local ignoreList = Journalator.Config.Get(Journalator.Config.Options.IGNORE_TRANSFERS)

  for _, char in ipairs(ignoreList) do
    Journalator.State.IgnoredTransferCharacters[char.character .. "-" .. (Journalator.Utilities.NormalizeRealmName(char.realm))] = true
  end
end

function Journalator.CheckCharacter(playerName, source)
  if next(Journalator.State.IgnoredTransferCharacters) == nil then
    return true
  else
    return Journalator.State.IgnoredTransferCharacters[Journalator.Utilities.GetIgnoredCharacterCheckString(playerName, source)] ~= true
  end
end
