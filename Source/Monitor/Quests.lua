JournalatorQuestsMonitorMixin = {}

function JournalatorQuestsMonitorMixin:OnLoad()
  self.pendingQuests = {}
  self.removed = {}
  self.rewardItems = {}
  self.rewardCurrencies = {}
  self.lootExpectedCount = {}

  FrameUtil.RegisterFrameForEvents(self, {
    "QUEST_TURNED_IN",
    "QUEST_REMOVED",
  })
  if not Auctionator.Constants.IsClassic then
    FrameUtil.RegisterFrameForEvents(self, {
      "QUEST_LOOT_RECEIVED",
      "QUEST_CURRENCY_LOOT_RECEIVED",
      "QUEST_DATA_LOAD_RESULT",
    })
  end

  if Auctionator.Constants.IsClassic then
    self.selectedChoice = {}
    hooksecurefunc("GetQuestReward", function(choice)
      local questID = GetQuestID()
      self.selectedChoice[questID] = choice
    end)
  end
end

function JournalatorQuestsMonitorMixin:OnEvent(eventName, ...)
  if eventName == "QUEST_TURNED_IN" then
    local questID, experience, money = ...
    Journalator.Debug.Message("quest turned in", questID, experience, money)
    local questInfo = {
      state = "turned in",
      rewardItems = nil,
      rewardCurrencies = nil,
      questID = questID,
      questName = nil,
      experience = experience,
      isWorldQuest = self:IsWorldQuest(questID),
      rewardMoney = money,
      time = time(),
      source = Journalator.State.Source,
    }
    self.pendingQuests[questID] = questInfo

    if Auctionator.Constants.IsClassic then
      -- Trigger quest name loading for classic
      local questName = QuestUtils_GetQuestName(questID)
      if questName ~= "" then
        questInfo.questName = questName
      else
        Journalator.Debug.Message("quest classic turn in no name", questID)
      end

      self:GetExpectedRewardCounts(questID)
      self:PredictRewards(questID)
      self:CheckForCompleted()

    else
      C_QuestLog.RequestLoadQuestByID(questInfo.questID)
      self:SetScript("OnUpdate", self.RewardsCheck)
    end

  elseif eventName == "QUEST_DATA_LOAD_RESULT" then
    local questID, success = ...
    local questInfo = self.pendingQuests[questID]
    if questInfo and questInfo.questName == nil then
      if success then
        self:FillInName(questID)
      else
        self:RemoveQuest(questID)
      end
    end

  -- Retail only to catch extra items
  elseif eventName == "QUEST_LOOT_RECEIVED" then
    local questID, itemLink, quantity = ...
    self.rewardItems[questID] = self.rewardItems[questID] or {}

    Journalator.Debug.Message("quest loot recieved", questID, itemLink, quantity)
    table.insert(self.rewardItems[questID], {
      itemLink = itemLink,
      quantity = quantity,
    })

    self:CheckForCompleted()

  -- Retail only to catch extra items
  elseif eventName == "QUEST_CURRENCY_LOOT_RECEIVED" then
    local questID, currencyID, quantity = ...
    self.rewardCurrencies[questID] = self.rewardCurrencies[questID] or {}

    Journalator.Debug.Message("quest currency loot recieved", questID, currencyID, quantity)
    table.insert(self.rewardCurrencies[questID], {
      currencyID = currencyID,
      quantity = quantity,
    })

    self:CheckForCompleted()

  elseif eventName == "QUEST_REMOVED" then
    local questID, isReplay = ...
    self.removed[questID] = true
    self:CheckForCompleted()
  end
end

-- Retail only
function JournalatorQuestsMonitorMixin:RewardsCheck()
  local anyWaiting = false
  for questID, questInfo in pairs(self.pendingQuests) do
    if self.lootExpectedCount[questID] == nil then
      if HaveQuestRewardData(questID) then
        self:GetExpectedRewardCounts(questID)
      else
        if self:IsWorldQuest(questID) then
          C_TaskQuest.RequestPreloadRewardData(questID)
        end
        anyWaiting = true
      end
    end
  end
  if not anyWaiting then
    self:SetScript("OnUpdate", nil)
  end
end

function JournalatorQuestsMonitorMixin:IsWorldQuest(questID)
  return C_QuestLog and C_QuestLog.IsWorldQuest and (C_QuestLog.IsWorldQuest(questID) or C_QuestLog.IsQuestTask(questID))
end

