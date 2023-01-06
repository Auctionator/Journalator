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

function Journalator.Utilities.NormalizeRealmName(realmName)
  return realmName:gsub("[ -]", "")
end

function Journalator.Utilities.GetRealmNames()
  local connected = GetAutoCompleteRealms()
  if #connected > 0 then
    return connected
  else
    return { GetNormalizedRealmName() }
  end
end

function Journalator.Utilities.AddQualityIconToItemName(itemName, itemLink)
  if C_TradeSkillUI == nil or C_TradeSkillUI.GetItemReagentQualityByItemInfo == nil then
    return itemName
  end

  local itemID = GetItemInfoInstant(itemLink)
  if itemID == nil then -- pets won't have an item id from the link
    return itemName
  end

  local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)
  if quality ~= nil then
    local icon = C_Texture.GetCraftingReagentQualityChatIcon(quality)
    return AUCTION_HOUSE_CRAFTING_REAGANT_QUALITY_FORMAT:format(itemName, icon)
  else
    return itemName
  end
end

-- Removes slotID field from reagents entries
function Journalator.Utilities.CleanReagents(basicReagents, specialReagents)
  local result = {}
  for _, item in ipairs(basicReagents) do
    table.insert(result, {
      itemID = item.itemID,
      quantity = item.quantity,
    })
  end
  for _, item in ipairs(specialReagents) do
    table.insert(result, {
      itemID = item.itemID,
      quantity = item.quantity,
    })
  end
  return result
end
