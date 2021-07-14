object ConflictFrame: TConflictFrame
  Left = 0
  Top = 0
  Width = 477
  Height = 73
  Anchors = [akLeft, akTop, akRight]
  Color = clWindow
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  object lblPackageBegin: TLabel
    Left = 8
    Top = 7
    Width = 136
    Height = 13
    Caption = 'Indirect dependecy package'
  end
  object lblInstalledCaption: TLabel
    Left = 8
    Top = 29
    Width = 83
    Height = 13
    Caption = 'Installed version:'
  end
  object lblRequiredCaption: TLabel
    Left = 8
    Top = 51
    Width = 85
    Height = 13
    Caption = 'Required version:'
  end
  object lblPackage: TLabel
    Left = 156
    Top = 7
    Width = 19
    Height = 13
    Caption = '%s'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsBold]
  end
  object lblPackageEnd: TLabel
    Left = 187
    Top = 7
    Width = 92
    Height = 13
    Caption = 'is already installed.'
  end
  object lblInstalledVersion: TLabel
    Left = 102
    Top = 29
    Width = 19
    Height = 13
    Caption = '%s'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsBold]
  end
  object lblRequiredVersion: TLabel
    Left = 102
    Top = 51
    Width = 19
    Height = 13
    Caption = '%s'
    ParentFont = False
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsBold]
  end
  object rbKeepInstalled: TRadioButton
    Left = 347
    Top = 27
    Width = 105
    Height = 17
    Caption = 'keep this version'
    TabOrder = 0
  end
  object rbUpdateToRequired: TRadioButton
    Left = 347
    Top = 49
    Width = 130
    Height = 17
    Caption = 'update to this version'
    TabOrder = 1
  end
end
