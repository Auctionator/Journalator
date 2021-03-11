JournalatorPostingMonitorMixin = {}

function JournalatorPostingMonitorMixin:OnLoad()
  hooksecurefunc(C_AuctionHouse, "PostItem", function(location, duration, quantity, bid, buyout)
    local link = select(7, GetContainerItemInfo(location:GetBagAndSlot()))
    local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)

    table.insert(JOURNALATOR_LOGS.Posting, {
      itemName = Journalator.Utilities.GetNameFromLink(link),
      buyout = buyout,
      bid = bid,
      count = quantity,
      deposit = deposit,
      time = time(),
      itemLink = link,
      source = Journalator.Source,
    })
  end)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", function(location, duration, quantity, unitPrice)
    local link = select(7, GetContainerItemInfo(location:GetBagAndSlot()))
    local itemID = GetItemInfoInstant(link)
    local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)

    table.insert(JOURNALATOR_LOGS.Posting, {
      itemName = GetNameFromLink(link),
      buyout = unitPrice,
      bid = nil,
      count = quantity,
      deposit = deposit,
      time = time(),
      itemLink = link,
      source = Journalator.Source,
    })
  end)
end
