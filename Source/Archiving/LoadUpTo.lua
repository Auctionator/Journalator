local allCompletedCallbacks = {}
local allStatusCallbacks = {}
local frame = nil

local function LoadNextArchive(frame)
  local archiveTime = JOURNALATOR_ARCHIVE_TIMES[frame.index]
  Journalator.State.Archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. archiveTime, true)
  for _, callback in ipairs(allStatusCallbacks) do
    callback(#JOURNALATOR_ARCHIVE_TIMES - frame.index + 1, #JOURNALATOR_ARCHIVE_TIMES)
  end

  if frame.index <= 1 or archiveTime <= frame.targetTime then
    frame:SetScript("OnUpdate", nil)
    Journalator.State.MinLoadedTime = frame.targetTime

    Journalator.State.LoadedAllStores = true
    for _, callback in ipairs(allCompletedCallbacks) do
      callback()
    end
    allCompletedCallbacks = {}
    allStatusCallbacks = {}
  else
    frame.index = frame.index - 1
  end
end

function Journalator.Archiving.LoadUpTo(minTime, completedCallback, statusCallback)
  if Journalator.State.MinTimeLoaded <= minTime or (frame and frame.index == 0) then
    if completedCallback ~= nil then
      completedCallback()
    end
    return
  end

  if completedCallback ~= nil then
    table.insert(allCompletedCallbacks, completedCallback)
  end

  if statusCallback ~= nil then
    table.insert(allStatusCallbacks, statusCallback)
  end

  if frame ~= nil then
    frame.targetTime = math.min(frame.targetTime, minTime)
    frame:SetScript("OnUpdate", LoadNextArchive)
    return
  end

  frame = CreateFrame("FRAME")

  frame.index = #JOURNALATOR_ARCHIVE_TIMES
  for _, callback in ipairs(allStatusCallbacks) do
    callback(0, #JOURNALATOR_ARCHIVE_TIMES)
  end
  frame.targetTime = minTime

  frame:SetScript("OnUpdate", LoadNextArchive)
end
