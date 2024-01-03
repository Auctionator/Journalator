JournalatorBasicMailReceiveMonitorMixin = {}

local CHECK_EVENTS = {
  "MAIL_SUCCESS",
  "MAIL_FAILED",
}

function JournalatorBasicMailReceiveMonitorMixin:OnLoad()
  hooksecurefunc("TakeInboxMoney", function(index)
    self:ProcessMail(index)
  end)
  hooksecurefunc("AutoLootMailItem", function(index)
    self:ProcessMail(index, true)
  end)
  hooksecurefunc("TakeInboxItem", function(index, itemIndex)
    self:ProcessMail(index, true)
  end)
end

function JournalatorBasicMailReceiveMonitorMixin:ProcessMail(index, codRequired)
  local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(index)

  if not canReply then
    Journalator.Debug.Message("basic mail ignored", index)
    return
  end

  -- No cash to pick up or cod to send
  if (codRequired and CODAmount == 0) or (not codRequired and money == 0) then
    return
  end

  Journalator.Debug.Message("basic mail recieved", index)

  local bodyText, stationeryID1, stationeryID2, isTakeable, isInvoice, isConsortium = GetInboxText(index)
  self.result = {
    sender = sender,
    subject = subject,
    text = bodyText,

    cod = CODAmount,
    money = money,
    items = nil,
    
    source = Journalator.State.Source,
  }
  self:StartListening()
end

function JournalatorBasicMailReceiveMonitorMixin:StartListening()
  FrameUtil.RegisterFrameForEvents(self, CHECK_EVENTS)
end

function JournalatorBasicMailReceiveMonitorMixin:StopListening()
  FrameUtil.UnregisterFrameForEvents(self, CHECK_EVENTS)
  self.result = nil
end

function JournalatorBasicMailReceiveMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_FAILED" then
    local data = ...
    if self.result.cod == 0 and data ~= nil then
      return
    end
    -- Either a cod with an item that failed to pickup or a no-item gold pickup
    -- that failed.
    self:StopListening()
  elseif eventName == "MAIL_SUCCESS" then
    assert(self.result)
    local data = ...
    if self.result.cod == 0 and data ~= nil then
      return
    end

    self.result.time = time()

    Journalator.AddToLogs({BasicMailReceived = { self.result } })

    self:StopListening()
  end
end
