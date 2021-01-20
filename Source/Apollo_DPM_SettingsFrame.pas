unit Apollo_DPM_SettingsFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Types, System.Actions, Vcl.ActnList;

type
  TSettingsFrame = class(TFrame)
    leGHPAToken: TLabeledEdit;
    btnApply: TButton;
    btnCancel: TButton;
    alActions: TActionList;
    actApply: TAction;
    actCancel: TAction;
    procedure actApplyExecute(Sender: TObject);
    procedure actApplyUpdate(Sender: TObject);
    procedure actCancelExecute(Sender: TObject);
    procedure actCancelUpdate(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    procedure ClearModified;
    procedure ReadFromControls;
    procedure WriteToControls;
  public
    constructor Create(aOwner: TComponent; aDPMEngine: TDPMEngine); reintroduce;
  end;

implementation

{$R *.dfm}

{ TSettingsFrame }

procedure TSettingsFrame.actApplyExecute(Sender: TObject);
begin
  ReadFromControls;
  FDPMEngine.ApplyAndSaveSettings;
  ClearModified;
end;

procedure TSettingsFrame.actApplyUpdate(Sender: TObject);
begin
  actApply.Enabled := leGHPAToken.Modified;
end;

procedure TSettingsFrame.actCancelExecute(Sender: TObject);
begin
  WriteToControls;
  ClearModified;
end;

procedure TSettingsFrame.actCancelUpdate(Sender: TObject);
begin
  actCancel.Enabled := actApply.Enabled;
end;

procedure TSettingsFrame.ClearModified;
var
  i: Integer;
begin
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TCustomEdit then
      TCustomEdit(Components[i]).Modified := False;
end;

constructor TSettingsFrame.Create(aOwner: TComponent; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  FDPMEngine := aDPMEngine;
  WriteToControls;
end;

procedure TSettingsFrame.ReadFromControls;
begin
  FDPMEngine.Settings.GHPAToken := leGHPAToken.Text;
end;

procedure TSettingsFrame.WriteToControls;
begin
  leGHPAToken.Text := FDPMEngine.Settings.GHPAToken;
end;

end.
