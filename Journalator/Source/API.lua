function Journalator.API.ComposeError(callerID, message)
  error(
    "Contact the maintainer of " .. callerID ..
    " to resolve this problem. Details: " .. message
  )
end

-- TODO: Maintain authorization keys for add-ons to prevent false callerIDs
function Journalator.API.CheckID(callerID)
  if type(callerID) ~= "string" or callerID == "" then
    error("Invalid callerID. Use the name of your add-on.")
  end
end

function Journalator.API.v1.GetRealmFailureCountByItemName(callerID, itemName)
  return 0
end

function Journalator.API.v1.GetRealmSuccessCountByItemName(callerID, itemName)
  return 0
end

function Journalator.API.v1.GetRealmLastSoldByItemName(callerID, itemName)
  return nil
end

function Journalator.API.v1.GetRealmLastBoughtByItemName(callerID, itemName)
  return nil
end

function Journalator.API.v1.GetRealmLastBoughtByItemLink(callerID, itemLink)
  return nil
end
