object frmPackage: TfrmPackage
  Left = 0
  Top = 0
  Width = 371
  Height = 74
  Color = clWindow
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  object lblPackageDescription: TLabel
    Left = 12
    Top = 3
    Width = 103
    Height = 13
    Caption = 'lblPackageDescription'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
  end
  object lblVersion: TLabel
    Left = 12
    Top = 30
    Width = 35
    Height = 13
    Caption = 'Version'
  end
  object lblVersionlDescribe: TLabel
    Left = 53
    Top = 54
    Width = 88
    Height = 13
    Caption = 'lblVersionlDescribe'
  end
  object btnInstall: TButton
    Left = 282
    Top = 25
    Width = 80
    Height = 25
    Caption = 'Action'
    DropDownMenu = pmActions
    Style = bsSplitButton
    TabOrder = 0
  end
  object cbbVersions: TComboBox
    Left = 53
    Top = 26
    Width = 194
    Height = 22
    Style = csOwnerDrawFixed
    ParentFont = False
    TabOrder = 1
    OnChange = cbbVersionsChange
    OnDropDown = cbbVersionsDropDown
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
  end
  object aiVerListLoad: TActivityIndicator
    Left = 252
    Top = 25
    IndicatorSize = aisSmall
    IndicatorType = aitRotatingSector
  end
  object pmActions: TPopupMenu
    Left = 160
    Top = 8
    object mniAdd: TMenuItem
      Caption = 'Add'
      OnClick = mniAddClick
    end
    object mniRemove: TMenuItem
      Caption = 'Remove'
      OnClick = mniRemoveClick
    end
    object mniUpdateTo: TMenuItem
      Caption = 'Update to'
      OnClick = mniUpdateToClick
    end
    object mniPackageSettings: TMenuItem
      Caption = 'Package settings...'
      OnClick = mniPackageSettingsClick
    end
  end
end
