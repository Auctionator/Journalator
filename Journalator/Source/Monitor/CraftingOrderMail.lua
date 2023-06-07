JournalatorCraftingOrderMailMonitorMixin = {}

local MAIL_EVENTS = {
  "MAIL_INBOX_UPDATE",
  "CLOSE_INBOX_ITEM",
}

local cancelledText, expiredText, rejectText

function JournalatorCraftingOrderMailMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MAIL_EVENTS)
  cancelledText = Journalator.Utilities.GetChatPattern(CONSORTIUM_CANCEL_MAIL_SUBJECT_FMT)
  expiredText = Journalator.Utilities.GetChatPattern(CONSORTIUM_EXPIRE_MAIL_SUBJECT_FMT)
  rejectText = Journalator.Utilities.GetChatPattern(CONSORTIUM_REJECT_MAIL_SUBJECT_FMT)
end

local function GetFirstAttachment(mailIndex)
  for attachmentIndex = 1, ATTACHMENTS_MAX do
    local link = GetInboxItemLink(mailIndex, attachmentIndex)
    if link ~= nil then
      return link
    end
  end
end

function JournalatorCraftingOrderMailMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    self.seenAttachments = {}

    for mailIndex = 1, (GetInboxNumItems()) do
      -- Ask for all mail so that player names get cached before a user opens
      -- the mail. This reduces the chance that buyer/seller names are missing.
      local orderDetails = C_Mail.GetCraftingOrderMailInfo(mailIndex)

      if orderDetails ~= nil then
        -- Keep the attachments for use after they've been removed from the mail
        self.seenAttachments[mailIndex] = GetFirstAttachment(mailIndex)
      end
    end

  -- Case when automatically closing mail because its being deleted due to
  -- being empty (e.g empty cancellation mail now you've taken the items)
  -- No further items can be taken until this message finishes being deleted, so
  -- we wait for it to finish.
  elseif eventName == "CLOSE_INBOX_ITEM" then
    local mailIndex = ...
    local orderDetails = C_Mail.GetCraftingOrderMailInfo(mailIndex)

    if orderDetails ~= nil then
      Journalator.Debug.Message("processing crafting order mail close")
      local subject = select(4, GetInboxHeaderInfo(mailIndex))
      self:ProcessMail(orderDetails, subject, self.seenAttachments[mailIndex])
    end
  end
end

function JournalatorCraftingOrderMailMonitorMixin:ProcessMail(orderDetails, subject, itemLink)
  if orderDetails.reason == Enum.RcoCloseReason.RcoCloseFulfill then
    -- Check to filter out corrupted entries from the API returning crafting
    -- order data even when there wasn't an order attached to the mail.
    if orderDetails.recipeName ~= "" then
      local entry = {
        recipeName = orderDetails.recipeName,
        commissionPaid = orderDetails.commissionPaid,
        crafterNote = orderDetails.crafterNote,
        crafterName = orderDetails.crafterName,
        itemLink = itemLink,
        source = Journalator.State.Source
      }
      if itemLink then
        local item = Item:CreateFromItemLink(itemLink)
        item:ContinueOnItemLoad(function()
          entry.itemName = item:GetItemName()
          entry.time = time()
          Journalator.AddToLogs({ CraftingOrdersSucceeded = { entry }})
        end)
      else
        entry.time = time()
        Journalator.AddToLogs({ CraftingOrdersSucceeded = { entry }})
      end
    else
      Journalator.Debug.Message("processing crafting order mail reject bad success")
    end
  else
    -- Its necessary to extract the item/recipe name from the subject for at
    -- least the cancelled orders (the recipe name is not in the orderDetails).
    -- Keeping the other recipe names extracted from subjects just in case they
    -- break too.
    local failType, altRecipeName
    if orderDetails.reason == Enum.RcoCloseReason.RcoCloseExpire then
      failType = "expire"
      altRecipeName = subject:match(expiredText)
    elseif orderDetails.reason == Enum.RcoCloseReason.RcoCloseCancel then
      failType = "cancel"
      altRecipeName = subject:match(cancelledText)
    elseif orderDetails.reason == Enum.RcoCloseReason.RcoCloseReject then
      failType = "reject"
      altRecipeName = subject:match(rejectText)
    elseif orderDetails.reason == Enum.RcoCloseReason.RcoCloseGmCancel  then
      failType = "gm"
    elseif orderDetails.reason == Enum.RcoCloseReason.RcoCloseInvalid then
      failType = "invalid"
    end
    if failType == nil then
      return
    end

    local recipeName = orderDetails.recipeName
    if recipeName == "" then
      recipeName = altRecipeName
    end

    Journalator.AddToLogs({ CraftingOrdersFailed = { {
      failType = failType,
      recipeName = recipeName,
      crafterNote = orderDetails.crafterNote,
      crafterName = orderDetails.crafterName,
      time = time(),
      source = Journalator.State.Source
    } }})
  end
end
