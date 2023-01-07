CRAFTING_ORDER_EVENTS = {
  "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE",
}

JournalatorCraftingOrderFulfillingMonitorMixin = {}

local function ExcludeMatching(array, toExclude)
  local hits = {}
  for _, item in ipairs(toExclude) do
    hits[item] = true
  end

  local result = {}
  for _, item in ipairs(array) do
    if not hits[item] then
      table.insert(result, item)
    end
  end
  return result
end

local function GetBasicAndNotModifiedReagents(recipeSchematic)
  local result = {}
  for _, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic and
       reagentSlotSchematic.dataSlotType == Enum.TradeskillSlotDataType.Reagent then
      table.insert(result, {
        itemID = reagentSlotSchematic.reagents[1].itemID,
        quantity = reagentSlotSchematic.quantityRequired,
        reagentSlot = reagentSlotSchematic.slotIndex
      })
    end
  end
  return result
end

local function GetCustomerReagents(reagentsData)
  local result = {}
  for _, r in ipairs(reagentsData) do
    table.insert(result, {
      itemID = r.reagent.itemID,
      quantity = r.reagent.quantity,
      reagentSlot = r.reagentSlot,
    })
  end
  return result
end

local function GetCrafterReagents(customerReagents, allReagents)
  return ExcludeMatching(allReagents, customerReagents)
end

local function GetSlotsWithReagents(recipeSchematic, reagents)
  local reagentsToSlots = {}
  for _, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
    for _, reagent in ipairs(reagentSlotSchematic.reagents) do
      reagentsToSlots[reagent.itemID] = reagentSlotSchematic.slotIndex
    end
  end

  local result = {}
  for _, r in ipairs(reagents) do
    table.insert(result, {
      itemID = r.itemID,
      quantity = r.quantity,
      reagentSlot = reagentsToSlots[r.itemID]
    })
  end

  return result
end

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

    hooksecurefunc(C_TradeSkillUI, "CraftRecipe", function(recipeID, _, craftingReagents, _, orderID)
      if orderID ~= nil then
        self.potentialLocalReagents.orderID = orderID

        local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)

        --Note we don't need to consider modified or non-basic reagents that are
        --not included in the parameters because the recipe must have been
        --supplied with the complete parameters for a given slot

        self.potentialLocalReagents.reagents = GetSlotsWithReagents(recipeSchematic, craftingReagents)

        local basicMissingReagents = ExcludeMatching(GetBasicAndNotModifiedReagents(recipeSchematic), self.potentialLocalReagents.reagents)

        tAppendAll(self.potentialLocalReagents.reagents, basicMissingReagents)
      end
    end)

    FrameUtil.RegisterFrameForEvents(self, CRAFTING_ORDER_EVENTS)
  end
end

function JournalatorCraftingOrderFulfillingMonitorMixin:ResetState()
  self.expectedCrafterNote = {orderID = nil, note = nil}
  -- Reagents with slot information that may have been used when crafting the
  -- item.
  self.potentialLocalReagents = {orderID = nil, reagents = nil}
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
    -- Determine the reagents supplied by the crafter by excluding those
    -- attached to the order from the list of potential reagents
    if self.potentialLocalReagents.orderID == orderID and self.potentialLocalReagents.reagents then
      crafterReagents = GetCrafterReagents(customerReagents, self.potentialLocalReagents.reagents)
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
