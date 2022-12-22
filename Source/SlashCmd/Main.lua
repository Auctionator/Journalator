Journalator.SlashCmd = {}

function Journalator.SlashCmd.Initialize()
  SlashCmdList["Journalator"] = Journalator.SlashCmd.Handler
  SLASH_Journalator1 = "/journalator"
  SLASH_Journalator2 = "/jnr"
end

function Journalator.SlashCmd.Handler(input)
  Journalator.ToggleView()
end
