JournalatorTimeCellTemplateMixin = CreateFromMixins(AuctionatorStringCellTemplateMixin)

function JournalatorTimeCellTemplateMixin:Populate(rowData, index)
  AuctionatorStringCellTemplateMixin.Populate(self, rowData, index)

  self.text:SetText(SecondsToTime(time() - rowData[self.columnName]))
end
