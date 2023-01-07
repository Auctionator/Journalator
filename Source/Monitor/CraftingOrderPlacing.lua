JournalatorCraftingOrderPlacingMonitorMixin = {}

function JournalatorCraftingOrderPlacingMonitorMixin:OnLoad()
  if Auctionator.Constants.IsClassic then
    -- No crafting orders
    return
  else
    self:HookPlacing()
  end
end

local possibleCraftingOrderOptions
-- There isn't a direct function to convert a skillLineAbilityID into a
-- recipeID, so we use an API call to dump a list of all the recipeIDs and
-- skillLineAbilityIDs to get a conversion.
local function GetSpellIDFromSkillLineAbilityID(skillLineAbilityID)
  if possibleCraftingOrderOptions == nil then
    possibleCraftingOrderOptions = C_CraftingOrders.GetCustomerOptions({
      categoryFilters = {},
      searchText = nil,
      minLevel = 0,
      maxLevel = 0,
      uncollectedOnly = false,
      usableOnly = false,
      upgradesOnly = false,
      includePoor = true,
      includeCommon = true,
      includeUncommon = true,
      includeRare = true,
      includeEpic = true,
      includeLegendary = true,
      includeArtifact = true,
      isFavoritesSearch = false,
    })
  end

  for _, option in ipairs(possibleCraftingOrderOptions.options) do
    if option.skillLineAbilityID == skillLineAbilityID then
      return option.spellID
    end
  end
  return nil
end

function JournalatorCraftingOrderPlacingMonitorMixin:HookPlacing()
  hooksecurefunc(C_CraftingOrders, "PlaceNewOrder", function(orderInfo)
    local guildName
    if orderInfo.orderType == Enum.CraftingOrderType.Guild then
      guildName = GetGuildInfo("player")
    end

    local recraftItemLink
    local isRecraft = false
    if orderInfo.recraftItem then
      recraftItemLink = C_Item.GetItemLinkByGUID(orderInfo.recraftItem)
      isRecraft = true
    end

    local minCraftQuality = orderInfo.minCraftingQualityID
    if minCraftQuality and minCraftQuality > 3 then -- shift gear qualities to the same scale as they start a 4, not 1
      minCraftQuality = minCraftQuality - 3
    end

    local recipeID = GetSpellIDFromSkillLineAbilityID(orderInfo.skillLineAbilityID)

    -- Determine the output item
    local outputLink
    if isRecraft then
      -- Uses tooltip API as there isn't another option to get the hyperlink
      -- for the recraft result
      local tooltipInfo = C_TooltipInfo.GetRecipeResultItem(
        recipeID,
        orderInfo.craftingReagentItems,
        orderInfo.recraftItem,
        nil,
        orderInfo.minCraftingQualityID
      )
      outputLink = tooltipInfo.hyperlink
    else
      outputLink = Auctionator.CraftingInfo.GetOutputItemLink(recipeID, nil, orderInfo.craftingReagentItems)
    end

    -- Save all reagents merging quality and non-quality reagents
    local reagents = Journalator.Utilities.CleanReagents(orderInfo.reagentItems)
    tAppendAll(reagents, Journalator.Utilities.CleanReagents(orderInfo.craftingReagentItems))

    local postingFee = C_CraftingOrders.CalculateCraftingOrderPostingFee(orderInfo.skillLineAbilityID, orderInfo.orderType, orderInfo.orderDuration)

    local item = Item:CreateFromItemLink(outputLink)
    item:ContinueOnItemLoad(function()
      Journalator.AddToLogs({ CraftingOrdersPlaced = {
        {
        recipeID = recipeID,
        isRecraft = isRecraft,
        minCraftQuality = minCraftQuality,

        itemName = item:GetItemName(),
        itemLink = outputLink,
        customerReagents = reagents,
        recraftItemLink = recraftItemLink,
        count = 1,

        orderType = orderInfo.orderType,
        playerName = orderInfo.orderTarget,
        guildName = guildName,

        tipAmount = orderInfo.tipAmount,
        postingFee = postingFee,
        customerNote = orderInfo.customerNotes,

        time = time(),
        source = Journalator.State.Source,
        }
      }})
    end)
  end)
end
