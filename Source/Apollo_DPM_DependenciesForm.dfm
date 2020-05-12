object DependenciesForm: TDependenciesForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'DependenciesForm'
  ClientHeight = 211
  ClientWidth = 374
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lvDependencies: TListView
    Left = 0
    Top = 0
    Width = 374
    Height = 177
    Align = alTop
    Checkboxes = True
    Columns = <
      item
        Caption = 'BVNVCBN'
      end>
    Items.ItemData = {
      05900000000400000000000000FFFFFFFFFFFFFFFF00000000FFFFFFFF000000
      000648004700460048004700460000000000FFFFFFFFFFFFFFFF00000000FFFF
      FFFF0000000007420056004E00560042004E00430000000000FFFFFFFFFFFFFF
      FF00000000FFFFFFFF0000000007560042004E00420056004E00430000000000
      FFFFFFFFFFFFFFFF00000000FFFFFFFF0000000000}
    TabOrder = 0
    ViewStyle = vsList
  end
end
