JournalatorTaxisMonitorMixin = {}

local TAXI_EVENTS_CLASSIC = {
  "TAXIMAP_CLOSED"
}

local TAXI_EVENTS_RETAIL = {
  "PLAYER_INTERACTION_MANAGER_FRAME_HIDE"
}

function JournalatorTaxisMonitorMixin:OnLoad()
  if PlayerInteractionFrameManager == nil then
    FrameUtil.RegisterFrameForEvents(self, TAXI_EVENTS_CLASSIC)
  else
    FrameUtil.RegisterFrameForEvents(self, TAXI_EVENTS_RETAIL)
  end

  hooksecurefunc("TakeTaxiNode", function(slot)
    if NumTaxiNodes() == 0 or TaxiNodeGetType(slot) ~= "REACHABLE" then
      Journalator.Debug.Message("taxi unreachable/closed")
      return
    end

    local cost = TaxiNodeCost(slot)
    if GetMoney() < cost then
      Journalator.Debug.Message("taxi unaffordable")
      return
    end

    local target = TaxiNodeName(slot)
    local origin = ""
    for i = 1, NumTaxiNodes() do
      if TaxiNodeGetType(i) == "CURRENT" then
        origin = TaxiNodeName(i)
        break
      end
    end

    local map = GetTaxiMapID()

    local zone = ""
    if map then
      local mapInfo = C_Map.GetMapInfo(map)
      if mapInfo then
        zone = mapInfo.name
      end
    end

    self.pending = {
      money = cost,
      target = target,
      origin = origin,
      map = map,
      zone = zone,
      source = Journalator.State.Source,
    }
  end)
end

function JournalatorTaxisMonitorMixin:OnTaxiHide()
  if self.pending == nil then
    return
  end
  self.pending.time = time()

  Journalator.AddToLogs({ Taxis = {
    self.pending
  }})
  self.pending = nil
end

function JournalatorTaxisMonitorMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then -- Dragonflight
    local showType = ...
    if showType == Enum.PlayerInteractionType.TaxiNode then
      self:OnTaxiHide()
    end
  elseif eventName == "TAXIMAP_CLOSED" then
    self:OnTaxiHide()
  end
end
