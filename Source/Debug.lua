function Journalator.Debug.IsOn()
  return Journalator.Config.Get(Journalator.Config.Options.DEBUG)
end

function Journalator.Debug.Toggle()
  Journalator.Config.Set(Journalator.Config.Options.DEBUG,
    not Journalator.Config.Get(Journalator.Config.Options.DEBUG))
end

function Journalator.Debug.Message(message, ...)
  if Journalator.Debug.IsOn() then
    print(GREEN_FONT_COLOR:WrapTextInColorCode(message), ...)
  end
end
