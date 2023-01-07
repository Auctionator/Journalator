JournalatorLogViewCraftingOrdersRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local lightBlue = CreateColor(116/255, 236/255, 252/255)
function JournalatorLogViewCraftingOrdersRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter
  if self.rowData.itemLink then
    GameTooltip:SetHyperlink(self.rowData.itemLink)
  end
  GameTooltip:AddLine(" ")
  if self.rowData.customerReagents or self.rowData.crafterReagents then
    if self.rowData.customerReagents and #self.rowData.customerReagents > 0 then
      GameTooltip:AddLine(lightBlue:WrapTextInColorCode(JOURNALATOR_L_CUSTOMER_REAGENTS_COLON))
      for _, reagent in ipairs(self.rowData.customerReagents) do
        local _, link = GetItemInfo(reagent.itemID)
        if link ~= nil then
          GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.GetNameFromLink(link)) .. Auctionator.Utilities.CreateCountString(reagent.quantity))
        end
      end
    elseif self.rowData.customerReagents then
      GameTooltip:AddLine(lightBlue:WrapTextInColorCode(JOURNALATOR_L_NO_CUSTOMER_REAGENTS))
    else
      GameTooltip:AddLine(JOURNALATOR_L_NO_RECORDS_CUSTOMER_REAGENTS)
    end
    GameTooltip:AddLine(" ")

    if self.rowData.crafterReagents and #self.rowData.crafterReagents > 0 then
      GameTooltip:AddLine(lightBlue:WrapTextInColorCode(JOURNALATOR_L_CRAFTER_REAGENTS_COLON))
      for _, reagent in ipairs(self.rowData.crafterReagents) do
        local _, link = GetItemInfo(reagent.itemID)
        if link ~= nil then
          GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.GetNameFromLink(link)) .. Auctionator.Utilities.CreateCountString(reagent.quantity))
        end
      end
    elseif self.rowData.crafterReagents then
      GameTooltip:AddLine(lightBlue:WrapTextInColorCode(JOURNALATOR_L_NO_CRAFTER_REAGENTS))
    else
      GameTooltip:AddLine(JOURNALATOR_L_NO_RECORDS_CRAFTER_REAGENTS)
    end
  else
    GameTooltip:AddLine(JOURNALATOR_L_NO_RECORDS_FOR_REAGENTS)
  end
  GameTooltip:Show()
end

function JournalatorLogViewCraftingOrdersRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  GameTooltip:Hide()
end

function JournalatorLogViewCraftingOrdersRowMixin:OnClick(button)
  if button == "LeftButton" then
    if IsModifiedClick("CHATLINK") then
      if self.rowData.itemLink ~= nil then
        ChatEdit_InsertLink(self.rowData.itemLink)
      end
    else
      Auctionator.EventBus
        :RegisterSource(self, "JournalatorLogViewCraftingOrdersRowMixin")
        :Fire(self, Journalator.Events.RowClicked, self.rowData)
        :UnregisterSource(self)
    end
  end
end
