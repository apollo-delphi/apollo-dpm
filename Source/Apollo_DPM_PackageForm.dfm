object PackageForm: TPackageForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Package'
  ClientHeight = 309
  ClientWidth = 314
  Color = clWindow
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblValidationMsg: TLabel
    Left = 5
    Top = 240
    Width = 88
    Height = 13
    Caption = 'lblValidationMsg'
    ParentFont = False
    Visible = False
    Font.Color = clRed
    Font.Style = [fsBold]
  end
  object grpVisibility: TGroupBox
    Left = 6
    Top = 107
    Width = 301
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
    Left = 77
    Top = 179
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
  object grpGitHub: TGroupBox
    Left = 6
    Top = 2
    Width = 301
    Height = 107
    Caption = 'GitHub Repository'
    TabOrder = 4
    object btnGoToURL: TSpeedButton
      Left = 274
      Top = 20
      Width = 23
      Height = 22
      Flat = True
    end
    object leURL: TLabeledEdit
      Left = 45
      Top = 20
      Width = 227
      Height = 21
      EditLabel.Width = 20
      EditLabel.Height = 13
      EditLabel.Caption = 'URL'
      LabelPosition = lpLeft
      TabOrder = 0
    end
    object leRepoOwner: TLabeledEdit
      Left = 45
      Top = 43
      Width = 227
      Height = 21
      Color = clBtnFace
      EditLabel.Width = 35
      EditLabel.Height = 13
      EditLabel.Caption = 'Owner'
      LabelPosition = lpLeft
      ReadOnly = True
      TabOrder = 1
    end
    object leRepo: TLabeledEdit
      Left = 45
      Top = 66
      Width = 227
      Height = 21
      Color = clBtnFace
      EditLabel.Width = 27
      EditLabel.Height = 13
      EditLabel.Caption = 'Repo'
      LabelPosition = lpLeft
      ReadOnly = True
      TabOrder = 2
    end
  end
end
