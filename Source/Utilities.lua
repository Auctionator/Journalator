Journalator.Utilities = {}

function Journalator.Utilities.GetNameFromLink(link)
  return string.match(link, "%[(.+)%]")
end

function Journalator.ApplyQualityColor(name, link)
  return "|c" .. Auctionator.Utilities.GetQualityColorFromLink(link) .. name .. "|r"
end
