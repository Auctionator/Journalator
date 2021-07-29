local callbacks = {}
local alreadyRunning = false

function Journalator.Archiving.LoadAll(cb)
  if Journalator.State.LoadedAllStores and cb ~= nil then
    cb()
    return
  end

  if cb ~= nil then
    table.insert(callbacks, cb)
  end

  if alreadyRunning then
    return
  end

  alreadyRunning = true

  local index = 1
  local ticker = C_Timer.NewTicker(0, function()
    local time = JOURNALATOR_ARCHIVE_TIMES[index]
    Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. time, true)
    index = index + 1

    if index > #JOURNALATOR_ARCHIVE_TIMES then
      Journalator.State.LoadedAllStores = true
      for _, cb in ipairs(callbacks) do
        cb()
      end
      callbacks = {}
    end
  end, #JOURNALATOR_ARCHIVE_TIMES)
end
