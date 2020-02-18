object PackageForm: TPackageForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Package Settings'
  ClientHeight = 461
  ClientWidth = 415
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblPackageType: TLabel
    Left = 24
    Top = 152
    Width = 68
    Height = 13
    Caption = 'Package Type'
  end
  object leRepoURL: TLabeledEdit
    Left = 95
    Top = 8
    Width = 276
    Height = 21
    EditLabel.Width = 90
    EditLabel.Height = 13
    EditLabel.Caption = 'GitHub Repo URL'
    LabelPosition = lpLeft
    TabOrder = 0
  end
  object btnGo: TButton
    Left = 374
    Top = 6
    Width = 37
    Height = 25
    Caption = 'Go'
    TabOrder = 1
    OnClick = btnGoClick
  end
  object leOwner: TLabeledEdit
    Left = 95
    Top = 39
    Width = 250
    Height = 21
    EditLabel.Width = 35
    EditLabel.Height = 13
    EditLabel.Caption = 'Owner'
    LabelPosition = lpLeft
    ReadOnly = True
    TabOrder = 2
  end
  object leRepo: TLabeledEdit
    Left = 95
    Top = 66
    Width = 250
    Height = 21
    EditLabel.Width = 27
    EditLabel.Height = 13
    EditLabel.Caption = 'Repo'
    LabelPosition = lpLeft
    ReadOnly = True
    TabOrder = 3
  end
  object leName: TLabeledEdit
    Left = 95
    Top = 93
    Width = 250
    Height = 21
    EditLabel.Width = 29
    EditLabel.Height = 13
    EditLabel.Caption = 'Name'
    LabelPosition = lpLeft
    TabOrder = 4
  end
  object leDescription: TLabeledEdit
    Left = 95
    Top = 120
    Width = 250
    Height = 21
    EditLabel.Width = 59
    EditLabel.Height = 13
    EditLabel.Caption = 'Description'
    LabelPosition = lpLeft
    TabOrder = 5
  end
  object grpFiltering: TGroupBox
    Left = 3
    Top = 176
    Width = 200
    Height = 249
    Caption = 'Filtering'
    TabOrder = 6
    object rbBlackList: TRadioButton
      Left = 103
      Top = 16
      Width = 70
      Height = 17
      Caption = 'Black list'
      TabOrder = 0
    end
    object rbWhiteList: TRadioButton
      Left = 27
      Top = 16
      Width = 70
      Height = 17
      Caption = 'White list'
      Checked = True
      TabOrder = 1
      TabStop = True
    end
    object sgFiltering: TStringGrid
      Left = 5
      Top = 36
      Width = 190
      Height = 207
      ColCount = 1
      DefaultRowHeight = 21
      FixedCols = 0
      RowCount = 1
      FixedRows = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAlwaysShowEditor]
      TabOrder = 2
      OnKeyDown = sgFilteringKeyDown
      ColWidths = (
        180)
    end
  end
  object grpMoving: TGroupBox
    Left = 208
    Top = 176
    Width = 200
    Height = 249
    Caption = 'Moving'
    TabOrder = 7
    object sgMoving: TStringGrid
      Left = 5
      Top = 36
      Width = 190
      Height = 207
      ColCount = 2
      DefaultRowHeight = 21
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAlwaysShowEditor]
      TabOrder = 0
      OnKeyDown = sgMovingKeyDown
      ColWidths = (
        93
        85)
    end
  end
  object btnSaveJSON: TButton
    Left = 8
    Top = 431
    Width = 75
    Height = 25
    Caption = 'Save JSON'
    TabOrder = 8
    OnClick = btnSaveJSONClick
  end
  object btnCancel: TButton
    Left = 328
    Top = 431
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 9
  end
  object cbbPackageType: TComboBox
    Left = 95
    Top = 147
    Width = 145
    Height = 22
    Style = csOwnerDrawFixed
    TabOrder = 10
  end
  object fsdSaveJSON: TFileSaveDialog
    DefaultExtension = 'json'
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'json'
        FileMask = '*.json'
      end>
    Options = [fdoStrictFileTypes]
    Left = 56
    Top = 328
  end
end
