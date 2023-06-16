JournalatorBasicMailSendMonitorMixin = {}

local CHECK_EVENTS = {
  "MAIL_SEND_SUCCESS",
  "MAIL_FAILED",
}

function JournalatorBasicMailSendMonitorMixin:OnLoad()
  hooksecurefunc("SendMail", function(recipient, subject, body)
    if self.result then
      return
    end

    self:StartListening()

    self.result = {
      recipient = recipient,
      subject = subject,
      text = body,

      cod = GetSendMailCOD(),
      money = GetSendMailMoney(),
      items = {},

      source = Journalator.State.Source
    }

    for index = 1, ATTACHMENTS_MAX_SEND do
      local itemLink = GetSendMailItemLink(index)
      if itemLink ~= nil then
        local quantity = select(4, GetSendMailItem(index))
        table.insert(self.result.items, {
          itemLink = itemLink,
          quantity = quantity,
        })
      end
    end
  end)
end

function JournalatorBasicMailSendMonitorMixin:StartListening()
  FrameUtil.RegisterFrameForEvents(self, CHECK_EVENTS)
end

function JournalatorBasicMailSendMonitorMixin:StopListening()
  FrameUtil.UnregisterFrameForEvents(self, CHECK_EVENTS)
  self.result = nil
end

function JournalatorBasicMailSendMonitorMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_FAILED" then
    self:StopListening()
  elseif eventName == "MAIL_SEND_SUCCESS" then
    assert(self.result)

    self.result.time = time()

    Journalator.AddToLogs({BasicMailSent = { self.result } })

    self:StopListening()
  end
end
