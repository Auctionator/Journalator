Journalator.Config.Options = {
  TOOLTIP_SALE_RATE = "tooltip_sale_rate",
  TOOLTIP_FAILURES = "tooltip_failures",
  TOOLTIP_LAST_SOLD = "tooltip_last_sold",
  TOOLTIP_LAST_BOUGHT = "tooltip_last_bought",

  VENDORING_GROUP_JUNK = "vendoring_group_junk",
  MINIMAP_ICON = "minimap_icon",

  SHOW_DETAILED_STATUS = "show_detailed_status",

  DEBUG = "debug",
}

Journalator.Config.Defaults = {
  [Journalator.Config.Options.TOOLTIP_SALE_RATE] = false,
  [Journalator.Config.Options.TOOLTIP_FAILURES] = false,
  [Journalator.Config.Options.TOOLTIP_LAST_SOLD] = true,
  [Journalator.Config.Options.TOOLTIP_LAST_BOUGHT] = true,
  [Journalator.Config.Options.VENDORING_GROUP_JUNK] = true,
  [Journalator.Config.Options.MINIMAP_ICON] = { hide = false },
  [Journalator.Config.Options.SHOW_DETAILED_STATUS] = false,
  [Journalator.Config.Options.DEBUG] = false,
}

function Journalator.Config.IsValidOption(name)
  for _, option in pairs(Journalator.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

function Journalator.Config.Create(constant, name, defaultValue)
  Journalator.Config.Options[constant] = name

  Journalator.Config.Defaults[Journalator.Config.Options[constant]] = defaultValue

  if JOURNALATOR_CONFIG ~= nil and JOURNALATOR_CONFIG[name] == nil then
    JOURNALATOR_CONFIG[name] = defaultValue
  end
end

function Journalator.Config.Set(name, value)
  if JOURNALATOR_CONFIG == nil then
    error("JOURNALATOR_CONFIG not initialized")
  elseif not Journalator.Config.IsValidOption(name) then
    error("Invalid option '" .. name .. "'")
  else
    JOURNALATOR_CONFIG[name] = value
  end
end

function Journalator.Config.Reset()
  JOURNALATOR_CONFIG = {}
  for option, value in pairs(Journalator.Config.Defaults) do
    JOURNALATOR_CONFIG[option] = value
  end
end

function Journalator.Config.InitializeData()
  if JOURNALATOR_CONFIG == nil then
    Journalator.Config.Reset()
  else
    for option, value in pairs(Journalator.Config.Defaults) do
      if JOURNALATOR_CONFIG[option] == nil then
        JOURNALATOR_CONFIG[option] = value
      end
    end
  end
end

function Journalator.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if JOURNALATOR_CONFIG == nil then
    return Journalator.Config.Defaults[name]
  else
    return JOURNALATOR_CONFIG[name]
  end
end

function Journalator.Config.Show()
  if Settings ~= nil then -- Dragonflight
    Settings.OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  else
    InterfaceOptionsFrame:Show()
    InterfaceOptionsFrame_OpenToCategory(JOURNALATOR_L_JOURNALATOR)
  end
end
