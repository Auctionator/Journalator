JournalatorReputationMonitorMixin = {}

local REP_INCREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_INCREASED)
local REP_DECREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_DECREASED)

function JournalatorReputationMonitorMixin:OnLoad()
  self.reportKey = nil
  self.logged = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "CHAT_MSG_COMBAT_FACTION_CHANGE",
  })
end

function JournalatorReputationMonitorMixin:OnEvent(eventName, ...)
  if eventName == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    if self.reportKey == nil then
      return
    end

    local text = ...

    Journalator.Debug.Message("quest classic faction change", text)

    local faction, amount = text:match(REP_INCREASED_PATTERN)
    local multiplier = 1
    if faction == nil or amount == nil then
      faction, amount = text:match(REP_DECREASED_PATTERN)
      multiplier = -1
    end

    if faction == nil or amount == nil then
      return
    end

    amount = Journalator.Utilities.CleanNumberString(amount)
    if amount == nil then
      return
    end
    amount = amount * multiplier

    self.logged[self.reportKey] = self.logged[self.reportKey] or {}
    table.insert(self.logged[self.reportKey], {
      factionName = faction,
      reputationChange = amount,
    })
    Journalator.Debug.Message("reputation recorded", self.reportKey, faction, amount)
  end
end

function JournalatorReputationMonitorMixin:SetReportKey(reportKey)
  self.reportKey = reportKey
end

function JournalatorReputationMonitorMixin:ClearByKey(reportKey)
  self.logged[reportKey] = nil
  self.reportKey = nil
end

function JournalatorReputationMonitorMixin:GetByKey(reportKey)
  return self.logged[reportKey] or {}
end
