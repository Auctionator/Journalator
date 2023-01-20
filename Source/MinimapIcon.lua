local function GetMonthPeriod()
  local d = date("*t")
  d.day = 1
  return time() - (time(d) - 24 * 60 * 60 + C_DateAndTime.GetSecondsUntilDailyReset())
end

local function GetDayPeriod()
  return 24 * 60 * 60 - C_DateAndTime.GetSecondsUntilDailyReset()
end

local function GetProfitString(period)
  local profit = Journalator.GetProfit(time() - period, time())
  if profit < 0 then
    return RED_FONT_COLOR:WrapTextInColorCode("-" .. GetMoneyString(-profit, true))
  else
    return GREEN_FONT_COLOR:WrapTextInColorCode(GetMoneyString(profit, true))
  end
end

local icon = LibStub("LibDBIcon-1.0")

local isOpen = false
local isLoading = false
local function OnEnter(parent)
  isOpen = true
  GameTooltip:SetOwner(parent, "ANCHOR_BOTTOMLEFT")
  if not isLoading then
    isLoading = true
    local startPoint = time() - math.max(GetMonthPeriod(), GetDayPeriod())
    Journalator.Archiving.LoadUpTo(startPoint, function()
      isLoading = false
      if isOpen then
        GameTooltip:SetText(JOURNALATOR_L_JOURNALATOR)
        GameTooltip:AddDoubleLine(JOURNALATOR_L_MONTHLY_PROFIT, GetProfitString(GetMonthPeriod()))
        GameTooltip:AddDoubleLine(JOURNALATOR_L_DAILY_PROFIT, GetProfitString(GetDayPeriod()))
        GameTooltip:Show()
      end
    end, function(current, total)
      if isOpen then
        GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(JOURNALATOR_L_LOADING_X_X:format(current, total)))
        GameTooltip:Show()
      end
    end)
  end
end

local function OnLeave(parent)
  GameTooltip:Hide()
  isOpen = false
end

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
    OnEnter = OnEnter,
    OnLeave = OnLeave,
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
