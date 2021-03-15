local function GetProfitString(period)
  local profit = Journalator.GetProfit(period)
  if profit < 0 then
    return "-" .. RED_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreateMoneyString(-profit))
  else
    return GREEN_FONT_COLOR:WrapTextInColorCode(Auctionator.Utilities.CreateMoneyString(profit))
  end
end

local function GetProfitMonthly()
  return GetProfitString(Journalator.Constants.SECONDS_IN_A_MONTH)
end

local function GetProfitDaily()
  return GetProfitString(Journalator.Constants.SECONDS_IN_A_DAY)
end

function Journalator_LDB_Initialize()
  Journalator_LDB_SetupLauncher()
end

function Journalator_LDB_SetupLauncher()
  local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
  local dataObj = ldb:NewDataObject("Journalator Launcher", {
    type = "launcher",
    icon = "Interface\\AddOns\\Journalator-LDB\\Images\\icon",
    label = JOURNALATOR_L_JOURNALATOR,
    tocname = "Journalator",
    OnClick = function(clickedframe, button)
      JNRView:SetShown(not JNRView:IsShown())
    end,
    OnTooltipShow = function(tip)
      tip:SetText(JOURNALATOR_L_JOURNALATOR, 1, 1, 1)
      tip:AddDoubleLine(JOURNALATOR_L_MONTHLY_PROFIT, GetProfitMonthly())
      tip:AddDoubleLine(JOURNALATOR_L_DAILY_PROFIT, GetProfitDaily())
      tip:Show()
    end
  })
end

