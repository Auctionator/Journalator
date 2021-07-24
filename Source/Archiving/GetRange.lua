-- Gets all the items in the stores which overlap the time range (dateFrom, now)
-- Returns an array ordered by time (if the original data is also ordered).
--
-- For example, if the overlapping store starts 500s before dateFrom, all the
-- items from that 500s will be included in the results returned, as well as all
-- the results after dateFrom.
function Journalator.Archiving.GetRange(dateFrom, section)
  -- Identify the starting dates for the relevant stores that contain the items
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

  -- Get all the items
  local items = {}
  for _, storeTime in ipairs(times) do
    local store = Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. storeTime, true)
    for _, i in ipairs(store[section]) do
      table.insert(items, i)
    end
  end

  return items
end
