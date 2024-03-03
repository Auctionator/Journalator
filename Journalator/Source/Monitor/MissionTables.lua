JournalatorMissionTablesMonitorMixin = {}

function JournalatorMissionTablesMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "GARRISON_MISSION_BONUS_ROLL_COMPLETE",
    "GARRISON_MISSION_BONUS_ROLL_LOOT",
  })
end

function JournalatorMissionTablesMonitorMixin:OnEvent(eventName, ...)
  if eventName == "GARRISON_MISSION_BONUS_ROLL_COMPLETE" then
    self.missionID = ...
    self.missionName = C_Garrison.GetMissionName(self.missionID)
  elseif eventName == "GARRISON_MISSION_BONUS_ROLL_LOOT" then
    local itemID, count = ...
    local money, itemCount = 0, 0
    if itemID == 0 then
      money = count
    else
      itemCount = count
    end

    local tableType
    if GarrisonMissionFrame:IsShown() then
      tableType = Journalator.Constants.MissionTableTypes.Draenor
    elseif OrderHallMissionFrame:IsShown() then
      tableType = Journalator.Constants.MissionTableTypes.Legion
    elseif CovenantMissionFrame:IsShown() then
      tableType = Journalator.Constants.MissionTableTypes.Shadowlands
    elseif BFAMissionFrameMissions:IsShown() then
      tableType = Journalator.Constants.MissionTableTypes.BattleForAzeroth
    end

    if count > 0 then
      Journalator.AddToLogs({ MissionTables = {
        {
          missionID = self.missionID,
          missionName = self.missionName,
          tableType = tableType,
          money = money,
          itemCount = itemCount,
          itemID = itemID,
          time = time(),
          source = Journalator.State.Source,
        }
      }})
    end
  end
end
