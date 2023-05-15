local function IsAuctionableItem(itemLink)
  local bindType = select(14, GetItemInfo(itemLink))
  return bindType ~= LE_ITEM_BIND_ON_ACQUIRE and bindType ~= LE_ITEM_BIND_QUEST
end

local function ColorMoney(moneyString)
  return WHITE_FONT_COLOR:WrapTextInColorCode(moneyString)
end

hooksecurefunc(Auctionator.Tooltip, "ShowTipWithPricingDBKey",
  function(tooltipFrame, dbKeys, itemLink, itemCount)
    if not Journalator.Tooltips.AnyEnabled() or #dbKeys == 0 or itemLink == nil or not IsAuctionableItem(itemLink) then
      return
    end

    local itemName = GetItemInfo(itemLink)

    if itemName == nil then
      return
    end

    local salesRate, failedCount, lastSold, lastBought, boughtStats, soldStats = Journalator.Tooltips.GetSalesInfo(itemName, itemLink)

    if salesRate ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_SALE_RATE, WHITE_FONT_COLOR:WrapTextInColorCode(salesRate))
    end
    if failedCount ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_FAILURES, WHITE_FONT_COLOR:WrapTextInColorCode(failedCount))
    end
    if lastSold ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_LAST_SOLD, ColorMoney(Auctionator.Utilities.CreatePaddedMoneyString(lastSold)))
    end
    if lastBought ~= nil then
      tooltipFrame:AddDoubleLine(JOURNALATOR_L_LAST_BOUGHT, ColorMoney(Auctionator.Utilities.CreatePaddedMoneyString(lastBought)))
    end
    if boughtStats ~= nil then
      tooltipFrame:AddLine(JOURNALATOR_L_BOUGHT_MIN_MAX_MEAN:format(ColorMoney(GetMoneyString(boughtStats.min, true)), ColorMoney(GetMoneyString(boughtStats.max)), ColorMoney(GetMoneyString(boughtStats.mean))))
    end
    if soldStats ~= nil then
      tooltipFrame:AddLine(JOURNALATOR_L_SOLD_MIN_MAX_MEAN:format(ColorMoney(GetMoneyString(soldStats.min, true)), ColorMoney(GetMoneyString(soldStats.max)), ColorMoney(GetMoneyString(soldStats.mean))))
    end

    tooltipFrame:Show()
end)

local PET_TOOLTIP_SPACING = " "

hooksecurefunc(Auctionator.Tooltip, "AddPetTip",
  function(speciesID)
    if not Journalator.Tooltips.AnyEnabled() then
      return
    end

    local itemName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)

    if itemName == nil then
      return
    end

    local salesRate, failedCount, lastSold, lastBought, boughtStats, soldStats = Journalator.Tooltips.GetSalesInfo(itemName)

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
    if boughtStats ~= nil then
      BattlePetTooltip:AddLine(JOURNALATOR_L_BOUGHT_MIN_MAX_MEAN:format(ColorMoney(GetMoneyString(boughtStats.min, true)), ColorMoney(GetMoneyString(boughtStats.max)), ColorMoney(GetMoneyString(boughtStats.mean))))
    end
    if soldStats ~= nil then
     BattlePetTooltip:AddLine(JOURNALATOR_L_SOLD_MIN_MAX_MEAN:format(ColorMoney(GetMoneyString(soldStats.min, true)), ColorMoney(GetMoneyString(soldStats.max)), ColorMoney(GetMoneyString(soldStats.mean))))
    end
end)
