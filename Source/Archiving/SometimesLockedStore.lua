-- Manage archivist stores that they are usually opened in a read-only mode so
-- that no time needs to be spent compressing the store for storage on
-- PLAYER_LOGOUT.
--
-- Usually just the store for the latest month (as configured by
-- Journalator.Constants.ARCHIVE_INTERVAL) is in a read/write mode.
-- The default setting for a store is read/write. To open in read-only mode set
-- the locked parameter to true.
local Archivist = select(2, ...).Archivist

local prototype = {
  id = "SometimesLocked",
  version = 1,
  locked = {},
  Create = function(self, data, locked)
    if type(data) ~= "table" then
      data = {}
    end
    self.locked[data] = locked or false
    return data, data
  end,
  Open = function(self, data, locked)
    if self.locked[data] == nil then
      self.locked[data] = locked or false
    end
    return data
  end,
  Commit = function(self, store)
    if not self.locked[store] then
      return store
    end
  end,
  Close = function(self, store)
    local isLocked = self.locked[store]
    self.locked[store] = nil
    if not isLocked then
      return store
    end
  end,
}

Archivist:RegisterDefaultStoreType(prototype)
