JournalatorAuctionPostingMonitorMixin = {}

local function GetContainerItemLink(location)
  return C_Container.GetContainerItemInfo(location:GetBagAndSlot()).hyperlink
end

function JournalatorAuctionPostingMonitorMixin:OnLoad()
  if Journalator.Constants.IsClassic and (not IsUsingLegacyAuctionClient or IsUsingLegacyAuctionClient()) then
    if not Auctionator or not Auctionator.EventBus then
      return
    end
    Auctionator.EventBus:Register({
      ReceiveEvent = function(self, eventName, auctionData)
        Journalator.Debug.Message("JournalatorAuctionPostingMonitor: Auctionator post hook", auctionData.itemLink)
        Journalator.AddToLogs({ Posting = {
          {
            itemName = Auctionator.Utilities.GetNameFromLink(auctionData.itemLink),
            buyout = auctionData.buyoutAmount,
            bid = math.floor(auctionData.bidAmount / auctionData.quantity),
            count = auctionData.quantity,
            deposit = auctionData.deposit or 0,
            time = time(),
            itemLink = auctionData.itemLink,
            source = Journalator.State.Source,
          }
        }})
      end
    }, { Auctionator.Selling.Events.AuctionCreated })
  else
    hooksecurefunc(C_AuctionHouse, "PostItem", function(location, duration, quantity, bid, buyout)
      local link = GetContainerItemLink(location)
      local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)

      Journalator.Debug.Message("JournalatorAuctionPostingMonitor: Blizzard post item hook", link)

      Journalator.AddToLogs({ Posting = {
        {
        itemName = C_Item.GetItemName(location),
        buyout = buyout,
        bid = bid,
        count = quantity,
        deposit = deposit,
        time = time(),
        itemLink = link,
        source = Journalator.State.Source,
        }
      }})
    end)
    hooksecurefunc(C_AuctionHouse, "PostCommodity", function(location, duration, quantity, unitPrice)
      local link = GetContainerItemLink(location)
      local itemID = C_Item.GetItemInfoInstant(link)
      local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)

      Journalator.Debug.Message("JournalatorAuctionPostingMonitor: Blizzard post commodity hook", link)

      Journalator.AddToLogs({ Posting = {
        {
          itemName = C_Item.GetItemName(location),
          buyout = unitPrice,
          bid = nil,
          count = quantity,
          deposit = deposit,
          time = time(),
          itemLink = link,
          source = Journalator.State.Source,
        }
      }})
    end)
  end
end
