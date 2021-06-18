local function IsAuctionableItem(itemLink)
  local bindType = select(14, GetItemInfo(itemLink))
  return bindType ~= LE_ITEM_BIND_ON_ACQUIRE and bindType ~= LE_ITEM_BIND_QUEST
end

hooksecurefunc(Auctionator.Tooltip, "ShowTipWithPricingDBKey",
  function(tooltipFrame, dbKeys, itemLink, itemCount)
    if #dbKeys == 0 or itemLink == nil or not IsAuctionableItem(itemLink) then
      return
    end

    local itemName = Journalator.Utilities.GetNameFromLink(itemLink)
    local salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)

    if salesRate ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_SALE_RATE, WHITE_FONT_COLOR:WrapTextInColorCode(salesRate))
    end
    if failedCount ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_FAILURES, WHITE_FONT_COLOR:WrapTextInColorCode(failedCount))
    end
    if lastSold ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_LAST_SOLD, WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreatePaddedMoneyString(lastSold)))
    end
    if lastBought ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_LAST_BOUGHT, WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreatePaddedMoneyString(lastBought)))
    end

    tooltipFrame:Show()
end)

local PET_TOOLTIP_SPACING = " "

hooksecurefunc(Auctionator.Tooltip, "AddPetTip",
  function(speciesID)
    local itemName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    local salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)

    if salesRate ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_SALE_RATE .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(salesRate))
    end
    if failedCount ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_FAILURES .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(failedCount))
    end
    if lastSold ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_LAST_SOLD .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreatePaddedMoneyString(lastSold)))
    end
    if lastBought ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_LAST_BOUGHT .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreatePaddedMoneyString(lastBought)))
    end
    BattlePetTooltip:Show()
end)
