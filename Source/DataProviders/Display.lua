JournalatorDisplayDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

local itemLinkToLevel = {}

function JournalatorDisplayDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)
  self.processCountPerUpdate = 200 --Reduce flickering when updating the display

  Auctionator.EventBus:Register(self, {
    Journalator.Events.FiltersChanged
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
  Journalator.Archiving.LoadUpTo(self:GetTimeForRange(), function()
    self:Refresh()
  end)
end

function JournalatorDisplayDataProviderMixin:ReceiveEvent(eventName, ...)
  if eventName == Journalator.Events.FiltersChanged then
    if self:IsVisible() then
      self.onPreserveScroll()
      Journalator.Archiving.LoadUpTo(self:GetTimeForRange(), function()
        self:Refresh()
      end)
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

