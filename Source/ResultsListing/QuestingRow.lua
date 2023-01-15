JournalatorLogViewQuestingRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local function IsGear(itemLink)
  local classType = select(6, GetItemInfoInstant(itemLink))
  return classType == Enum.ItemClass.Weapon
    or classType == Enum.ItemClass.Armor
    -- In DF profession equipment is its own class:
    or (not Auctionator.Constants.IsClassic and classType ~= nil and classType == Enum.ItemClass.Profession)
end

local function AddItem(itemLink, quantity)
  local itemInfo = {GetItemInfo(itemLink)}
  local text = Auctionator.Utilities.GetNameFromLink(itemInfo[2])

  if IsGear(itemLink) then
    text = text .. " (" .. (GetDetailedItemLevelInfo(itemLink)) .. ")"
  end

  local qualityColor = ITEM_QUALITY_COLORS[itemInfo[3]]
  text = qualityColor.color:WrapTextInColorCode(text)

  if quantity > 1 then
    text = text .. Auctionator.Utilities.CreateCountString(quantity)
  end

  GameTooltip:AddLine(text)
end

local function AddCurrency(currencyID, quantity)
  local link = C_CurrencyInfo.GetCurrencyLink(currencyID, quantity)

  local text = Auctionator.Utilities.GetNameFromLink(link)

  local color = Auctionator.Utilities.GetQualityColorFromLink(link)
  if color ~= nil then
    text = "|c" .. color .. text .. "|r"
  end

  text = text .. Auctionator.Utilities.CreateCountString(quantity)

  GameTooltip:AddLine(text)
end

function JournalatorLogViewQuestingRowMixin:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter
  GameTooltip:SetHyperlink(self.rowData.itemLink)

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
        AddItem(item.itemLink, item.quantity)
      end
    end
  else
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_NO_ITEM_RECORDS)
  end

  if self.rowData.currencies then
    if #self.rowData.currencies > 0 then
      if not shownRewardsHeader then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(JOURNALATOR_L_REWARDS_COLON)
        shownRewardsHeader = true
      end
      for _, item in ipairs(self.rowData.currencies) do
        AddCurrency(item.currencyID, item.quantity)
      end
    end
  else
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_NO_CURRENCY_RECORDS)
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
        GameTooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(item.factionName .. " " .. change))
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
