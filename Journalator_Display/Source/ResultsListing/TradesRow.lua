JournalatorLogViewTradesRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

JournalatorLogViewTradesRowMixin.Populate = JournalatorLogViewResultsRowMixin.Populate
JournalatorLogViewTradesRowMixin.OnClick = JournalatorLogViewResultsRowMixin.OnClick

function JournalatorLogViewTradesRowMixin:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter
  GameTooltip:SetText(self.rowData.otherPlayer)

  if self.rowData.moneyOut < 0 or #self.rowData.itemsOut > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_OUT_COLON)
    if self.rowData.moneyOut < 0 then
      GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(-self.rowData.moneyOut, true)))
    end
    for _, item in ipairs(self.rowData.itemsOut) do
      GameTooltip:AddLine(Journalator.Utilities.GetItemText(item.itemLink, item.quantity))
    end
  end

  if self.rowData.moneyIn > 0 or #self.rowData.itemsIn > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_IN_COLON)
    if self.rowData.moneyIn > 0 then
      GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(self.rowData.moneyIn, true)))
    end
    for _, item in ipairs(self.rowData.itemsIn) do
      GameTooltip:AddLine(Journalator.Utilities.GetItemText(item.itemLink, item.quantity))
    end
  end

  GameTooltip:Show()
end

-- Used to prevent tooltip triggering too late and interfering with another
-- tooltip
function JournalatorLogViewTradesRowMixin:CancelContinuable()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
    self.continuableContainer = nil
  end
end

function JournalatorLogViewTradesRowMixin:OnHide()
  self:CancelContinuable()
end

function JournalatorLogViewTradesRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  self:CancelContinuable()

  if #self.rowData.itemsOut > 0 or #self.rowData.itemsIn > 0 then
    self.continuableContainer = ContinuableContainer:Create()

    for _, item in ipairs(self.rowData.itemsOut) do
      self.continuableContainer:AddContinuable(Item:CreateFromItemLink(item.itemLink))
    end
    for _, item in ipairs(self.rowData.itemsIn) do
      self.continuableContainer:AddContinuable(Item:CreateFromItemLink(item.itemLink))
    end

    self.continuableContainer:ContinueOnLoad(function()
      self.continuableContainer = nil
      self:ShowTooltip()
    end)
  else
    self:ShowTooltip()
  end
end

function JournalatorLogViewTradesRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  self:CancelContinuable()
  GameTooltip:Hide()
end
