-- Invoices/Posting/etc. data is separated into stores inside an Archivist
-- instance.
--
-- Each store covers the period of a month (configured by
-- Journalator.Constants.ARCHIVE_INTERVAL), and includes all the
-- Invoices/Posting/etc. entries for that month, stored in the
-- Invoices/Posting/etc. keys, which contain ordered arrays by time ascending of
-- the entries.
--
-- Usage of Archivist is best explained by reading the Github documentation
-- https://github.com/emptyrivers/Archivist
local Archivist = select(2, ...).Archivist

function Journalator.Archiving.InitializeStore(store)
  if store.Version ~= 1 then
    store.Version = 1
    store.Invoices = {}
    store.Posting = {}
    store.Failures = {}
    store.Vendoring = {}
  end
end

function Journalator.Archiving.Initialize()
  JOURNALATOR_ARCHIVE = JOURNALATOR_ARCHIVE or {}
  local archive = Archivist:Initialize(JOURNALATOR_ARCHIVE)

  -- Upgrade from the old storage format (plain tables with lots of keys)
  -- This can be removed if _all_ users have been converted (2021-07-24).
  if JOURNALATOR_LOGS then
    Journalator.Archiving.Convert2021TablesToStores(JOURNALATOR_LOGS, archive)
    JOURNALATOR_LOGS = nil
  end

  -- Create a store if there aren't any already
  if JOURNALATOR_ARCHIVE_TIMES == nil or #JOURNALATOR_ARCHIVE_TIMES == 0 then
    JOURNALATOR_ARCHIVE_TIMES = { time() }
    archive:Create("SometimesLocked", Journalator.Constants.STORE_PREFIX .. JOURNALATOR_ARCHIVE_TIMES[1])
  end

  local storeTime = JOURNALATOR_ARCHIVE_TIMES[#JOURNALATOR_ARCHIVE_TIMES]
  local currentTime = time()
  -- If more than a month (the ARCHIVE_INTERVAL) has elapsed since the last
  -- store was created, update the time and create a new one.
  if currentTime - storeTime > Journalator.Constants.ARCHIVE_INTERVAL then
    storeTime = currentTime
    archive:Create("SometimesLocked", Journalator.Constants.STORE_PREFIX .. storeTime)
    table.insert(JOURNALATOR_ARCHIVE_TIMES, storeTime)
  end

  Journalator.State.Logs = archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. storeTime)

  Journalator.Archiving.InitializeStore(Journalator.State.Logs)

  Journalator.State.Archive = archive
end
