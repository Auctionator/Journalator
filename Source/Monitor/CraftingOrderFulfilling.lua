CRAFTING_ORDER_EVENTS = {
  "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE",
}

JournalatorCraftingOrderFulfillingMonitorMixin = {}

function JournalatorCraftingOrderFulfillingMonitorMixin:OnLoad()
  if Auctionator.Constants.IsClassic then
    -- No crafting orders
    return
  else
    self:ResetState()

    hooksecurefunc(C_CraftingOrders, "FulfillOrder", function(orderID, crafterNote, profession)
      self.expectedCrafterNote.orderID = orderID
      self.expectedCrafterNote.note = crafterNote
    end)

    hooksecurefunc(C_TradeSkillUI, "CraftRecipe", function(_, _, craftingReagents, _, orderID)
      if orderID ~= nil then
        self.usedReagents.orderID = orderID
        self.usedReagents.reagents = CopyTable(craftingReagents)
      end
    end)

    FrameUtil.RegisterFrameForEvents(self, CRAFTING_ORDER_EVENTS)
  end
end

function JournalatorCraftingOrderFulfillingMonitorMixin:ResetState()
  self.expectedCrafterNote = {orderID = nil, note = nil}
  self.usedReagents = {orderID = nil, reagents = nil}
end

local function GetCustomerReagents(reagentsData)
  local customerReagents = {}
  for _, r in ipairs(reagentsData) do
    table.insert(customerReagents, r.reagent)
  end
  return customerReagents
end

local function GetCrafterReagents(customerReagents, allReagents)
  local customerSlots = {}
  for _, reagent in ipairs(customerReagents) do
    customerSlots[reagent.dataSlotIndex] = true
  end

  return tFilter(
    allReagents,
    function(reagent) return not customerSlots[reagent.dataSlotIndex] end
  )
end

function JournalatorCraftingOrderFulfillingMonitorMixin:OnEvent(eventName, ...)
  if eventName == "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE" then
    local state, orderID = ...

    if state ~= Enum.CraftingOrderResult.Ok then
      return
    end

    local claimedOrder = C_CraftingOrders.GetClaimedOrder()

    if orderID ~= claimedOrder.orderID or claimedOrder.outputItemHyperlink == nil then
      return
    end

    local crafterNote = ""
    if self.expectedCrafterNote.orderID == orderID and self.expectedCrafterNote.note then
      crafterNote = self.expectedCrafterNote.note
    end

    local customerReagents = GetCustomerReagents(claimedOrder.reagents)
    local crafterReagents
    if self.usedReagents.orderID == orderID and self.usedReagents.reagents then
      crafterReagents = GetCrafterReagents(customerReagents, self.usedReagents.reagents)
    end

    local item = Item:CreateFromItemLink(claimedOrder.outputItemHyperlink)
    item:ContinueOnItemLoad(function()
      local itemName = item:GetItemName()

      local guildName
      if claimedOrder.orderType == Enum.CraftingOrderType.Guild then
        guildName = GetGuildInfo("player")
      end

      Journalator.AddToLogs({ Fulfilling = {
        {
        recipeID = claimedOrder.spellID,
        isRecraft = claimedOrder.isRecraft,
        minCraftQuality = claimedOrder.minQuality,

        itemName = itemName,
        itemLink = claimedOrder.outputItemHyperlink,
        customerReagents = Journalator.Utilities.CleanReagents(customerReagents),
        crafterReagents = Journalator.Utilities.CleanReagents(crafterReagents),
        recraftItemLink = claimedOrder.recraftItemHyperlink,
        count = 1,

        orderType = claimedOrder.orderType,
        playerName = claimedOrder.customerName,
        guildName = guildName,

        tipAmount = claimedOrder.tipAmount,
        consortiumCut = claimedOrder.consortiumCut,
        customerNote = claimedOrder.customerNotes,
        crafterNote = crafterNote,

        time = time(),
        source = Journalator.State.Source,
        }
      }})
      self:ResetState()
    end)
  end
end
