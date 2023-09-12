JournalatorTrainingCostsMonitorMixin = {}

local TRAINER_EVENTS = {
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
  "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
}
local EVENTS_WHEN_OPEN = {
  "TRAINER_UPDATE",
  "PLAYER_MONEY",
}

function JournalatorTrainingCostsMonitorMixin:OnLoad()
  self:Reset()

  FrameUtil.RegisterFrameForEvents(self, TRAINER_EVENTS)

  hooksecurefunc("BuyTrainerService", function(index)
    if not C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.Trainer) then
      return
    end
    self:QueuePurchaseAttempt(index)
  end)
end

function JournalatorTrainingCostsMonitorMixin:Reset()
  self.awaitingRemoval = {}
  self.payments = {}
  self.awaitingPayment = {}
end

local function GetAvailableServiceClassic(index)
  local serviceName, serviceSubText, serviceType = GetTrainerServiceInfo(index)

  if serviceType ~= "available" then
    return
  end

  local price = GetTrainerServiceCost(index)

  local skillLineText = GetTrainerServiceSkillLine(index)

  local text = serviceName

  if serviceSubText and serviceSubText ~= "" then
    text = text .. " (" .. serviceSubText .. ")"
  end

  local requirement
  local skill, rank = GetTrainerServiceSkillReq(index)
  if skill then
    requirement = skill .. " (" .. rank .. ")"
  end

  return {label = text, group = skillLineText, cost = price, requirement = requirement}
end

local function GetAvailableServiceRetail(index)
  local serviceName, serviceType = GetTrainerServiceInfo(index)

  if serviceType ~= "available" then
    return
  end

  local price = GetTrainerServiceCost(index)

  local skillLineText = GetTrainerServiceSkillLine(index)

  local requirement

  if IsTradeskillTrainer() then
    local skill, rank, hasReq = GetTrainerServiceSkillReq(index)
    if skill then
      requirement = skill .. " (" .. rank .. ")"
    end
  end

  return {label = serviceName, group = skillLineText, cost = price, requirement = requirement}
end

function JournalatorTrainingCostsMonitorMixin:QueuePurchaseAttempt(index)
  local details
  if Journalator.Constants.IsClassic then
    details = GetAvailableServiceClassic(index)
  else
    details = GetAvailableServiceRetail(index)
  end

  if details.cost > GetMoney() then
    return
  end

  for _, item in ipairs(self.awaitingRemoval) do
    if item.label == details.label then
      return
    end
  end

  self.awaitingRemoval[details] = true
end

function JournalatorTrainingCostsMonitorMixin:LogPurchase(item)
  Journalator.Utilities.GetNPCDetailsFromGUID(self.npcGUID, function(details)
    Journalator.AddToLogs({ TrainingCosts = {
      {
        money = item.cost,
        item = item.label,
        group = item.group,
        requirements = item.requirement,
        trainer = CopyTable(details),
        source = Journalator.State.Source,
        time = time()
      }
    }})
  end)
end

function JournalatorTrainingCostsMonitorMixin:TrainerUpdate()
  self:SetScript("OnUpdate", nil)

  for item in pairs(self.awaitingRemoval) do
    local found = false
    for index = 1, GetNumTrainerServices() do
      local details
      if Journalator.Constants.IsClassic then
        details = GetAvailableServiceClassic(index)
      else
        details = GetAvailableServiceRetail(index)
      end
      if details and details.label == item.label then
        found = true
      end
    end

    if not found then
      self.awaitingRemoval[item] = nil
      if item.cost == 0 then
        self:LogPurchase(item)
      else
        -- See if the payment has been taken
        local costIndex = tIndexOf(self.payments, item.cost)
        if costIndex ~= nil then
          table.remove(self.payments, costIndex)
          self:LogPurchase(item)
        else
          -- Wait for the payment
          self.awaitingPayment[item] = true
        end
      end
    end
  end
end

-- Watch for events indicating a specific service was acquired and paid for
function JournalatorTrainingCostsMonitorMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local showType = ...
    if showType == Enum.PlayerInteractionType.Trainer then
      FrameUtil.RegisterFrameForEvents(self, EVENTS_WHEN_OPEN)
      self:Reset()
      self.money = GetMoney()
      self.npcGUID = UnitGUID("npc")
    end

  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local showType = ...
    if showType == Enum.PlayerInteractionType.Trainer then
      self:Reset()
      FrameUtil.UnregisterFrameForEvents(self, EVENTS_WHEN_OPEN)
    end

  -- Watch for outgoing payments corresponding to the service bought
  elseif eventName == "PLAYER_MONEY" then
    local diff = self.money - GetMoney()
    self.money = GetMoney()
    local found = false
    -- See if a corresponding service has been removed from the available list
    for item in pairs(self.awaitingPayment) do
      if item.cost == diff then
        found = true
        self.awaitingPayment[item] = nil
        self:LogPurchase(item)
      end
    end
    if not found then
      table.insert(self.payments, diff)
    end

  -- Watch for services being removed from the available list
  elseif eventName == "TRAINER_UPDATE" then
    self:SetScript("OnUpdate", self.TrainerUpdate)
  end
end
