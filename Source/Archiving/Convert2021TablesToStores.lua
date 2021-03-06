-- when Journalator was first created the information on postings, sales, etc.
-- was stored in uncompressed unserialized tables, which was vulnerable to the
-- SavedVariables constant limit if there was too much data.
--
-- This file includes the code to convert from the original format into the
-- Archivist based stores format.

-- Get the oldest time in any section (Invoices/Posting/etc.)
local function GetOldestTime(input)
  local oldestTime = nil

  for key, value in pairs(input) do
    if type(value) == "table" and value[1] and value[1].time then
      if oldestTime ~= nil then
        oldestTime = math.min(oldestTime, value[1].time)
      else
        oldestTime = value[1].time
      end
    end
  end

  return oldestTime
end

-- Place the items from the section (Invoices/Posting/etc.) in the correct store
-- for their time.
local function ImportSection(section, input, archiveTimes, stores)
  local storeIndex = 1
  for index, item in ipairs(input[section]) do
    while storeIndex < #stores and item.time >= archiveTimes[storeIndex+1] do
      storeIndex = storeIndex + 1
    end
    table.insert((stores[storeIndex])[section], item)
  end
end

function Journalator.Archiving.Convert2021TablesToStores(input, archive)
  local currentTime = time()
  local oldestTime = GetOldestTime(input) or currentTime

  local archiveTimes = {}
  local stores = {}
  while oldestTime < currentTime do
    table.insert(archiveTimes, oldestTime)

    local s = archive:Load("SometimesLocked", Journalator.Constants.STORE_PREFIX .. oldestTime)
    table.insert(stores, s)

    Journalator.Archiving.InitializeStore(stores[#stores])
    oldestTime = oldestTime + Journalator.Constants.ARCHIVE_INTERVAL
  end

  ImportSection("Invoices", input, archiveTimes, stores)
  ImportSection("Posting", input, archiveTimes, stores)
  ImportSection("Failures", input, archiveTimes, stores)
  if input.Vendoring then
    ImportSection("Vendoring", input, archiveTimes, stores)
  end

  for _, s in ipairs(stores) do
    archive:CloseStore(s)
  end

  JOURNALATOR_ARCHIVE_TIMES = archiveTimes
end
