hooksecurefunc(Auctionator.Tooltip, "ShowTipWithPricingDBKey",
  function(tooltipFrame, dbKeys, itemLink, itemCount)
    if #dbKeys == 0 or itemLink == nil then
      return
    end

    local bindType = select(14, GetItemInfo(itemLink))
    if bindType == LE_ITEM_BIND_ON_ACQUIRE or bindType == LE_ITEM_BIND_QUEST then
      return
    end

    local itemName = Journalator.Utilities.GetNameFromLink(itemLink)
    local salesRate, failedCount = Journalator.Tooltips.GetSalesInfo(itemName)

    if salesRate ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_SALE_RATE, WHITE_FONT_COLOR:WrapTextInColorCode(salesRate))
    end
    if failedCount ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_FAILURES, WHITE_FONT_COLOR:WrapTextInColorCode(failedCount))
    end

    tooltipFrame:Show()
end)

PET_TOOLTIP_SPACING = " "

hooksecurefunc(Auctionator.Tooltip, "AddPetTip",
  function(speciesID)
    local itemName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    local salesRate, failedCount = Journalator.Tooltips.GetSalesInfo(itemName)

    if salesRate ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_SALE_RATE .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(salesRate))
    end
    if failedCount ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_FAILURES .. PET_TOOLTIP_SPACING .. WHITE_FONT_COLOR:WrapTextInColorCode(failedCount))
    end
    BattlePetTooltip:Show()
end)
