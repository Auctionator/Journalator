local function GetMonthPeriod()
  local origin = time()
  local resetTime = date("*t", origin - 24 * 60 * 60 + C_DateAndTime.GetSecondsUntilDailyReset())
  local d = date("*t")
  d.min = resetTime.min
  d.hour = resetTime.hour
  d.sec = resetTime.sec
  d.day = 1
  local result = time(d)
  if result > origin then
    d.month = d.month - 1
    if d.month < 1 then
      d.month = 12
      d.year = d.year - 1
    end
  end
  return origin - time(d)
end

local function GetWeekPeriod()
  return 7 * 24 * 60 * 60 - C_DateAndTime.GetSecondsUntilWeeklyReset()
end

local function GetDayPeriod()
  return 24 * 60 * 60 - C_DateAndTime.GetSecondsUntilDailyReset()
end

local function GetProfitString(period)
  local profit = Journalator.GetProfit(time() - period, time(), function(item)
    return not item.playerCheck or Journalator.CheckCharacter(item.playerCheck, item.source)
  end)
  if profit < 0 then
    return RED_FONT_COLOR:WrapTextInColorCode("-" .. GetMoneyString(-profit, true))
  else
    return GREEN_FONT_COLOR:WrapTextInColorCode(GetMoneyString(profit, true))
  end
end

local icon = LibStub("LibDBIcon-1.0")

Journalator.MinimapIcon = {}

function Journalator.MinimapIcon.Initialize()
  local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
  local dataObj = ldb:NewDataObject("Journalator", {
    type = "launcher",
    icon = "Interface\\AddOns\\Journalator\\Images\\icon",
    label = JOURNALATOR_L_JOURNALATOR,
    tocname = "Journalator",
    OnClick = function(clickedframe, button)
      if button == "RightButton" then
        Journalator.Config.Show()
      else
        Journalator.ToggleView()
      end
    end,
    OnTooltipShow = function(tip)
      tip:SetText(JOURNALATOR_L_JOURNALATOR)

      local startPoint = time() - math.max(GetMonthPeriod(), GetDayPeriod())
      if Journalator.Archiving.IsLoadedUpTo(startPoint) then
        tip:AddDoubleLine(WHITE_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_MONTHLY_PROFIT), GetProfitString(GetMonthPeriod()))
        tip:AddDoubleLine(WHITE_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_WEEKLY_PROFIT), GetProfitString(GetWeekPeriod()))
        tip:AddDoubleLine(WHITE_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_DAILY_PROFIT), GetProfitString(GetDayPeriod()))
      else
        tip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_OPEN_TO_SEE_STATS))
      end
      tip:Show()
    end
  })

  icon:Register("Journalator", dataObj, Journalator.Config.Get(Journalator.Config.Options.MINIMAP_ICON))
end

function Journalator.MinimapIcon.UpdateShown()
  if Journalator.Config.Get(Journalator.Config.Options.MINIMAP_ICON).hide then
    icon:Hide("Journalator")
  else
    icon:Show("Journalator")
  end
end
