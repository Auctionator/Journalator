JournalatorDisplayDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

local itemLinkToLevel = {}

function JournalatorDisplayDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200 --Reduce flickering when updating the display
  self.selectedIndexes = {}

  Auctionator.EventBus:Register(self, {
    Journalator.Events.FiltersChanged,
    Journalator.Events.RowSelected,
    Journalator.Events.LogsUpdated,
    Journalator.Events.ResetTotal,
  })

  local function ApplyItemLevel(entry, itemLevel)
    if entry.searchTerm == nil then
      entry.searchTerm = entry.itemName
    end

    entry.itemName = entry.itemName .. " (" .. itemLevel .. ")"
    entry.itemNamePretty = Journalator.ApplyQualityColor(entry.itemName, entry.itemLink)
  end

  -- Populate item level in any item names
  self:SetOnEntryProcessedCallback(function(entry)
    if entry.itemLink == nil then
      self:NotifyCacheUsed()
      return
    end

    local itemClass = select(6, GetItemInfoInstant(entry.itemLink))
    if not Auctionator.Utilities.IsEquipment(itemClass) then
      self:NotifyCacheUsed()
      return
    end

    -- Use cached item level to reduce flickering and scroll jumping up and down
    if itemLinkToLevel[entry.itemLink] then
      ApplyItemLevel(entry, itemLinkToLevel[entry.itemLink])
      self:NotifyCacheUsed()
      return
    end

    local item = Item:CreateFromItemLink(entry.itemLink)
    item:ContinueOnItemLoad(function()
      local itemLevel = GetDetailedItemLevelInfo(entry.itemLink)

      if itemLevel ~= nil then
        itemLinkToLevel[entry.itemLink] = itemLevel
        ApplyItemLevel(entry, itemLevel)
        self:SetDirty()
      end
    end)
  end)
end

function JournalatorDisplayDataProviderMixin:OnShow()
  Auctionator.EventBus:RegisterSource(self, "JournalatorDisplayDataProviderMixin")
    :Fire(self, Journalator.Events.ClearTotalQuantity)
    :UnregisterSource(self)
  Journalator.Archiving.LoadUpTo(self:GetTimeForRange(), function()
    self:Refresh()
  end)
end

function JournalatorDisplayDataProviderMixin:ReceiveEvent(eventName, ...)
  if eventName == Journalator.Events.FiltersChanged then
    if self:IsVisible() then
      Journalator.Archiving.LoadUpTo(self:GetTimeForRange(), function()
        self:Refresh()
      end)
    end
  -- Reset selection on logs update.
  -- This is to avoid extra code to give each log entry a unique ID or adding to
  -- selection indexes in order to track it across log updates
  elseif eventName == Journalator.Events.LogsUpdated then
    self.selectedIndexes = {}
  elseif eventName == Journalator.Events.ResetTotal then
    local anySelected = next(self.selectedIndexes)
    self.selectedIndexes = {}
    if anySelected and self:IsVisible() then
      self:Refresh()
    end
  -- Select a row for the totals calculation
  elseif eventName == Journalator.Events.RowSelected then
    local rowData = ...
    if self:IsVisible() then
      if rowData.index == nil or rowData.value == nil then
        return
      end
      local value = rowData.value
      if self.selectedIndexes[rowData.index] then
        self.selectedIndexes[rowData.index] = nil

        Auctionator.EventBus
          :RegisterSource(self, "JournalatorDisplayDataProvider")
          :Fire(self, Journalator.Events.RemoveValueFromTotal, value)
          :UnregisterSource(self)
      else
        self.selectedIndexes[rowData.index] = true

        Auctionator.EventBus
          :RegisterSource(self, "JournalatorDisplayDataProvider")
          :Fire(self, Journalator.Events.AddValueForTotal, value)
          :UnregisterSource(self)
      end
      self:Refresh()
    end
  end
end

-- Load/refresh the current view with the current filters
function JournalatorDisplayDataProviderMixin:Refresh()
  error("This should be overridden.")
end

function JournalatorDisplayDataProviderMixin:Filter(item)
  return self:GetParent():GetParent().Filters:Filter(item)
end

function JournalatorDisplayDataProviderMixin:IsSelected(index)
  return self.selectedIndexes[index] ~= nil
end

function JournalatorDisplayDataProviderMixin:GetTimeForRange()
  return self:GetParent():GetParent().Filters:GetTimeForRange()
end

-- Every entry is considered unique (unlike in Auctionator when that isn't
-- always true)
function JournalatorDisplayDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

function JournalatorDisplayDataProviderMixin:GetRowTemplate()
  return "JournalatorLogViewResultsRowTemplate"
end

