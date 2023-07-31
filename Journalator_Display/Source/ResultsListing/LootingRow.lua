JournalatorLogViewLootingRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

JournalatorLogViewLootingRowMixin.Populate = JournalatorLogViewResultsRowMixin.Populate
JournalatorLogViewLootingRowMixin.OnClick = JournalatorLogViewResultsRowMixin.OnClick

function JournalatorLogViewLootingRowMixin:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter
  if not self.rowData.itemLink then
    GameTooltip:SetText(self.rowData.itemName)
  else
    GameTooltip:SetHyperlink(self.rowData.itemLink)
  end
  -- Sometimes the quest data is unavailable, this ensures some kind of tooltip
  -- displays anyway
  if not GameTooltip:IsVisible() then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.rowData.itemName)
  end

  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(JOURNALATOR_L_DROPS_COLON)

  if self.rowData.money > 0 then
    GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(self.rowData.money, true)))
  end

  if self.rowData.items then
    if #self.rowData.items > 0 then
      for _, item in ipairs(self.rowData.items) do
        GameTooltip:AddLine(Journalator.Utilities.GetItemText(item.itemLink, item.quantity))
      end
    end
  end

  if self.rowData.currencies then
    if #self.rowData.currencies > 0 then
      for _, item in ipairs(self.rowData.currencies) do
        GameTooltip:AddLine(Journalator.Utilities.GetCurrencyText(item.currencyID, item.quantity))
      end
    end
  end

  GameTooltip:Show()
end

-- Used to prevent tooltip triggering too late and interfering with another
-- tooltip
function JournalatorLogViewLootingRowMixin:CancelContinuable()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
    self.continuableContainer = nil
  end
end

function JournalatorLogViewLootingRowMixin:OnHide()
  self:CancelContinuable()
end

function JournalatorLogViewLootingRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  self:CancelContinuable()

  self.continuableContainer = ContinuableContainer:Create()

  -- Cache item data for all reagents ready for display in tooltip
  if self.rowData.items then
    for _, item in ipairs(self.rowData.items) do
      self.continuableContainer:AddContinuable(Item:CreateFromItemLink(item.itemLink))
    end
  end

  self.continuableContainer:ContinueOnLoad(function()
    self.continuableContainer = nil
    self:ShowTooltip()
  end)
end

function JournalatorLogViewLootingRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  self:CancelContinuable()
  GameTooltip:Hide()
end
