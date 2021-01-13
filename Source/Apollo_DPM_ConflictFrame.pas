unit Apollo_DPM_ConflictFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Apollo_DPM_Types,
  Apollo_DPM_Version;

type
  TConflictFrame = class(TFrame)
    lblPackageBegin: TLabel;
    lblInstalledCaption: TLabel;
    rbKeepInstalled: TRadioButton;
    lblRequiredCaption: TLabel;
    rbUpdateToRequired: TRadioButton;
    lblPackage: TLabel;
    lblPackageEnd: TLabel;
    lblInstalledVersion: TLabel;
    lblRequiredVersion: TLabel;
  private
    FVersionConflict: TVersionConflict;
  public
    function GetSelection: TVersion;
    function GetVersionConflictWithSelection: TVersionConflict;
    procedure RenderVersionConflict(const aVersionConflict: TVersionConflict);
    constructor Create(aOwner: TWinControl; const aIndex: Integer); reintroduce;
  end;

implementation

{$R *.dfm}

{ TConflictFrame }

constructor TConflictFrame.Create(aOwner: TWinControl; const aIndex: Integer);
begin
  inherited Create(aOwner);

  Name := Format('ConflictFrame%d', [aIndex]);
  Parent := aOwner;
  Left := 0;
  Width := aOwner.Width;

  Top := (Height + 2) * aIndex;
  if not Odd(aIndex) then
    Color := clBtnFace;
end;

function TConflictFrame.GetSelection: TVersion;
begin
  if rbKeepInstalled.Checked then
    Result := FVersionConflict.InstalledVersion
  else
  if rbUpdateToRequired.Checked then
    Result := FVersionConflict.RequiredVersion
  else
    Result := nil;
end;

function TConflictFrame.GetVersionConflictWithSelection: TVersionConflict;
begin
  Result := FVersionConflict;
  Result.Selection := GetSelection;
end;

procedure TConflictFrame.RenderVersionConflict(
  const aVersionConflict: TVersionConflict);
begin
  lblPackage.Caption := aVersionConflict.DependentPackage.Name;
  lblPackageEnd.Left := lblPackage.Left + lblPackage.Width + 4;

  lblInstalledVersion.Caption := aVersionConflict.InstalledVersion.DisplayName;
  lblRequiredVersion.Caption := aVersionConflict.RequiredVersion.DisplayName;

  FVersionConflict := aVersionConflict;
end;

end.
