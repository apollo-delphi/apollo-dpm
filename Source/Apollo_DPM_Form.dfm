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
    Top = 29
    Width = 624
    Height = 280
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnlMain'
    TabOrder = 0
    object splStruct2Grid: TSplitter
      Left = 170
      Top = 0
      Width = 2
      Height = 280
    end
    object sbPackages: TScrollBox
      Left = 172
      Top = 0
      Width = 452
      Height = 280
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = clWindow
      ParentColor = False
      TabOrder = 0
      object aiPabPkgLoad: TActivityIndicator
        Left = 203
        Top = 116
        Anchors = []
        IndicatorSize = aisLarge
        IndicatorType = aitRotatingSector
      end
    end
    object tvStructure: TTreeView
      Left = 0
      Top = 0
      Width = 170
      Height = 280
      Align = alLeft
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      HideSelection = False
      Indent = 19
      ReadOnly = True
      ShowLines = False
      TabOrder = 1
      ToolTips = False
      OnChange = tvStructureChange
      OnCustomDrawItem = tvStructureCustomDrawItem
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
