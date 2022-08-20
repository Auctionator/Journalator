Journalator.Utilities = {}

function Journalator.ApplyQualityColor(name, link)
  return "|c" .. Auctionator.Utilities.GetQualityColorFromLink(link) .. name .. "|r"
end

function Journalator.Utilities.PrettyPercentage(value)
  return tostring(math.floor(value)) .. "%"
end

function Journalator.Utilities.GetSortedKeys(a)
  local result = {}

  for key, _ in pairs(a) do
    table.insert(result, key)
  end
  table.sort(result)

  return result
end

function Journalator.Utilities.AddRealmToPlayerName(playerName, source)
  if playerName == nil then
    return nil
  end

  if source.realm ~= Journalator.State.Source.realm and not string.match(playerName, "-") then
    return playerName .. "-" .. string.gsub(source.realm, "[ -]", "")
  else
    return playerName
  end
end

function Journalator.Utilities.Message(message)
  print(
    INVASION_FONT_COLOR:WrapTextInColorCode("Journalator: ")
    .. message
  )
end
