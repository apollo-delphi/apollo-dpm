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
  object pnlMainContainer: TPanel
    Left = 0
    Top = 0
    Width = 619
    Height = 441
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    Caption = 'pnlMainContainer'
    TabOrder = 0
    object splHorizontal: TSplitter
      Left = 0
      Top = 339
      Width = 619
      Height = 2
      Cursor = crVSplit
      Align = alBottom
    end
    object reActionLog: TRichEdit
      Left = 0
      Top = 341
      Width = 619
      Height = 100
      Align = alBottom
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
      Zoom = 100
      Font.Charset = RUSSIAN_CHARSET
    end
    object pnlMain: TPanel
      Left = 0
      Top = 0
      Width = 619
      Height = 339
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlMain'
      TabOrder = 0
      object splVertical: TSplitter
        Left = 170
        Top = 0
        Width = 2
        Height = 339
      end
      object tvNavigation: TTreeView
        Left = 0
        Top = 0
        Width = 170
        Height = 339
        Align = alLeft
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Indent = 19
        TabOrder = 0
      end
      object pnlPackages: TPanel
        Left = 172
        Top = 0
        Width = 447
        Height = 339
        Align = alClient
        BevelOuter = bvNone
        Caption = 'pnlPackages'
        TabOrder = 1
        object sbPackages: TScrollBox
          Left = 0
          Top = 30
          Width = 447
          Height = 309
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clWindow
          ParentColor = False
          TabOrder = 1
        end
        object pnlButtons: TPanel
          Left = 0
          Top = 0
          Width = 447
          Height = 30
          Align = alTop
          BevelOuter = bvNone
          Caption = 'pnlButtons'
          Color = clWindow
          ParentBackground = False
          ShowCaption = False
          TabOrder = 0
        end
      end
    end
  end
  object swPackageDetail: TSplitView
    Left = 619
    Top = 0
    Width = 5
    Height = 441
    CloseStyle = svcCompact
    Color = clWindow
    CompactWidth = 5
    Opened = False
    OpenedWidth = 200
    Placement = svpRight
    TabOrder = 1
    object pnlDetailSwitcher: TPanel
      Left = 0
      Top = 0
      Width = 5
      Height = 441
      Cursor = crHandPoint
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'pnlDetailSwitcher'
      Color = clMenuHighlight
      ParentBackground = False
      ShowCaption = False
      TabOrder = 0
      OnClick = pnlDetailSwitcherClick
    end
  end
end
