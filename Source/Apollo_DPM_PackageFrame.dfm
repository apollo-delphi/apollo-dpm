object frmPackage: TfrmPackage
  Left = 0
  Top = 0
  Width = 366
  Height = 74
  Color = clWindow
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  object lblPackageDescription: TLabel
    Left = 12
    Top = 5
    Width = 103
    Height = 13
    Caption = 'lblPackageDescription'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
  end
  object lblVersion: TLabel
    Left = 12
    Top = 50
    Width = 35
    Height = 13
    Caption = 'Version'
  end
  object btnInstall: TButton
    Left = 280
    Top = 44
    Width = 83
    Height = 25
    Caption = 'Action'
    DropDownMenu = pmActions
    Style = bsSplitButton
    TabOrder = 0
  end
  object cbbVersions: TComboBox
    Left = 53
    Top = 46
    Width = 80
    Height = 22
    Style = csOwnerDrawFixed
    ParentFont = False
    TabOrder = 1
    OnDropDown = cbbVersionsDropDown
    Font.Name = 'Tahoma'
    Font.Height = -9
    Font.Charset = DEFAULT_CHARSET
  end
  object aiVerListLoad: TActivityIndicator
    Left = 138
    Top = 45
    IndicatorSize = aisSmall
    IndicatorType = aitRotatingSector
  end
  object pmActions: TPopupMenu
    Left = 208
    Top = 8
    object mniAdd: TMenuItem
      Caption = 'Add'
      OnClick = mniAddClick
    end
    object mniRemove: TMenuItem
      Caption = 'Remove'
      OnClick = mniRemoveClick
    end
    object mniUpgrade: TMenuItem
      Caption = 'Upgrade'
    end
    object mniPackageSettings: TMenuItem
      Caption = 'Package settings...'
      OnClick = mniPackageSettingsClick
    end
  end
end
