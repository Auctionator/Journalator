local allCompletedCallbacks = {}
local allStatusCallbacks = {}
local frame = nil

function Journalator.Archiving.LoadAll(completedCallback, statusCallback)
  if Journalator.State.LoadedAllStores and completedCallback ~= nil then
    completedCallback()
    return
  end

  if completedCallback ~= nil then
    table.insert(allCompletedCallbacks, completedCallback)
  end

  if statusCallback ~= nil then
    table.insert(allStatusCallbacks, statusCallback)
  end

  if frame ~= nil then
    return
  end

  frame = CreateFrame("FRAME")

  local index = 1
  for _, callback in ipairs(allStatusCallbacks) do
    callback(index, #JOURNALATOR_ARCHIVE_TIMES)
  end

  frame:SetScript("OnUpdate", function()
    local time = JOURNALATOR_ARCHIVE_TIMES[index]

    Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. time, true)
    index = index + 1
    for _, callback in ipairs(allStatusCallbacks) do
      callback(index, #JOURNALATOR_ARCHIVE_TIMES)
    end

    if index > #JOURNALATOR_ARCHIVE_TIMES then
      frame:SetScript("OnUpdate", nil)

      Journalator.State.LoadedAllStores = true
      for _, callback in ipairs(allCompletedCallbacks) do
        callback()
      end
      allCompletedCallbacks = {}
      allStatusCallbacks = {}
    end
  end)
end
