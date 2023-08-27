JournalatorTradesMonitorMixin = {}

local TRADE_EVENTS = {
  "TRADE_SHOW",
  "TRADE_UPDATE",
  "TRADE_PLAYER_ITEM_CHANGED",
  "TRADE_TARGET_ITEM_CHANGED",
  "TRADE_MONEY_CHANGED",
  "UI_INFO_MESSAGE",
}

function JournalatorTradesMonitorMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, TRADE_EVENTS)

  hooksecurefunc("SetTradeMoney", function(money)
    if self.queuedTrade ~= nil then
      self.queuedTrade.moneyOut = money
    end
  end)
end

function JournalatorTradesMonitorMixin:NewTrade()
  self.queuedTrade = {
    moneyOut = 0,
    moneyIn = 0,
    itemsOut = {},
    itemsIn = {},
    player = GetUnitName("NPC", true),
    source = Journalator.State.Source,
  }
end

function JournalatorTradesMonitorMixin:UpdateItemsOut()
  local itemsOut = {}
  for id = 1, MAX_TRADABLE_ITEMS do
    local _, _, quantity = GetTradePlayerItemInfo(id)
    local itemLink = GetTradePlayerItemLink(id)

    if itemLink ~= nil then
      table.insert(itemsOut, { quantity = quantity, itemLink = itemLink })
    end
  end
  self.queuedTrade.itemsOut = itemsOut
end

function JournalatorTradesMonitorMixin:UpdateItemsIn()
  local itemsIn = {}
  for id = 1, MAX_TRADABLE_ITEMS do
    local _, _, quantity = GetTradeTargetItemInfo(id)
    local itemLink = GetTradeTargetItemLink(id)

    if itemLink ~= nil then
      table.insert(itemsIn, { quantity = quantity, itemLink = itemLink })
    end
  end
  self.queuedTrade.itemsIn = itemsIn
end

function JournalatorTradesMonitorMixin:OnEvent(eventName, ...)
  if eventName == "TRADE_SHOW" then
    self:NewTrade()
  elseif self.queuedTrade ~= nil then
    if eventName == "UI_INFO_MESSAGE" then
      local msgType, message = ...
      if message == ERR_TRADE_COMPLETE then
        self.queuedTrade.time = time()
        Journalator.AddToLogs( { Trades = { self.queuedTrade } })
        self.queuedTrade = nil
      elseif message == ERR_TRADE_CANCELLED then
        self.queuedTrade = nil
      end

    elseif eventName == "TRADE_MONEY_CHANGED" then
      self.queuedTrade.moneyIn = GetTargetTradeMoney()

    elseif eventName == "TRADE_PLAYER_ITEM_CHANGED" then
      self:UpdateItemsOut()

    elseif eventName == "TRADE_TARGET_ITEM_CHANGED" then
      self:UpdateItemsIn()

    elseif eventName == "TRADE_UPDATE" then
      self:UpdateItemsOut()
      self:UpdateItemsIn()
    end
  end
end
