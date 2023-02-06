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
function Journalator.Utilities.CleanReagents(reagents)
  local result = {}
  for _, item in ipairs(reagents) do
    table.insert(result, {
      itemID = item.itemID,
      quantity = item.quantity,
    })
  end
  return result
end

function Journalator.Utilities.GetChatPattern(chatTextTemplate)
  chatTextTemplate = chatTextTemplate:gsub("(%W)", "%%%1")
  return "^" .. chatTextTemplate:gsub("%%%%s", "(.*)"):gsub("%%%%d", "(.*)") .. "$"
end

function Journalator.Utilities.CleanNumberString(numberString)
  local cleaned = numberString:gsub("%,", ""):gsub("%.", "")
  return tonumber(cleaned)
end

function Journalator.Utilities.MergeReputationChanges(reputationChanges)
  local seen = {}
  for _, change in ipairs(reputationChanges) do
    local factionName = change.factionName
    if seen[factionName] then
      seen[factionName] = seen[factionName] + change.reputationChange
    else
      seen[factionName] = change.reputationChange
    end
  end

  local result = {}
  for factionName, reputationChange in pairs(seen) do
    table.insert(result, {
      factionName = factionName,
      reputationChange = reputationChange,
    })
  end

  table.sort(result, function(a, b)
    return a.factionName < b.factionName
  end)

  return result
end

do
  local factionMap

  -- Converts from a faction name to the faction id. Assumes that the faction is
  -- in the player's reputation listing.
  function Journalator.Utilities.GetFactionID(factionName)
    if factionMap == nil or factionMap[factionName] == nil then
      factionMap = {}
      ExpandAllFactionHeaders()

      for i = 1, GetNumFactions() do
        local factionInfo = {GetFactionInfo(i)}
        local name = factionInfo[1]
        local id = factionInfo[14]
        factionMap[name] = id
      end
    end

    return factionMap[factionName]
  end
end

do
  local tooltip

  function Journalator.GetTooltipFirstLine(link)
    if not tooltip then
      tooltip = CreateFrame("GameTooltip", "JournalatorFirstLineScanningTooltip", UIParent, "GameTooltipTemplate")
    end

    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(link)
    return _G["JournalatorFirstLineScanningTooltipTextLeft1"]:GetText()
  end
end

do
  local frame
  local callbacks = {}
  local function Check()
    for link, list in pairs(callbacks) do
      local name = Journalator.GetTooltipFirstLine(link)
      if name ~= nil then
        for _, c in ipairs(list) do
          c(name)
        end
        callbacks[link] = nil
      end
    end
    if next(callbacks) == nil then
      frame:SetScript("OnUpdate", nil)
    end
  end

  function Journalator.GetNPCNameFromGUID(guid, callback)
    if not frame then
      frame = CreateFrame("Frame", nil, UIParent)
    end

    local link = "unit:" .. guid
    callbacks[link] = callbacks[link] or {}
    table.insert(callbacks[link], callback)

    frame:SetScript("OnUpdate", Check)
  end
end
