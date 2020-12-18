object ItemEditForm: TItemEditForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'ItemEditForm'
  ClientHeight = 71
  ClientWidth = 337
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object leTemplate: TLabeledEdit
    Left = 88
    Top = 8
    Width = 244
    Height = 21
    EditLabel.Width = 55
    EditLabel.Height = 13
    EditLabel.Caption = 'leTemplate'
    LabelPosition = lpLeft
    TabOrder = 0
    Visible = False
  end
  object btnApply: TButton
    Left = 176
    Top = 42
    Width = 75
    Height = 25
    Caption = 'Apply'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 257
    Top = 42
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
