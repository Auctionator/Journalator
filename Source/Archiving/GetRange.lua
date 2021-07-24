function Journalator.Archiving.GetRange(dateFrom, section)
  local times = {}
  local prev = nil
  for _, storeTime in ipairs(JOURNALATOR_ARCHIVE_TIMES) do
    if storeTime > dateFrom then
      if #times == 0 and prev ~= nil then
        table.insert(times, prev)
      end

      table.insert(times, storeTime)
    end
    prev = storeTime
  end

  if #times == 0 and prev ~= nil then
    table.insert(times, prev)
  end

  local items = {}
  for _, storeTime in ipairs(times) do
    local store = Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. storeTime, true)
    for _, i in ipairs(store[section]) do
      table.insert(items, i)
    end
  end

  return items
end
