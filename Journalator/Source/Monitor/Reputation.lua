JournalatorReputationMonitorMixin = {}

local REP_INCREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_INCREASED)
local REP_DECREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_DECREASED)

function JournalatorReputationMonitorMixin:OnLoad()
  self.reportKey = nil
  self.logged = {}
  self.recentNotLogged = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "CHAT_MSG_COMBAT_FACTION_CHANGE",
  })
end

function JournalatorReputationMonitorMixin:OnEvent(eventName, ...)
  if eventName == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    local text = ...

    if self.reportKey == nil then
      table.insert(self.recentNotLogged, {
        time = GetTime(),
        text = text,
      })
      self:ClearOldRecents()
      Journalator.Debug.Message("reputation recents", text)
      return
    end

    self:ProcessText(text)
  end
end

function JournalatorReputationMonitorMixin:ClearOldRecents()
  local time = GetTime()
  while self.recentNotLogged[1] and (time - self.recentNotLogged[1].time) > Journalator.Constants.EARLY_REPUTATION_DELAY do
    table.remove(self.recentNotLogged, 1)
  end
end

function JournalatorReputationMonitorMixin:ProcessText(text)
  Journalator.Debug.Message("reputation change", text)

  local factionName, amount = text:match(REP_INCREASED_PATTERN)
  local multiplier = 1
  if factionName == nil or amount == nil then
    factionName, amount = text:match(REP_DECREASED_PATTERN)
    multiplier = -1
  end

  if factionName == nil or amount == nil then
    return
  end

  amount = Journalator.Utilities.CleanNumberString(amount)
  if amount == nil then
    return
  end
  amount = amount * multiplier

  local entry = {
    reputationChange = amount,
  }

  local factionID = Journalator.Utilities.GetFactionID(factionName)

  if factionID ~= nil then
    entry.factionID = factionID
  else
    entry.factionName = factionName
  end

  self.logged[self.reportKey] = self.logged[self.reportKey] or {}
  table.insert(self.logged[self.reportKey], entry)
  Journalator.Debug.Message("reputation recorded", self.reportKey, factionName, factionID, amount)
end

function JournalatorReputationMonitorMixin:SetReportKey(reportKey, importRecents)
  self.reportKey = reportKey

  if importRecents then
    self:ClearOldRecents()
    for _, recent in ipairs(self.recentNotLogged) do
      self:ProcessText(recent.text)
    end
  end
  self.recentNotLogged = {}
end

function JournalatorReputationMonitorMixin:ClearByKey(reportKey)
  self.logged[reportKey] = nil
  self.reportKey = nil
end

function JournalatorReputationMonitorMixin:GetByKey(reportKey)
  return self.logged[reportKey] or {}
end
