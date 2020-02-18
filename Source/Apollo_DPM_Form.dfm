object DPMForm: TDPMForm
  Left = 0
  Top = 0
  Caption = 'Apollo DPM - Delphi Package Manager'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object splMain2Log: TSplitter
    Left = 0
    Top = 309
    Width = 624
    Height = 2
    Cursor = crVSplit
    Align = alBottom
  end
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 309
    Align = alClient
    BevelOuter = bvNone
    Caption = 'pnlMain'
    TabOrder = 0
    object splStruct2Grid: TSplitter
      Left = 170
      Top = 0
      Width = 2
      Height = 309
    end
    object tvStructure: TTreeView
      Left = 0
      Top = 0
      Width = 170
      Height = 309
      Align = alLeft
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      HideSelection = False
      Indent = 19
      ReadOnly = True
      ShowLines = False
      TabOrder = 0
      ToolTips = False
      OnChange = tvStructureChange
      OnCustomDrawItem = tvStructureCustomDrawItem
    end
    object pnlContent: TPanel
      Left = 172
      Top = 0
      Width = 452
      Height = 309
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object sbPackages: TScrollBox
        Left = 0
        Top = 41
        Width = 452
        Height = 268
        Align = alClient
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clWindow
        ParentColor = False
        TabOrder = 0
        object aiPabPkgLoad: TActivityIndicator
          Left = 203
          Top = 110
          Anchors = []
          IndicatorSize = aisLarge
          IndicatorType = aitRotatingSector
        end
      end
      object pnlButtons: TPanel
        Left = 0
        Top = 0
        Width = 452
        Height = 41
        Align = alTop
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        object btnRegisterPackage: TButton
          Left = 21
          Top = 4
          Width = 105
          Height = 25
          Caption = 'Register Package'
          TabOrder = 0
          Visible = False
          OnClick = btnRegisterPackageClick
        end
      end
    end
  end
  object mmoActionLog: TMemo
    Left = 0
    Top = 311
    Width = 624
    Height = 130
    Align = alBottom
    BevelOuter = bvNone
    BorderStyle = bsNone
    ReadOnly = True
    TabOrder = 1
  end
end
