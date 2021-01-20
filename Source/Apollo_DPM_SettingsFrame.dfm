object SettingsFrame: TSettingsFrame
  Left = 0
  Top = 0
  Width = 349
  Height = 206
  TabOrder = 0
  object leGHPAToken: TLabeledEdit
    Left = 16
    Top = 24
    Width = 273
    Height = 21
    EditLabel.Width = 141
    EditLabel.Height = 13
    EditLabel.Caption = 'GitHub Personal access token'
    TabOrder = 0
  end
  object btnApply: TButton
    Left = 173
    Top = 175
    Width = 75
    Height = 25
    Action = actApply
    Anchors = [akRight, akBottom]
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 254
    Top = 175
    Width = 75
    Height = 25
    Action = actCancel
    Anchors = [akRight, akBottom]
    TabOrder = 2
  end
  object alActions: TActionList
    Left = 304
    Top = 8
    object actApply: TAction
      Caption = 'Apply'
      OnExecute = actApplyExecute
      OnUpdate = actApplyUpdate
    end
    object actCancel: TAction
      Caption = 'Cancel'
      OnExecute = actCancelExecute
      OnUpdate = actCancelUpdate
    end
  end
end