-- Retail mainly. This won't error on classic though, and is left to keep as
-- many similarities between the mainline and classic code as possible.
-- The checks are to get the quest data correctly for world quests, as they
-- don't use the normal quest APIs
-- This function tries to predict how many rewards should be found, for WQs that
-- may exceed these numbers, but it prevents rewards from getting skipped with
-- regular quests.
function JournalatorQuestsMonitorMixin:GetExpectedRewardCounts(questID)
  local isWorldQuest = self:IsWorldQuest(questID)

  Journalator.Debug.Message("numquestrewards", GetNumQuestLogRewards(questID), GetNumQuestRewards())
  if isWorldQuest then
    self.lootExpectedCount[questID] = GetNumQuestLogRewards(questID)
  else
    self.lootExpectedCount[questID] = GetNumQuestRewards()
  end

  if (not isWorldQuest and GetNumQuestChoices() > 0) or (isWorldQuest and GetNumQuestLogChoices(questID) > 0) then
    self.lootExpectedCount[questID] = self.lootExpectedCount[questID] + 1
  end
  Journalator.Debug.Message("numquestchoices", GetNumQuestLogChoices(questID), GetNumQuestChoices())

  if isWorldQuest then
    self.lootExpectedCount[questID] = self.lootExpectedCount[questID] + GetNumQuestLogRewardCurrencies(questID)
  else
    self.lootExpectedCount[questID] = self.lootExpectedCount[questID] + GetNumRewardCurrencies()
  end

  Journalator.Debug.Message("numquestrewardcurrencies", GetNumQuestLogRewardCurrencies(questID), GetNumRewardCurrencies())
  Journalator.Debug.Message("quest name got", questID, self.lootExpectedCount[questID])

  self:CheckForCompleted()
end

function JournalatorQuestsMonitorMixin:FillInName(questID)
  self.pendingQuests[questID].questName = QuestUtils_GetQuestName(questID)

  self:CheckForCompleted()
end

-- Classic ONLY
-- Assumes quest is currently focussed in quest hand in screen
function JournalatorQuestsMonitorMixin:PredictRewards(questID)
  local items = {}
  local currencies = {}

  local basicRewards = GetNumQuestRewards()
  for i = 1, basicRewards do
    local itemLink = GetQuestItemLink("reward", i)
    local quantity = select(4, GetQuestItemInfo("reward", i))
    table.insert(items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  end

  local choice = self.selectedChoice[questID]
  if choice ~= nil and choice ~= 0 then
    local itemLink = GetQuestItemLink("choice", choice)
    local quantity = select(4, GetQuestItemInfo("choice", choice))
    table.insert(items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  end

  local basicRewards = GetNumQuestRewards()
  for i = 1, basicRewards do
    local itemLink = GetQuestItemLink("reward", i)
    local quantity = select(4, GetQuestItemInfo("reward", i))
    table.insert(items, {
      itemLink = itemLink,
      quantity = quantity,
    })
  end

  local currencyRewards = GetNumRewardCurrencies()
  for i = 1, currencyRewards do
    local currencyID = GetQuestCurrencyID("reward", i)
    local quantity = select(3, GetQuestCurrencyInfo("reward", i))
    table.insert(currencies, {
      currencyID = currencyID,
      quantity = quantity,
    })
  end
  self.rewardItems[questID] = items
  self.rewardCurrencies[questID] = currencies
end

function JournalatorQuestsMonitorMixin:HasAnyRewards(questInfo)
  return #questInfo.rewardItems > 0 or #questInfo.rewardCurrencies > 0 or questInfo.experience > 0 or questInfo.rewardMoney > 0
end

function JournalatorQuestsMonitorMixin:RemoveQuest(questID)
  Journalator.Debug.Message("removed", questID)
  self.pendingQuests[questID] = nil
  self.rewardItems[questID] = nil
  self.rewardCurrencies[questID] = nil
  self.lootExpectedCount[questID] = nil
  self.removed[questID] = nil

  if Auctionator.Constants.IsClassic then
    self.selectedChoice[questID] = nil
  end
end

function JournalatorQuestsMonitorMixin:CheckForCompleted()
  for questID, questInfo in pairs(self.pendingQuests) do
    local currentName = self.pendingQuests[questID].questName ~= nil
    if currentName ~= nil and self.removed[questID] and self.lootExpectedCount[questID] ~= nil then
      local wantedCount = self.lootExpectedCount[questID]
      local items = self.rewardItems[questID] or {}
      local currencies = self.rewardCurrencies[questID] or {}
      if #items + #currencies >= wantedCount then
        Journalator.Debug.Message("quest accept", questID, #items + #currencies, wantedCount)
        questInfo.rewardItems = items
        questInfo.rewardCurrencies = currencies
        -- Don't record any empty quests
        if self:HasAnyRewards(questInfo) then
          Journalator.AddToLogs({Questing = {questInfo}})
        end
        self:RemoveQuest(questID)
      else
        Journalator.Debug.Message("quest reject not enough loot", questID, wantedCount, #items + #currencies)
      end
    else
      Journalator.Debug.Message("quest reject not loaded", questID)
    end
  end
end
