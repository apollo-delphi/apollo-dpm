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
    Left = 6
    Top = 259
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
    Left = 153
    Top = 277
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 2
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 234
    Top = 277
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
      Hint = 'Go to URL'
      Flat = True
      Glyph.Data = {
        36040000424D3604000000000000360000002800000010000000100000000100
        2000000000000004000000000000000000000000000000000000FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF007B7B7B00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00020202007777
        7700FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00020202000000
        000077777700FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF007D7D7D007A7A7A007A7A7A007A7A7A007A7A7A007A7A7A00000000000000
        00000000000077777700FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00020202000000000000000000000000000000000000000000000000000000
        0000000000000000000077777700FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00020202000000000000000000000000000000000000000000000000000000
        000000000000000000000000000077777700FF00FF00FF00FF00FF00FF00FF00
        FF00020202000000000000000000000000000000000000000000000000000000
        00000000000000000000000000007E7E7E00FF00FF00FF00FF00FF00FF00FF00
        FF00020202000000000000000000000000000000000000000000000000000000
        000000000000000000007E7E7E00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00848484008282820082828200828282008282820082828200010101000000
        0000000000007E7E7E00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00020202000000
        00007E7E7E00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00020202007E7E
        7E00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0082828200FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
      ParentShowHint = False
      ShowHint = True
      OnClick = btnGoToURLClick
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
    object leRepoName: TLabeledEdit
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
    object aiRepoDataLoad: TActivityIndicator
      Left = 274
      Top = 42
      IndicatorSize = aisSmall
      IndicatorType = aitRotatingSector
    end
  end
end
