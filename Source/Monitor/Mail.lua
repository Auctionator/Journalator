JournalatorMailMonitorMixin = {}

local MAIL_EVENTS = {
  "MAIL_INBOX_UPDATE",
  "CLOSE_INBOX_ITEM",
}

local function CacheMail(index)
  return {
    header = {GetInboxHeaderInfo(index)},
    invoice = {GetInboxInvoiceInfo(index)},
  }
end

local function GetFirstAttachment(mailIndex)
  for attachmentIndex = 1, ATTACHMENTS_MAX do
    local link = GetInboxItemLink(mailIndex, attachmentIndex)
    if link ~= nil then
      return link
    end
  end
end

-- Sale or purchase
--local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count, _ = GetInboxInvoiceInfo(index)
local function SaveInvoice(mail, itemLink)
  Journalator.AddToLogs({ Invoices = {
    {
      invoiceType = mail.invoice[1],
      itemName = mail.invoice[2],
      playerName = mail.invoice[3],
      value = mail.invoice[4],
      count = mail.invoice[11],
      deposit = mail.invoice[6],
      consignment = mail.invoice[7],
      time = time(),
      source = Journalator.State.Source,
      itemLink = itemLink,
    }
  }})
end

-- Cancellation or expired auction
local function SaveFailed(failedType, itemInfo, itemLink)
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
    count = quantity,
    time = time(),
    source = Journalator.State.Source,
    itemLink = itemLink,
    }
  }})
end

function JournalatorMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)
end

function JournalatorMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    self.seenAttachments = {}

    -- Ask for all mail so that player names get cached before a user opens the
    -- mail. On classic this reduces the chance that buyer names are missing.
    for mailIndex = 1, (GetInboxNumItems()) do
      local mail = CacheMail(mailIndex)

      -- Cache basic attachment information (used when another addon finds a way
      -- to skip the added hooks, say with a private copy of TakeInboxItem)
      self.seenAttachments[mailIndex] = {
        money = mail.header[5],
        link = GetFirstAttachment(mailIndex),
      }
    end

  -- Case when automatically closing mail because its being deleted due to
  -- being empty (e.g empty cancellation mail now you've taken the items)
  -- No further items can be taken until this message finishes being deleted, so
  -- we wait for it to finish.
  elseif eventName == "CLOSE_INBOX_ITEM" then
    local mailIndex = ...
    local mail = CacheMail(mailIndex)

    -- Use the cache to extract whatever was attached and log it.
    local attachment = self.seenAttachments[mailIndex]
    if attachment.money > 0 then
      self:ProcessMailWithMoney(mail)
    elseif attachment.link ~= nil then
      self:ProcessMailWithItem(mail, attachment.link)
    end
  end
end

local expiredText = AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.*)")
local cancelledText = AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.*)")

function JournalatorMailMonitorMixin:ProcessMailWithItem(mail, itemLink)
  if mail.header[4] == RETRIEVING_DATA then
    return
  end

  if mail.invoice[1] ~= nil then
    SaveInvoice(mail, itemLink)

  elseif string.match(mail.header[4], expiredText) then
    SaveFailed("expired", string.match(mail.header[4], expiredText), itemLink)

  elseif string.match(mail.header[4], cancelledText) then
    SaveFailed("cancelled", string.match(mail.header[4], cancelledText), itemLink)
  end
end

function JournalatorMailMonitorMixin:ProcessMailWithMoney(mail)
  if mail.header[4] == RETRIEVING_DATA then
    return
  end

  if mail.invoice[1] ~= nil then
    SaveInvoice(mail)
  end
end
