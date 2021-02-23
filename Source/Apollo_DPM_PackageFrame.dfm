object PackageFrame: TPackageFrame
  Left = 0
  Top = 0
  Width = 385
  Height = 97
  Margins.Left = 0
  Margins.Top = 0
  Margins.Right = 0
  Margins.Bottom = 0
  Anchors = [akLeft, akTop, akRight]
  Constraints.MinWidth = 370
  Color = clWindow
  Padding.Right = 15
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  OnClick = FrameClick
  OnResize = FrameResize
  object lblVersion: TLabel
    Left = 16
    Top = 61
    Width = 35
    Height = 13
    Caption = 'Version'
    Transparent = True
  end
  object lblName: TLabel
    Left = 16
    Top = 16
    Width = 45
    Height = 13
    Caption = 'lblName'
    ParentFont = False
    Transparent = True
    Font.Name = 'Tahoma'
    Font.Charset = DEFAULT_CHARSET
    Font.Style = [fsBold]
  end
  object lblInstalled: TLabel
    Left = 325
    Top = 16
    Width = 41
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Installed'
    ParentFont = False
    Transparent = True
    Visible = False
    Font.Name = 'Tahoma'
    Font.Color = clGreen
    Font.Charset = DEFAULT_CHARSET
  end
  object lblDescription: TLabel
    Left = 16
    Top = 35
    Width = 63
    Height = 13
    Caption = 'lblDescription'
    Transparent = True
  end
  object pnlActions: TPanel
    Left = 260
    Top = 54
    Width = 106
    Height = 27
    Anchors = [akTop, akRight]
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    object btnAction: TSpeedButton
      Left = 0
      Top = 0
      Width = 90
      Height = 27
      Align = alLeft
      Anchors = []
      Caption = 'Action'
      Flat = True
    end
    object btnActionDropDown: TSpeedButton
      Left = 89
      Top = 0
      Width = 17
      Height = 27
      Align = alRight
      Anchors = []
      Flat = True
      Glyph.Data = {
        36040000424D3604000000000000360000002800000010000000100000000100
        2000000000000004000000000000000000000000000000000000FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF004040400044444400FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF005555550000000000000000005858
        5800FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00747474000000000000000000000000000000
        000078787800FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF0096969600000000000000000000000000000000000000
        00000000000099999900FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00B4B4B40002020200000000000000000000000000000000000000
        00000000000003030300B6B6B600FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF001919190000000000000000000000000000000000000000000000
        000000000000000000001A1A1A00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
        FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
      OnClick = btnActionDropDownClick
    end
  end
  object aiVersionLoad: TActivityIndicator
    Left = 231
    Top = 56
    IndicatorSize = aisSmall
    IndicatorType = aitRotatingSector
  end
  object cbVersions: TComboBox
    Left = 58
    Top = 57
    Width = 167
    Height = 22
    Style = csOwnerDrawFixed
    TabOrder = 2
    OnChange = cbVersionsChange
    OnCloseUp = cbVersionsCloseUp
    OnDrawItem = cbVersionsDrawItem
    OnDropDown = cbVersionsDropDown
  end
  object pmActions: TPopupMenu
    AutoHotkeys = maManual
    Left = 136
    Top = 8
    object mniInstall: TMenuItem
      Caption = 'Install'
      OnClick = mniInstallClick
    end
    object mniUpdate: TMenuItem
      Caption = 'Update'
      OnClick = mniUpdateClick
    end
    object mniUninstall: TMenuItem
      Caption = 'Uninstall'
      OnClick = mniUninstallClick
    end
    object mniEditPackage: TMenuItem
      Caption = 'Edit Package...'
      OnClick = mniEditPackageClick
    end
  end
end
