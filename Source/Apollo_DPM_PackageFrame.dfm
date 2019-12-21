object frmPackage: TfrmPackage
  Left = 0
  Top = 0
  Width = 366
  Height = 49
  TabOrder = 0
  object lblPackageName: TLabel
    Left = 12
    Top = 8
    Width = 77
    Height = 13
    Caption = 'lblPackageName'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
  end
  object lblPackageDescription: TLabel
    Left = 12
    Top = 27
    Width = 103
    Height = 13
    Caption = 'lblPackageDescription'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsItalic]
  end
  object lblVersion: TLabel
    Left = 120
    Top = 8
    Width = 35
    Height = 13
    Caption = 'Version'
  end
  object btnInstall: TButton
    Left = 304
    Top = 2
    Width = 47
    Height = 25
    Caption = 'Install'
    TabOrder = 0
    OnClick = btnInstallClick
  end
  object cbbVersions: TComboBox
    Left = 161
    Top = 4
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
    Left = 247
    Top = 3
    IndicatorSize = aisSmall
    IndicatorType = aitRotatingSector
  end
end
