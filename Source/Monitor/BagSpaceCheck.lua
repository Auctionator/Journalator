-- Assumes GetItemInfo data is loaded
-- Returns true if a bag has the space for all of slotSizeNeeded*itemLink
function Journalator.Monitor.BagSpaceCheck(itemLink, slotSizeNeeded)
  local stackSize = select(8, GetItemInfo(itemLink))

  for bag = 0, 4 do
    local available = 0

    for slot = 1, GetContainerNumSlots(bag) do
      local _, itemCount, _, _, _, _, slotLink = GetContainerItemInfo(bag, slot)
      if itemCount == 0 or itemCount == nil then
        available = available + stackSize
      elseif itemLink == slotLink then
        available = available + stackSize - itemCount
      end
    end

    if available >= slotSizeNeeded then
      return true
    end
  end

  return false
end
