JournalatorMailMonitorMixin = {}

local MAIL_EVENTS = {
  "MAIL_SHOW",
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

-- Checks whether taking an item from the mail will cause it to be deleted (ie
-- you're on the last item)
local function IsOnLastStuff(mailIndex)
  local count = 0
  for attachmentIndex = 1, ATTACHMENTS_MAX do
    if HasInboxItem(mailIndex, attachmentIndex) then
      count = count + 1
    end
  end
  local money = select(5, GetInboxHeaderInfo(mailIndex))

  -- Reports when either
  -- 1. Last item (gear/pet/etc.) and no money OR
  -- 2. Only money left and no items (gear/pet/etc.)
  return (count == 1 and money == 0) or (money > 0 and count == 0)
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

local function GetNumMails()
  return select(2, GetInboxNumItems())
end

function JournalatorMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)

  self:RegisterPickupHandlers()

  self:ResetState()

  hooksecurefunc(_G, "CheckInbox", function()
    self:ResetState()
  end)
end

function JournalatorMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_SHOW" then
    self:ResetState()
  elseif eventName == "MAIL_INBOX_UPDATE" then
    self.mailQueued = false
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

    -- XXX: Possible edge case, if a mail arrives in the same event that this
    -- mail is deleted it may look like it wasn't deleted, and delay processing
    -- until the next deletion.
    if self.waitingForDeletion and GetNumMails() < self.lastMailCount then
      self.waitingForDeletion = false
    end
    self.lastMailCount = GetNumMails()

  -- Case when automatically closing mail because its being deleted due to
  -- being empty (e.g empty cancellation mail now you've taken the items)
  -- No further items can be taken until this message finishes being deleted, so
  -- we wait for it to finish.
  elseif eventName == "CLOSE_INBOX_ITEM" then
    local mailIndex = ...
    local mail = CacheMail(mailIndex)

    -- Special case, when a mail is deleted, but we haven't had a chance to
    -- intercept the TakeInboxItem call it means that the hook was bypassed.
    -- This uses the attachment cache to figure out what was attached and save
    -- it anyway.
    if not self.mailQueued then
      local attachment = self.seenAttachments[mailIndex]
      if attachment.money > 0 then
        self:ProcessMailWithMoney(mail, true)
      elseif attachment.link ~= nil then
        self:ProcessMailWithItem(mail, true, attachment.link)
      end
    end

    self.waitingForDeletion = true
    self.lastMailCount = GetNumMails()
  end
end

function JournalatorMailMonitorMixin:ResetState()
  self.mailQueued = false

  -- Used to detect when a mail that had something now has nothing on it and
  -- gets automatically deleted
  self.waitingForDeletion = false
  self.lastMailCount = nil
end

function JournalatorMailMonitorMixin:RegisterPickupHandlers()
  hooksecurefunc(_G, "TakeInboxItem", function(mailIndex, attachmentIndex)
    local link = GetInboxItemLink(mailIndex, attachmentIndex)
    local count = select(4, GetInboxItem(mailIndex, attachmentIndex))

    -- Mail is with an item on it, the item can only be taken if it exists AND
    -- there's space for it in the player's bag
    if self:IsReady() and link ~= nil and Journalator.Monitor.BagSpaceCheck(link, count) then
      self.mailQueued = true

      self:ProcessMailWithItem(CacheMail(mailIndex), IsOnLastStuff(mailIndex), link)
    end
  end)
  hooksecurefunc(_G, "TakeInboxMoney", function(mailIndex)
    local money = select(5, GetInboxHeaderInfo(mailIndex))

    -- XXX: Edge case, its untested what happens if the amount of money would
    -- push the player over the Blizzard character gold-cap threshold.
    if self:IsReady() and money > 0 then
      self.mailQueued = true

      self:ProcessMailWithMoney(CacheMail(mailIndex), IsOnLastStuff(mailIndex))
    end
  end)
end

-- Ready if no other item has been picked up and is pending from mail and no
-- mail is being automatically deleted
function JournalatorMailMonitorMixin:IsReady()
  return not self.mailQueued and not self.waitingForDeletion
end

local expiredText = AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.*)")
local cancelledText = AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.*)")

function JournalatorMailMonitorMixin:ProcessMailWithItem(mail, isLastStuff, itemLink)
  if mail.header[4] == RETRIEVING_DATA then
    return
  end

  if isLastStuff then
    if mail.invoice[1] ~= nil then
      SaveInvoice(mail, itemLink)

    elseif string.match(mail.header[4], expiredText) then
      SaveFailed("expired", string.match(mail.header[4], expiredText), itemLink)

    elseif string.match(mail.header[4], cancelledText) then
      SaveFailed("cancelled", string.match(mail.header[4], cancelledText), itemLink)
    end
  end
end

function JournalatorMailMonitorMixin:ProcessMailWithMoney(mail, isLastStuff)
  if mail.header[4] == RETRIEVING_DATA then
    return
  end

  if isLastStuff then
    if mail.invoice[1] ~= nil then
      SaveInvoice(mail)
    end
  end
end
