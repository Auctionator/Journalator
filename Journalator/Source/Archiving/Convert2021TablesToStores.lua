-- when Journalator was first created the information on postings, sales, etc.
-- was stored in uncompressed unserialized tables, which was vulnerable to the
-- SavedVariables constant limit if there was too much data.
--
-- This file includes the code to convert from the original format into the
-- Archivist based stores format.

-- Seen if every index has reached the end of the sections in the input
local function CheckIfEndsNotReached(indexes, input)
  for key, index in pairs(indexes) do
    if #input[key] >= index then
      return true
    end
  end
  return false
end

local function GetTimeSteps(input)
  local steps = {}

  local indexes = {}
  for key, value in pairs(input) do
    if type(value) == "table" then
      indexes[key] = 1
    end
  end

  local countLeft = 0
  local minTime = nil
  local minKey = nil

  while CheckIfEndsNotReached(indexes, input) do
    -- Determine next newest entry
    for key, index in pairs(indexes) do
      local entry = input[key][index]
      if entry ~= nil then
        if minTime == nil or entry.time <= minTime then
          minTime = entry.time
          minKey = key
        end
      end
    end

    -- When the store would be filled with entries create a new store timestamp
    countLeft = countLeft - 1
    if countLeft < 0 then
      table.insert(steps, minTime)
      countLeft = Journalator.Constants.STORE_SIZE_LIMIT
    end

    -- Shift the current index along one to account for the entry counted
    indexes[minKey] = indexes[minKey] + 1
    minTime = nil
  end

  return steps
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
  local timeSteps = GetTimeSteps(input) or { currentTime }

  local archiveTimes = {}
  local stores = {}
  for _, step in ipairs(timeSteps) do
    table.insert(archiveTimes, step)

    local s = archive:Load("SometimesLocked", Journalator.Constants.STORE_PREFIX .. step)
    table.insert(stores, s)

    Journalator.Archiving.InitializeStore(stores[#stores])
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
