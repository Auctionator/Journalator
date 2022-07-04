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

  hooksecurefunc(_G, "CheckInbox", function()
    self.previousCache = {}
  end)
end

local function GetFirstItem(mailIndex)
  for i = 1, ATTACHMENTS_MAX_RECEIVE do
    local link = GetInboxItemLink(mailIndex, i)
    if link then
      return link
    end
  end
end

local function CacheMail(index)
  return {
    header = {GetInboxHeaderInfo(index)},
    invoice = {GetInboxInvoiceInfo(index)},
    itemLink = GetFirstItem(index)
  }
end

local function GetMailKey(mail)
  return
    mail.header[4] ..  " " ..
    tostring(mail.header[7]) .. " " ..
    tostring(mail.invoice[4] or 0) .. " " ..
    (mail.itemLink or "")
end

local function RecordAllMail(counts)
  local cache = {}
  local counts = {}
  for i = 1, GetInboxNumItems() do
    local firstItem = GetFirstItem(i)
    local mail = CacheMail(i)
    local key = GetMailKey(mail)

    if firstItem ~= nil or mail.header[5] > 0 then -- Got an item or money

      cache[key] = mail

      if counts[key] == nil then
        counts[key] = 0
      end

      if mail.invoice[11] ~= nil then
        counts[key] = counts[key] + mail.invoice[11]
      else
        counts[key] = counts[key] + 1
      end
    end
  end
  return cache, counts
end

--local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count, _ = GetInboxInvoiceInfo(index)
--count: Number of items seen across multiple similar mails for this item, used
--to avoid losing items when processing a lot of them.
local function SaveInvoice(mail, count)
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
      itemLink = mail.itemLink,
    }
  }})
end

--multiplier: Number of similar mails for this itemLink and quantity, used to avoid
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
  if eventName == "MAIL_SHOW" or eventName == "MAIL_CLOSED" or eventName == "UPDATE_PENDING_MAIL" then
    self.previousCache, self.previousCounts = {}, {}
  elseif eventName == "MAIL_INBOX_UPDATE" then
    if not next(self.previousCache) then
      self.previousCache, self.previousCounts = RecordAllMail()
    end
    local newCache, newCounts = RecordAllMail()
    for key, mail in pairs(self.previousCache) do
      if (newCache[key] == nil or newCounts[key] < self.previousCounts[key]) and
          mail.header[4] ~= RETRIEVING_DATA then
        if mail.invoice[1] ~= nil then
          SaveInvoice(mail, self.previousCounts[key] - (newCounts[key] or 0))
        elseif string.match(mail.header[4], expiredText) then
          SaveFailed("expired", string.match(mail.header[4], expiredText), mail.itemLink, self.previousCounts[key] - (newCounts[key] or 0))
        elseif string.match(mail.header[4], cancelledText) then
          SaveFailed("cancelled", string.match(mail.header[4], cancelledText), mail.itemLink, self.previousCounts[key] - (newCounts[key] or 0))
        end
      end
    end
    self.previousCache = newCache
    self.previousCounts = newCounts
  end
end
