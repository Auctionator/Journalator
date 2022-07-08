local function GetProfitString(period)
  local profit = Journalator.GetProfit(time() - period, time())
  if profit < 0 then
    return RED_FONT_COLOR:WrapTextInColorCode("-" .. Auctionator.Utilities.CreateMoneyString(-profit))
  else
    return GREEN_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreateMoneyString(profit))
  end
end

local function GetProfitMonthly()
  local d = date("*t")
  d.day = 1
  local monthStart = time(d) - 24 * 60 * 60 + C_DateAndTime.GetSecondsUntilDailyReset()
  return GetProfitString(time() - monthStart)
end

local function GetProfitDaily()
  return GetProfitString(24 * 60 * 60 - C_DateAndTime.GetSecondsUntilDailyReset())
end

local icon = LibStub("LibDBIcon-1.0")

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
        JNRView:SetShown(not JNRView:IsShown())
      end
    end,
    OnTooltipShow = function(tip)
      tip:SetText(JOURNALATOR_L_JOURNALATOR)
      tip:AddDoubleLine(JOURNALATOR_L_MONTHLY_PROFIT, GetProfitMonthly())
      tip:AddDoubleLine(JOURNALATOR_L_DAILY_PROFIT, GetProfitDaily())
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
