JournalatorTradingPostMonitorMixin = {}

function JournalatorTradingPostMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PERKS_PROGRAM_PURCHASE_SUCCESS",
    "PERKS_PROGRAM_REFUND_SUCCESS",
  })
end

local function ProcessItemInfo(vendorItemID, isRefund)
  Journalator.Debug.Message("journalator trading post action", vendorItemID, isRefund)
  local vendorItemInfo = C_PerksProgram.GetVendorItemInfo(vendorItemID)
  local item = Item:CreateFromItemID(vendorItemInfo.itemID)
  item:ContinueOnItemLoad(function()
    local name, link = GetItemInfo(vendorItemInfo.itemID)
    Journalator.Debug.Message("journalator trading post link", link)
    Journalator.AddToLogs({ TradingPostVendoring = {
      {
        itemName = name,
        price = vendorItemInfo.price,
        currencyID = Constants.CurrencyConsts.CURRENCY_ID_PERKS_PROGRAM_DISPLAY_INFO,
        time = time(),
        itemLink = link,
        source = Journalator.State.Source,
        isRefund = isRefund,
      }
    }})
  end)
end

function JournalatorTradingPostMonitorMixin:OnEvent(event, ...)
  if event == "PERKS_PROGRAM_PURCHASE_SUCCESS" then
    local vendorItemID = ...
    ProcessItemInfo(vendorItemID, false)
  elseif event == "PERKS_PROGRAM_REFUND_SUCCESS" then
    local vendorItemID = ...
    ProcessItemInfo(vendorItemID, true)
  end
end
