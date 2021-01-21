object ItemEditForm: TItemEditForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'ItemEditForm'
  ClientHeight = 80
  ClientWidth = 359
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblValidationMsg: TLabel
    Left = 6
    Top = 34
    Width = 92
    Height = 13
    Caption = 'lblValidationMsg'
    ParentFont = False
    Visible = False
    Font.Name = 'Tahoma'
    Font.Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsBold]
  end
  object leTemplate: TLabeledEdit
    Left = 111
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
    Left = 200
    Top = 50
    Width = 75
    Height = 25
    Caption = 'Apply'
    TabOrder = 1
    OnClick = btnApplyClick
  end
  object btnCancel: TButton
    Left = 280
    Top = 50
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
