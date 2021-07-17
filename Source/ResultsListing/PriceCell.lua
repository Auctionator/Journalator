JournalatorPriceCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin, TableBuilderCellMixin)

function JournalatorPriceCellTemplateMixin:Init(columnName)
  self.columnName = columnName

  self.MoneyDisplay:ClearAllPoints();
  self.MoneyDisplay:SetPoint("LEFT");
end

function JournalatorPriceCellTemplateMixin:Populate(rowData, index)
  AuctionatorCellMixin.Populate(self, rowData, index)


  if rowData[self.columnName] ~= 0 then
    if rowData[self.columnName] < 0 then
      self.MoneyDisplay:SetAmount(-rowData[self.columnName])
      self.MoneyDisplay:SetFontObject(PriceFontRed)
    else
      self.MoneyDisplay:SetAmount(rowData[self.columnName])
      self.MoneyDisplay:SetFontObject(PriceFontGreen)
    end
    self.MoneyDisplay:Show()
  else
    self.MoneyDisplay:Hide()
  end
end
