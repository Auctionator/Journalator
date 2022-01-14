local allCallbacks = {}
local frame = nil

function Journalator.Archiving.LoadAll(callback)
  if Journalator.State.LoadedAllStores and callback ~= nil then
    callback()
    return
  end

  if callback ~= nil then
    table.insert(allCallbacks, callback)
  end

  if frame ~= nil then
    return
  end

  frame = CreateFrame("FRAME")

  local index = 1

  local fullStartTime = debugprofilestop()
  frame:SetScript("OnUpdate", function()
    local time = JOURNALATOR_ARCHIVE_TIMES[index]

    Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. time, true)
    index = index + 1

    if index > #JOURNALATOR_ARCHIVE_TIMES then
      frame:SetScript("OnUpdate", nil)

      Journalator.State.LoadedAllStores = true
      for _, callback in ipairs(allCallbacks) do
        callback()
      end
      allCallbacks = {}
    end
  end)
end
