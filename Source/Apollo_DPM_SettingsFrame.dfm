object SettingsFrame: TSettingsFrame
  Left = 0
  Top = 0
  Width = 392
  Height = 331
  TabOrder = 0
  object leGHPAToken: TLabeledEdit
    Left = 16
    Top = 42
    Width = 273
    Height = 21
    EditLabel.Width = 141
    EditLabel.Height = 13
    EditLabel.Caption = 'GitHub Personal access token'
    TabOrder = 1
  end
  object btnApply: TButton
    Left = 213
    Top = 300
    Width = 75
    Height = 25
    Action = actApply
    Anchors = [akRight, akBottom]
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 294
    Top = 300
    Width = 75
    Height = 25
    Action = actCancel
    Anchors = [akRight, akBottom]
    TabOrder = 4
  end
  object chkShowIndirectPkg: TCheckBox
    Left = 16
    Top = 74
    Width = 217
    Height = 17
    Caption = 'Show indirect packages in dependencies'
    TabOrder = 2
  end
  object btnUpdate: TButton
    Left = 294
    Top = 7
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Update'
    TabOrder = 0
    OnClick = btnUpdateClick
  end
  object alActions: TActionList
    Left = 344
    Top = 44
    object actApply: TAction
      Caption = 'Apply'
      OnExecute = actApplyExecute
    end
    object actCancel: TAction
      Caption = 'Cancel'
      OnExecute = actCancelExecute
    end
  end
end
