JournalatorLogViewResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function JournalatorLogViewResultsRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  if self.rowData.itemLink then
    if string.match(self.rowData.itemLink, "battlepet") then
      BattlePetToolTip_ShowLink(self.rowData.itemLink)
    else
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink(self.rowData.itemLink)
      GameTooltip:Show()
    end

  elseif self.rowData.itemKey then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemKey(self.rowData.itemKey.itemID, self.rowData.itemKey.itemSuffix, 0, self.rowData.battlePetSpeciesID)
    GameTooltip:Show()
  end
end

function JournalatorLogViewResultsRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)

  if self.rowData.itemLink and string.match(self.rowData.itemLink, "battlepet") then
    BattlePetTooltip:Hide()
  elseif self.rowData.itemLink then
    GameTooltip:Hide()
  end
end
