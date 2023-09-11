JournalatorVendorRepairsMonitorMixin = {}

local MERCHANT_EVENTS = {
  "PLAYER_INTERACTION_MANAGER_FRAME_HIDE"
}

local REPAIR_VALIDATION_EVENTS = {
  "GUILDBANK_UPDATE_MONEY",
  "PLAYER_MONEY",
  "CHAT_MSG_SYSTEM",
  "UPDATE_INVENTORY_DURABILITY",
}

function JournalatorVendorRepairsMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, MERCHANT_EVENTS)

  self:RegisterRepairHandlers()
end

function JournalatorVendorRepairsMonitorMixin:RegisterRepairHandlers()
  hooksecurefunc("RepairAllItems", function(isGuild)
    if not CanMerchantRepair() or isGuild then
      return
    end

    self.repairBill = GetRepairAllCost()

    if self.repairBill == 0 then
      return
    end

    self.seenPlayerMoneyTransfer = false

    FrameUtil.RegisterFrameForEvents(self, REPAIR_VALIDATION_EVENTS)

    Journalator.Debug.Message("repair hook", GetMoneyString(self.repairBill))
  end)
end

function JournalatorVendorRepairsMonitorMixin:EndRepair()
  FrameUtil.UnregisterFrameForEvents(self, REPAIR_VALIDATION_EVENTS)
  self.seenPlayerMoneyTransfer = false
  self.repairBill = 0
end

function JournalatorVendorRepairsMonitorMixin:OnMerchantHide()
  self:EndRepair()
end

function JournalatorVendorRepairsMonitorMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local hideType = ...
    if hideType == Enum.PlayerInteractionType.Merchant then
      self:OnMerchantHide()
    end

  -- We listen to the guildback money events because some addons with autorepair
  -- may call the guild funded repair and the player funded repair at the same
  -- time. This way we filter out when the guild money has been used.
  elseif eventName == "GUILDBANK_UPDATE_MONEY" then
    Journalator.Debug.Message("repair guild money - stopping listening")
    self:EndRepair()

  elseif eventName == "PLAYER_MONEY" then
    self.seenPlayerMoneyTransfer = true

  elseif eventName == "CHAT_MSG_SYSTEM" then
    local message = ...
    if message == ERR_NOT_ENOUGH_MONEY then
      Journalator.Debug.Message("repair not enough money", message)
      self:EndRepair()
    end

  elseif eventName == "UPDATE_INVENTORY_DURABILITY" then
    if not self.seenPlayerMoneyTransfer then
      Journalator.Debug.Message("repair ignored no money transferred")
      return
    end

    local newBill = GetRepairAllCost()

    if newBill >= self.repairBill then
      Journalator.Debug.Message("repair ignored as bill increased/unchanged")
      self.repairBill = newBill
      return
    end

    local money = self.repairBill - newBill
    Journalator.Debug.Message("repair success", GetMoneyString(money, true))
    Journalator.AddToLogs({ VendorRepairs = {
      {
        money = money,
        time = time(),
        source = Journalator.State.Source,
      }
    }})
    self:EndRepair()
  end
end
