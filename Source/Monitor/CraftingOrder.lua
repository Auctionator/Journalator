JournalatorCraftingOrderMonitorMixin = {}

function JournalatorCraftingOrderMonitorMixin:OnLoad()
  if Auctionator.Constants.IsClassic then
    -- No crafting orders
    return
  else
    hooksecurefunc(C_CraftingOrders, "FulfillOrder", function(orderID, crafterNote, profession)
      local claimedOrder = C_CraftingOrders.GetClaimedOrder()

      if orderID ~= claimedOrder.orderID or claimedOrder.outputItemHyperlink == nil then
        return
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
      end)
    end)
  end
end
