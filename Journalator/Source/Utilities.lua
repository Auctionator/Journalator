Journalator.Utilities = {}

function Journalator.Utilities.Message(message)
  print(
    INVASION_FONT_COLOR:WrapTextInColorCode("Journalator: ")
    .. message
  )
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
  local currencyMap

  -- Converts from a currency name to the currency id. Assumes that the currency is
  -- in the player's currencies listing.
  function Journalator.Utilities.GetCurrencyID(currencyName)
    if C_CurrencyInfo == nil then
      return nil
    end

    if currencyMap == nil or currencyMap[currencyName] == nil then
      currencyMap = {}

      local index = 0
      while index < C_CurrencyInfo.GetCurrencyListSize() do
        index = index + 1
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info.isHeader then
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        else
          local link = C_CurrencyInfo.GetCurrencyListLink(index)
          if link ~= nil then
            currencyMap[info.name] = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          end
        end
      end
    end

    return currencyMap[currencyName]
  end
end

do
  local tooltip

  function Journalator.GetTooltipFirstLine(link)
    if not tooltip then
      tooltip = CreateFrame("GameTooltip", "JournalatorFirstLineScanningTooltip", nil, "GameTooltipTemplate")
    end

    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
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

  function Journalator.Utilities.GetNPCNameFromGUID(guid, callback)
    if not frame then
      frame = CreateFrame("Frame", nil, UIParent)
    end

    local link = "unit:" .. guid
    callbacks[link] = callbacks[link] or {}
    table.insert(callbacks[link], callback)

    frame:SetScript("OnUpdate", Check)
  end
end

-- Necessary workaround as Wrath and Classic Era do not have
-- C_Item.GetItemLocation
function Journalator.Utilities.GetItemLocationFromGUID(wantedItemGUID)
  local function NumSlots(bagID)
    if C_Container and C_Container.GetContainerNumSlots then
      return C_Container.GetContainerNumSlots(bagID)
    else
      return GetContainerNumSlots(bagID)
    end
  end

  for _, bagID in ipairs(Auctionator.Constants.BagIDs) do
    for slot = 1, NumSlots(bagID) do
      local location = ItemLocation:CreateFromBagAndSlot(bagID, slot)
      if C_Item.DoesItemExist(location) then
        local itemGUID = C_Item.GetItemGUID(location)
        if itemGUID == wantedItemGUID then
          return location
        end
      end
    end
  end

  return nil
end

function Journalator.Utilities.NormalizeRealmName(realmName)
  return realmName:gsub("[ -]", "")
end
