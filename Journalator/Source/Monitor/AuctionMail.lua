JournalatorAuctionMailMonitorMixin = {}

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

-- Order of parameters for the battle pet hyperlink string
local battlePetTooltip = {
  "battlePetSpeciesID",
  "battlePetLevel",
  "battlePetBreedQuality",
  "battlePetMaxHealth",
  "battlePetPower",
  "battlePetSpeed",
}
-- Convert an attachment to a battle pet link as by default only the cage item
-- is supplied on the attachment link, missing all the battle pet stats (retail
-- only)
local function ExtractBattlePetLink(mailIndex, attachmentIndex)
  local tooltipInfo = C_TooltipInfo.GetInboxItem(mailIndex, attachmentIndex)
  if tooltipInfo then
    TooltipUtil.SurfaceArgs(tooltipInfo)

    local itemString = "battlepet"
    for _, key in ipairs(battlePetTooltip) do
      itemString = itemString .. ":" .. tooltipInfo[key]
    end

    local name = C_PetJournal.GetPetInfoBySpeciesID(tooltipInfo.battlePetSpeciesID)
    local quality = ITEM_QUALITY_COLORS[tooltipInfo.battlePetBreedQuality].color
    return quality:WrapTextInColorCode("|H" .. itemString .. "|h[" .. name .. "]|h")
  else
    print("miss")
  end
end

local function GetFirstAttachment(mailIndex)
  for attachmentIndex = 1, ATTACHMENTS_MAX do
    local link = GetInboxItemLink(mailIndex, attachmentIndex)
    if link ~= nil then
      if not Journalator.Constants.IsClassic and link:find("item:" .. Journalator.Constants.PET_CAGE_ID) then
        return ExtractBattlePetLink(mailIndex, attachmentIndex) or link
      else
        return link
      end
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

function JournalatorAuctionMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)
end

function JournalatorAuctionMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    Journalator.Debug.Message("JournalatorAuctionMailMonitor: inbox update", GetInboxNumItems())
    self.seenAttachments = {}

    for mailIndex = 1, (GetInboxNumItems()) do
      -- Ask for all mail so that player names get cached before a user opens
      -- the mail. This reduces the chance that buyer/seller names are missing.
      local mail = CacheMail(mailIndex)

      -- Keep the attachments for use after they've been removed from the mail
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

    Journalator.Debug.Message("JournalatorAuctionMailMonitor: close mail", mailIndex, mail.header[4], attachment.link, attachment.money)
  end
end

local expiredText = AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.*)")
local cancelledText = AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.*)")

function JournalatorAuctionMailMonitorMixin:ProcessMailWithItem(mail, itemLink)
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

function JournalatorAuctionMailMonitorMixin:ProcessMailWithMoney(mail)
  if mail.header[4] == RETRIEVING_DATA then
    return
  end

  if mail.invoice[1] ~= nil then
    SaveInvoice(mail)
  end
end
