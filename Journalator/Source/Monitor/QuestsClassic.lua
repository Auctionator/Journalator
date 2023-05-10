JournalatorQuestsClassicMonitorMixin = {}

local REP_INCREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_INCREASED)
local REP_DECREASED_PATTERN = Journalator.Utilities.GetChatPattern(FACTION_STANDING_DECREASED)

local function GetKeyByID(questID)
  return "quests-" .. questID
end

function JournalatorQuestsClassicMonitorMixin:OnLoad()
  self.pendingQuests = {}

  self.rewardTimers = {} -- Wait QUEST_LOOT_DELAY seconds to make sure all the rewards are obtained

  FrameUtil.RegisterFrameForEvents(self, {
    "QUEST_TURNED_IN",
    "PLAYER_LEAVING_WORLD",
  })

  self.selectedChoice = {}
  hooksecurefunc("GetQuestReward", function(choice)
    local questID = GetQuestID()

    self:EarlyCompleteCheck(questID)

    self.selectedChoice[questID] = choice
    self.reputationMonitor:SetReportKey(GetKeyByID(questID))
    Journalator.Debug.Message("get quest reward hook", questID, choice)
  end)
end

function JournalatorQuestsClassicMonitorMixin:SetReputationMonitor(monitor)
  self.reputationMonitor = monitor
end

function JournalatorQuestsClassicMonitorMixin:OnEvent(eventName, ...)
  if eventName == "QUEST_TURNED_IN" then
    local questID, experience, money = ...

    self:EarlyCompleteCheck(questID)

    Journalator.Debug.Message("quest turned in", questID, experience, money)
    local questInfo = {
      state = "turned in",
      rewardItems = nil,
      rewardCurrencies = nil,
      questID = questID,
      questName = nil,
      experience = experience,
      rewardMoney = 0,
      requiredMoney = nil,
      time = time(),
      map = C_Map.GetBestMapForUnit("player"),
      source = Journalator.State.Source,
    }
    if money >= 0 then
      questInfo.rewardMoney = money
    else
      questInfo.requiredMoney = -money
    end
    self.pendingQuests[questID] = questInfo

    self:PredictRewards(questID)

    self.rewardTimers[questID] = C_Timer.NewTimer(Journalator.Constants.QUEST_REWARD_DELAY, function()
      Journalator.Debug.Message("quest reward timer finished", questID)
      self.rewardTimers[questID] = nil
      self:CheckForCompleted(questID)
    end)

    -- Trigger quest name loading for classic
    local questName = QuestUtils_GetQuestName(questID)
    if questName ~= "" then
      questInfo.questName = questName
    else
      Journalator.Debug.Message("quest classic turn in no name", questID)
    end
    self:CheckForCompleted(questID)

  elseif eventName == "QUEST_DATA_LOAD_RESULT" then
    local questID, success = ...
    local questInfo = self.pendingQuests[questID]
    if questInfo and questInfo.questName == nil then
      if success then
        self.pendingQuests[questID].questName = QuestUtils_GetQuestName(questID)
        self:CheckForCompleted(questID)
      else
        self:RemoveQuest(questID)
      end
    end

  elseif eventName == "PLAYER_LEAVING_WORLD" then
    for questID in pairs(self.pendingQuests) do
      if self.rewardTimers[questID] then
        self.rewardTimers[questID]:Cancel()
        self.rewardTimers[questID] = nil
        self:CheckForCompleted(questID)
      end
    end
  end
end

-- Assumes quest is currently focussed in quest hand in screen
function JournalatorQuestsClassicMonitorMixin:PredictRewards(questID)
  local items = {}
  local currencies = {}

  local basicRewards = GetNumQuestRewards()
  for i = 1, basicRewards do
    local itemLink = GetQuestItemLink("reward", i)
    local quantity = select(3, GetQuestItemInfo("reward", i))
    table.insert(items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  end

  local choice = self.selectedChoice[questID]
  if choice ~= nil and choice ~= 0 then
    local itemLink = GetQuestItemLink("choice", choice)
    local quantity = select(3, GetQuestItemInfo("choice", choice))
    table.insert(items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  end

  -- Only Wrath onwards has currencies
  if GetNumRewardCurrencies then
    local currencyRewards = GetNumRewardCurrencies()
    for i = 1, currencyRewards do
      local currencyID = GetQuestCurrencyID("reward", i)
      local quantity = select(3, GetQuestCurrencyInfo("reward", i))
      table.insert(currencies, {
        currencyID = currencyID,
        quantity = quantity,
      })
    end
  end

  self.pendingQuests[questID].rewardItems = items
  self.pendingQuests[questID].rewardCurrencies = currencies
end

function JournalatorQuestsClassicMonitorMixin:HasAnyRewards(questInfo)
  return #questInfo.rewardItems > 0 or #questInfo.rewardCurrencies > 0 or #questInfo.reputationChanges > 0 or questInfo.experience > 0 or questInfo.rewardMoney > 0
end

function JournalatorQuestsClassicMonitorMixin:HasAnyCosts(questInfo)
  return questInfo.requiredMoney ~= nil and questInfo.requiredMoney > 0
end

function JournalatorQuestsClassicMonitorMixin:RemoveQuest(questID)
  Journalator.Debug.Message("removed jnr", questID)
  self.pendingQuests[questID] = nil
  self.selectedChoice[questID] = nil

  if self.rewardTimers[questID] then
    self.rewardTimers[questID]:Cancel()
    self.rewardTimers[questID] = nil
  end

  self.reputationMonitor:ClearByKey(GetKeyByID(questID))
end

function JournalatorQuestsClassicMonitorMixin:CheckForCompleted(questID)
  local questInfo = self.pendingQuests[questID]
  local currentName = self.pendingQuests[questID].questName
  if currentName ~= nil and self.rewardTimers[questID] == nil then
    questInfo.reputationChanges = self.reputationMonitor:GetByKey(GetKeyByID(questID))
    Journalator.Debug.Message("quest accept", questID, #questInfo.rewardItems, #questInfo.rewardCurrencies)
    -- Don't record any empty quests
    if self:HasAnyRewards(questInfo) or self:HasAnyCosts(questInfo) then
      Journalator.AddToLogs({Questing = {questInfo}})
    end
    self:RemoveQuest(questID)
  else
    Journalator.Debug.Message("quest reject not loaded", questID, currentName ~= nil)
  end
end

function JournalatorQuestsClassicMonitorMixin:EarlyCompleteCheck(questID)
  if self.pendingQuests[questID] then
    if self.rewardTimers[questID] then
      self.rewardTimers[questID]:Cancel()
      self.rewardTimers[questID] = nil
    end
    self:CheckForCompleted(questID)
  end
end
