JournalatorMailMonitorMixin = {}

MAIL_EVENTS = {
  "MAIL_SHOW",
  "MAIL_CLOSED",
  "MAIL_INBOX_UPDATE",
  "UPDATE_PENDING_MAIL",
}

function JournalatorMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)
end

local function GetMailKey(mail)
  return mail.header[4] .. tostring(mail.header[7])
end

local itemsByKey = {}

local function CacheMail(index)
  local result = {
    header = {GetInboxHeaderInfo(index)},
    invoice = {GetInboxInvoiceInfo(index)},
    items = {},
  }

  for i = 1, ATTACHMENTS_MAX_RECEIVE do
    local details = {GetInboxItem(index, i)}
    if details[1] ~= nil then
      table.insert(result.items, {
        name = details[1],
        itemID = details[2],
        count = details[4],
        link = GetInboxItemLink(index, i),
      })
    end
  end
  local key = GetMailKey(result)
  if not itemsByKey[key] or #result.items > #itemsByKey[key] then
    itemsByKey[key] = result.items
  end
  result.items = itemsByKey[key]

  return result
end

local function IsSameMail(mail, otherMail)
  return GetMailKey(mail) == GetMailKey(otherMail)
end

local function RecordAllMail()
  local cache = {}
  for i = 1, GetInboxNumItems() do
    local mail = CacheMail(i)
    cache[GetMailKey(mail)] = mail
  end
  return cache
end

local function IsInCache(mail, cache)
  return cache[GetMailKey(mail)] ~= nil
end

--local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count, _ = GetInboxInvoiceInfo(index)
local function SaveInvoice(mail)
  table.insert(JOURNALATOR_LOGS.Invoices, {
    invoiceType = mail.invoice[1],
    itemName = mail.invoice[2],
    playerName = mail.invoice[3],
    value = mail.invoice[4],
    count = mail.invoice[11],
    deposit = mail.invoice[6],
    consignment = mail.invoice[7],
    time = time(),
    source = Journalator.Source,
  })
end

local previousCache = {}

hooksecurefunc(_G, "CheckInbox", function()
  previousCache = {}
end)
function JournalatorMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    if not next(previousCache) then
      previousCache = RecordAllMail()
    end
    local newCache = RecordAllMail()
    for key, mail in pairs(previousCache) do
      if newCache[key] == nil and mail.header[4] ~= RETRIEVING_DATA then
        --print("deleted", key, (mail.items[1] and mail.items[1].link))
        if mail.invoice[1] ~= nil then
          --print("invoice saving", key)
          SaveInvoice(mail)
        end
      end
    end
    previousCache = newCache
  end
end
