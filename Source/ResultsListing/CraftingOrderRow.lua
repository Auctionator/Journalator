JournalatorLogViewCraftingOrdersRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local lightBlue = CreateColor(116/255, 236/255, 252/255)

local function AddReagents(reagents, headerText, noEntriesText, missingText)
  if reagents and #reagents > 0 then
    GameTooltip:AddLine(lightBlue:WrapTextInColorCode(headerText))
    for _, reagent in ipairs(reagents) do
      local _, link = GetItemInfo(reagent.itemID)
      if link ~= nil then
        GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.GetNameFromLink(link)) .. Auctionator.Utilities.CreateCountString(reagent.quantity))
      end
    end
  elseif reagents then
    GameTooltip:AddLine(lightBlue:WrapTextInColorCode(noEntriesText))
  else
    GameTooltip:AddLine(missingText)
  end
end

function JournalatorLogViewCraftingOrdersRowMixin:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter
  if self.rowData.itemLink then
    GameTooltip:SetHyperlink(self.rowData.itemLink)
  end
  GameTooltip:AddLine(" ")
  if self.rowData.customerReagents or self.rowData.crafterReagents then
    AddReagents(self.rowData.customerReagents,
      JOURNALATOR_L_CUSTOMER_REAGENTS_COLON,
      JOURNALATOR_L_NO_CUSTOMER_REAGENTS,
      JOURNALATOR_L_NO_RECORDS_CUSTOMER_REAGENTS
      )

    GameTooltip:AddLine(" ")

    AddReagents(self.rowData.crafterReagents,
      JOURNALATOR_L_CRAFTER_REAGENTS_COLON,
      JOURNALATOR_L_NO_CRAFTER_REAGENTS,
      JOURNALATOR_L_NO_RECORDS_CRAFTER_REAGENTS
      )
  else
    GameTooltip:AddLine(JOURNALATOR_L_NO_RECORDS_FOR_REAGENTS)
  end
  GameTooltip:Show()
end

-- Used to prevent tooltip triggering too late and interfering with another
-- tooltip
function JournalatorLogViewCraftingOrdersRowMixin:CancelContinuable()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
    self.continuableContainer = nil
  end
end

function JournalatorLogViewCraftingOrdersRowMixin:OnHide()
  self:CancelContinuable()
end

function JournalatorLogViewCraftingOrdersRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  self:CancelContinuable()

  local allReagents = CopyTable(self.rowData.customerReagents or {})
  tAppendAll(allReagents, self.rowData.crafterReagents or {})

  -- Cache item data for all reagents ready for display in tooltip
  if #allReagents > 0 then
    self.continuableContainer = ContinuableContainer:Create()
    for _, reagent in ipairs(allReagents) do
      self.continuableContainer:AddContinuable(Item:CreateFromItemID(reagent.itemID))
    end
    self.continuableContainer:ContinueOnLoad(function()
      self.continuableContainer = nil
      self:ShowTooltip()
    end)
  -- No reagents, so just show the nothing text
  else
    self:ShowTooltip()
  end
end

function JournalatorLogViewCraftingOrdersRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  self:CancelContinuable()
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
