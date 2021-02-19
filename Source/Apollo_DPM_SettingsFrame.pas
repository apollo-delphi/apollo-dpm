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
    chkShowIndirectPkg: TCheckBox;
    btnUpdate: TButton;
    procedure actApplyExecute(Sender: TObject);
    procedure actCancelExecute(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FEditableControls: TArray<TControl>;
    procedure DisenableEdit;
    procedure EnableEdit;
    procedure ReadFromControls;
    procedure WriteToControls;
  public
    constructor Create(aOwner: TComponent; aDPMEngine: TDPMEngine); reintroduce;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_UIHelper;

{ TSettingsFrame }

procedure TSettingsFrame.actApplyExecute(Sender: TObject);
begin
  ReadFromControls;
  FDPMEngine.ApplyAndSaveSettings;
  DisenableEdit;
end;

procedure TSettingsFrame.actCancelExecute(Sender: TObject);
begin
  WriteToControls;
  DisenableEdit;
end;

procedure TSettingsFrame.btnUpdateClick(Sender: TObject);
begin
  EnableEdit;
end;

constructor TSettingsFrame.Create(aOwner: TComponent; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  FDPMEngine := aDPMEngine;
  WriteToControls;

  FEditableControls := [leGHPAToken, chkShowIndirectPkg];
  DisenableEdit;
end;

procedure TSettingsFrame.DisenableEdit;
begin
  SetControlsEnable(False, FEditableControls);
  SetControlsEnable(False, [btnApply, btnCancel]);
  SetControlsEnable(True, [btnUpdate]);
end;

procedure TSettingsFrame.EnableEdit;
begin
  SetControlsEnable(True, FEditableControls);
  SetControlsEnable(True, [btnApply, btnCancel]);
  SetControlsEnable(False, [btnUpdate]);
end;

procedure TSettingsFrame.ReadFromControls;
begin
  FDPMEngine.Settings.GHPAToken := leGHPAToken.Text;
  FDPMEngine.Settings.ShowIndirectPackages := chkShowIndirectPkg.Checked;
end;

procedure TSettingsFrame.WriteToControls;
begin
  leGHPAToken.Text := FDPMEngine.Settings.GHPAToken;
  chkShowIndirectPkg.Checked := FDPMEngine.Settings.ShowIndirectPackages;
end;

end.
