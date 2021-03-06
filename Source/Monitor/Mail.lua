JournalatorMailMonitorMixin = {}

MAIL_EVENTS = {
  "MAIL_SHOW",
  "MAIL_CLOSED",
  "MAIL_INBOX_UPDATE",
  "UPDATE_PENDING_MAIL",
}

function JournalatorMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)

  self.previousCache = {}

  hooksecurefunc(_G, "CheckInbox", function()
    self.previousCache = {}
  end)
end

local function GetMailKey(mail)
  return mail.header[4] .. tostring(mail.header[7])
end

local function CacheMail(index)
  return {
    header = {GetInboxHeaderInfo(index)},
    invoice = {GetInboxInvoiceInfo(index)},
  }
end

local function RecordAllMail()
  local cache = {}
  for i = 1, GetInboxNumItems() do
    local mail = CacheMail(i)
    cache[GetMailKey(mail)] = mail
  end
  return cache
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

function JournalatorMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    if not next(self.previousCache) then
      self.previousCache = RecordAllMail()
    end
    local newCache = RecordAllMail()
    for key, mail in pairs(self.previousCache) do
      if newCache[key] == nil and mail.header[4] ~= RETRIEVING_DATA then
        if mail.invoice[1] ~= nil then
          SaveInvoice(mail)
        end
      end
    end
    self.previousCache = newCache
  end
end
