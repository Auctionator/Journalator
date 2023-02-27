JournalatorLogViewQuestingRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function JournalatorLogViewQuestingRowMixin:ShowTooltip()
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

  if self.rowData.requiredMoney ~= nil then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_REQUIRED_COLON)
    GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(self.rowData.requiredMoney, true)))
  end

  local shownRewardsHeader = false
  if self.rowData.items then
    if #self.rowData.items > 0 then
      GameTooltip:AddLine(" ")
      if not shownRewardsHeader then
        GameTooltip:AddLine(JOURNALATOR_L_REWARDS_COLON)
        shownRewardsHeader = true
      end
      for _, item in ipairs(self.rowData.items) do
        local name, link = GetItemInfo(item.itemLink)
        GameTooltip:AddLine(Journalator.Utilities.GetItemText(item.itemLink, item.quantity))
      end
    end
  end

  if self.rowData.currencies then
    if #self.rowData.currencies > 0 then
      if not shownRewardsHeader then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(JOURNALATOR_L_REWARDS_COLON)
        shownRewardsHeader = true
      end
      for _, item in ipairs(self.rowData.currencies) do
        GameTooltip:AddLine(Journalator.Utilities.GetCurrencyText(item.currencyID, item.quantity))
      end
    end
  end

  if self.rowData.reputationChanges then
    if #self.rowData.reputationChanges > 0 then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(JOURNALATOR_L_REPUTATION_COLON)
      for _, item in ipairs(self.rowData.reputationChanges) do
        local change = tostring(item.reputationChange)
        if item.reputationChange > 0 then
          change = "+" .. change
        end

        local factionName
        if item.factionID then
          factionName = GetFactionInfoByID(item.factionID)
        else
          factionName = item.factionName
        end

        -- Work around Blizzard error where the guild factions don't return
        -- anything for the name
        if factionName == nil and item.factionID == 1168 or item.factionID == 1169 then
          factionName = JOURNALATOR_L_GUILD
        end

        GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(factionName .. " " .. change))
      end
    end
  end

  GameTooltip:Show()
end

-- Used to prevent tooltip triggering too late and interfering with another
-- tooltip
function JournalatorLogViewQuestingRowMixin:CancelContinuable()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
    self.continuableContainer = nil
  end
end

function JournalatorLogViewQuestingRowMixin:OnHide()
  self:CancelContinuable()
end

function JournalatorLogViewQuestingRowMixin:OnEnter()
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

function JournalatorLogViewQuestingRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  self:CancelContinuable()
  GameTooltip:Hide()
end

function JournalatorLogViewQuestingRowMixin:OnClick(button)
  if button == "LeftButton" then
    if IsModifiedClick("CHATLINK") then
      if self.rowData.itemLink ~= nil then
        ChatEdit_InsertLink(self.rowData.itemLink)
      end
    else
      Auctionator.EventBus
        :RegisterSource(self, "JournalatorLogViewQuestingRowMixin")
        :Fire(self, Journalator.Events.RowClicked, self.rowData)
        :UnregisterSource(self)
    end
  end
end
