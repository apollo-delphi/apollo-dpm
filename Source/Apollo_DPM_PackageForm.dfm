object PackageForm: TPackageForm
  Left = 0
  Top = 0
  Caption = 'PackageForm'
  ClientHeight = 299
  ClientWidth = 310
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblValidationMsg: TLabel
    Left = 8
    Top = 248
    Width = 88
    Height = 13
    Caption = 'lblValidationMsg'
    ParentFont = False
    Visible = False
    Font.Color = clRed
    Font.Style = [fsBold]
  end
  object grpVisibility: TGroupBox
    Left = 8
    Top = 3
    Width = 294
    Height = 54
    Caption = 'Visibility'
    TabOrder = 0
    object rbPrivate: TRadioButton
      Left = 16
      Top = 19
      Width = 113
      Height = 17
      Caption = 'Private Package'
      TabOrder = 0
    end
    object rbPublic: TRadioButton
      Left = 144
      Top = 19
      Width = 113
      Height = 17
      Caption = 'Public Package'
      TabOrder = 1
    end
  end
  object leName: TLabeledEdit
    Left = 80
    Top = 63
    Width = 222
    Height = 21
    EditLabel.Width = 29
    EditLabel.Height = 13
    EditLabel.Caption = 'Name'
    LabelPosition = lpLeft
    TabOrder = 1
  end
  object btnOk: TButton
    Left = 147
    Top = 266
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 2
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 227
    Top = 266
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
