WOW_TOKEN_EVENTS = {
  "TOKEN_BUY_RESULT",
}

JournalatorWoWTokensMonitorMixin = {}

function JournalatorWoWTokensMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, WOW_TOKEN_EVENTS)
end

function JournalatorWoWTokensMonitorMixin:OnEvent(eventName, ...)
  if eventName == "TOKEN_BUY_RESULT" then
    local result = ...
    if result ~= LE_TOKEN_RESULT_SUCCESS then
      return
    end

    local value = C_WowTokenPublic.GetCurrentMarketPrice()

    local item = Item:CreateFromItemID(WOW_TOKEN_ITEM_ID)
    item:ContinueOnItemLoad(function()
      local itemName, itemLink = GetItemInfo(WOW_TOKEN_ITEM_ID)

      Journalator.AddToLogs({ WoWTokens = {
        {
        itemName = itemName,
        itemLink = itemLink,
        type = "buy",
        quantity = 1,
        value = value,
        time = time(),
        source = Journalator.State.Source,
        },
      }})
    end)
  end
end
