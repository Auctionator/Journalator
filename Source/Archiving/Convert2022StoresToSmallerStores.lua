-- When Journalator was changed to store the information an archive the chunks
-- were set to a monthly interval. This extracts all the data and puts it into
-- new chunks in a smaller interval (daily at time of writing)

function Journalator.Archiving.Convert2022StoresToSmallerStores(archive, callback)
  local input = {}
  Journalator.Archiving.InitializeStore(input)

  function loadNextStore(index)
    local storeTime = JOURNALATOR_ARCHIVE_TIMES[index]
    local store = archive:Open("SometimesLocked", Journalator.Constants.STORE_PREFIX .. storeTime, true)
    for key, val in pairs(store) do
      if type(val) == "table" then
        for _, entry in ipairs(val) do
          table.insert(input[key], entry)
        end
      end
    end
    archive:DeleteStore(store)

    if index < #JOURNALATOR_ARCHIVE_TIMES then
      C_Timer.After(0, function()
        loadNextStore(index + 1)
      end)
    else
      Journalator.Archiving.Convert2021TablesToStores(input, archive, callback)
    end
  end

  loadNextStore(1)
end
