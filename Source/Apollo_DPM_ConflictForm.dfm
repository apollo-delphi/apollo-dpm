object ConflictForm: TConflictForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Version Conflicts'
  ClientHeight = 299
  ClientWidth = 484
  Color = clWindow
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblValidationMsg: TLabel
    Left = 7
    Top = 251
    Width = 88
    Height = 13
    Caption = 'lblValidationMsg'
    ParentFont = False
    Visible = False
    Font.Color = clRed
    Font.Style = [fsBold]
  end
  object btnApply: TButton
    Left = 324
    Top = 269
    Width = 75
    Height = 25
    Caption = 'Apply'
    TabOrder = 0
    OnClick = btnApplyClick
  end
  object btnCancel: TButton
    Left = 405
    Top = 269
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object sbVersionConflicts: TScrollBox
    Left = 0
    Top = 34
    Width = 484
    Height = 209
    Align = alTop
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = clWindow
    ParentColor = False
    TabOrder = 2
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 484
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    Caption = 'pnlHeader'
    ShowCaption = False
    TabOrder = 3
    object lblCaption: TLabel
      Left = 12
      Top = 11
      Width = 332
      Height = 13
      Caption = #1057'onflicts were detected during indirect dependency installation:'
      ParentFont = False
      Font.Color = clRed
      Font.Style = [fsBold]
    end
  end
end
