JournalatorMailMonitorMixin = {}

local MAIL_EVENTS = {
  "MAIL_SHOW",
  "MAIL_CLOSED",
  "MAIL_INBOX_UPDATE",
  "UPDATE_PENDING_MAIL",
}

function JournalatorMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)

  self.previousCache = {}
  self.itemLog = {}

  hooksecurefunc(_G, "CheckInbox", function()
    self.previousCache = {}
    self.itemLog = {}
  end)
end

local function GetMailKey(mail)
  return mail.header[4] .. " " .. tostring(mail.header[7]) .. " " .. tostring(mail.invoice[11] or 0)
end

local function CacheMail(index)
  return {
    header = {GetInboxHeaderInfo(index)},
    invoice = {GetInboxInvoiceInfo(index)},
  }
end

local function GetFirstItem(mailIndex)
  for i = 1, ATTACHMENTS_MAX_RECEIVE do
    local link = GetInboxItemLink(mailIndex, i)
    if link then
      return link
    end
  end
end

local function RecordAllMail(itemLog, counts)
  local cache = {}
  local newCounts = {}
  for i = 1, GetInboxNumItems() do
    local mail = CacheMail(i)
    local key = GetMailKey(mail)

    cache[key] = mail
    itemLog[key] = GetFirstItem(i) or itemLog[key]

    if newCounts[key] == nil then
      newCounts[key] = 0
    end

    if mail.invoice[11] ~= nil then
      newCounts[key] = newCounts[key] + mail.invoice[11]
    else
      newCounts[key] = newCounts[key] + 1
    end

    if counts[key] == nil or newCounts[key] > counts[key] then
      counts[key] = newCounts[key]
    end
  end
  return cache, itemLog, counts
end

--local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count, _ = GetInboxInvoiceInfo(index)
--count: Number of items seen across multiple similar mails for this item, used
--to avoid losing items when processing a lot of them.
local function SaveInvoice(mail, itemLink, count)
  Journalator.AddToLogs({ Invoices = {
    {
      invoiceType = mail.invoice[1],
      itemName = mail.invoice[2],
      playerName = mail.invoice[3],
      value = mail.invoice[4],
      count = count,
      deposit = mail.invoice[6],
      consignment = mail.invoice[7],
      time = time(),
      source = Journalator.State.Source,
      itemLink = itemLink,
    }
  }})
end

--multiplier: Number of similar mails for this item and quantity, used to avoid
--losing items when processing a lot of them.
local function SaveFailed(failedType, itemInfo, itemLink, multiplier)
  local itemName, quantityText = string.match(itemInfo, "(.*) %((%d+)%)")

  local quantity = 1
  if itemName == nil then
    itemName = itemInfo
  else
    quantity = tonumber(quantityText)
  end

  Journalator.AddToLogs({ Failures = {
    {
    failedType = failedType,
    itemName = itemName,
    count = quantity * multiplier,
    time = time(),
    source = Journalator.State.Source,
    itemLink = itemLink,
    }
  }})
end

local expiredText = AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.*)")
local cancelledText = AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.*)")

function JournalatorMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    if not next(self.previousCache) then
      self.itemLog = {}
      self.counts = {}
      self.previousCache = RecordAllMail(self.itemLog, self.counts)
    end
    local newCache = RecordAllMail(self.itemLog, self.counts)
    for key, mail in pairs(self.previousCache) do
      if newCache[key] == nil and mail.header[4] ~= RETRIEVING_DATA then
        if mail.invoice[1] ~= nil then
          SaveInvoice(mail, self.itemLog[key], self.counts[key])
        elseif string.match(mail.header[4], expiredText) then
          SaveFailed("expired", string.match(mail.header[4], expiredText), self.itemLog[key], self.counts[key])
        elseif string.match(mail.header[4], cancelledText) then
          SaveFailed("cancelled", string.match(mail.header[4], cancelledText), self.itemLog[key], self.counts[key])
        end
      end
    end
    self.previousCache = newCache
  end
end
