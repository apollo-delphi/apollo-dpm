unit Apollo_DPM_Validation;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TValidationItem = record
  public
    Control: TWinControl;
    OrigColor: TColor;
    procedure Init;
    constructor Create(aControl: TWinControl);
  end;

  TValidation = class
  private
    FDPMEngine: TDPMEngine;
    FOutputLabel: TLabel;
    FValidationItems: TArray<TValidationItem>;
    function GetItemByControl(aControl: TWinControl): TValidationItem;
    procedure AddItemIfNotContains(aControl: TWinControl);
    procedure RestoreColor(aControl: TWinControl);
    procedure SetColor(aControl: TWinControl; aColor: TColor);
  public
    procedure Assert(const aActive: Boolean; aControl: TWinControl;
      const aValidStatement: Boolean; const aErrMsg: string; var aResult: Boolean);
    procedure SetOutputLabel(aLabel: TLabel);
    function ValidatePackageNameUniq(const aValue: string; const aVisibility: TVisibility): Boolean;
    constructor Create(aDPMEngine: TDPMEngine);
  end;

var
  Validation: TValidation;

implementation

uses
  Apollo_DPM_Consts,
  Vcl.ExtCtrls;

{ TValidation }

procedure TValidation.AddItemIfNotContains(aControl: TWinControl);
begin
  if GetItemByControl(aControl).Control = nil then
    FValidationItems := FValidationItems + [TValidationItem.Create(aControl)];
end;

procedure TValidation.Assert(const aActive: Boolean; aControl: TWinControl;
  const aValidStatement: Boolean; const aErrMsg: string; var aResult: Boolean);
begin
  AddItemIfNotContains(aControl);

  if (not aActive) or (not aResult) then
  begin
    RestoreColor(aControl);
    Exit;
  end;

  if not aValidStatement then
  begin
    if Assigned(FOutputLabel) then
    begin
      FOutputLabel.Caption := aErrMsg;
      FOutputLabel.Visible := True;
    end;

    aResult := False;
    SetColor(aControl, clRed);
  end;
end;

constructor TValidation.Create(aDPMEngine: TDPMEngine);
begin
  FDPMEngine := aDPMEngine;
  FValidationItems := [];
end;

function TValidation.GetItemByControl(aControl: TWinControl): TValidationItem;
var
  Item: TValidationItem;
begin
  Result.Init;

  for Item in FValidationItems do
    if Item.Control = aControl then
      Exit(Item);
end;

procedure TValidation.RestoreColor(aControl: TWinControl);
var
  Item: TValidationItem;
begin
  Item := GetItemByControl(aControl);

  if Item.Control <> nil then
    SetColor(aControl, Item.OrigColor);
end;

procedure TValidation.SetColor(aControl: TWinControl; aColor: TColor);
begin
  if aControl is TLabeledEdit then
    TLabeledEdit(aControl).Color := aColor;
end;

procedure TValidation.SetOutputLabel(aLabel: TLabel);
begin
  FOutputLabel := aLabel;
  FOutputLabel.Visible := False;
end;

function TValidation.ValidatePackageNameUniq(const aValue: string;
  const aVisibility: TVisibility): Boolean;
begin
  Result := True;

  if aVisibility = vPrivate then
  begin
    if FDPMEngine.GetPrivatePackages.GetByName(aValue) <> nil then
      Exit(False);
  end;
end;

{ TValidationItem }

constructor TValidationItem.Create(aControl: TWinControl);
begin
  Control := aControl;

  if aControl is TLabeledEdit then
    OrigColor := TLabeledEdit(aControl).Color;
end;

procedure TValidationItem.Init;
begin
  Control := nil;
  OrigColor := clWindow;
end;

end.
