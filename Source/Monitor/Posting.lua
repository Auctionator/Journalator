JournalatorPostingMonitorMixin = {}

function JournalatorPostingMonitorMixin:OnLoad()
  if Auctionator.Constants.IsTBC then
    Auctionator.EventBus:Register({
      ReceiveEvent = function(self, eventName, auctionData)
        table.insert(Journalator.State.Logs.Posting, {
          itemName = Journalator.Utilities.GetNameFromLink(auctionData.itemLink),
          buyout = auctionData.buyoutAmount,
          bid = math.floor(auctionData.bidAmount / auctionData.quantity),
          count = auctionData.quantity,
          deposit = auctionData.deposit or 0,
          time = time(),
          itemLink = auctionData.itemLink,
          source = Journalator.State.Source,
        })
      end
    }, { Auctionator.Selling.Events.AuctionCreated })
  else
    hooksecurefunc(C_AuctionHouse, "PostItem", function(location, duration, quantity, bid, buyout)
      local link = select(7, GetContainerItemInfo(location:GetBagAndSlot()))
      local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)

      table.insert(Journalator.State.Logs.Posting, {
        itemName = Journalator.Utilities.GetNameFromLink(link),
        buyout = buyout,
        bid = bid,
        count = quantity,
        deposit = deposit,
        time = time(),
        itemLink = link,
        source = Journalator.State.Source,
      })
    end)
    hooksecurefunc(C_AuctionHouse, "PostCommodity", function(location, duration, quantity, unitPrice)
      local link = select(7, GetContainerItemInfo(location:GetBagAndSlot()))
      local itemID = GetItemInfoInstant(link)
      local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)

      table.insert(Journalator.State.Logs.Posting, {
        itemName = Journalator.Utilities.GetNameFromLink(link),
        buyout = unitPrice,
        bid = nil,
        count = quantity,
        deposit = deposit,
        time = time(),
        itemLink = link,
        source = Journalator.State.Source,
      })
    end)
  end
end
