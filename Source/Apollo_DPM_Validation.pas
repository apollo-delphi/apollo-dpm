unit Apollo_DPM_Validation;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  System.Classes,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TValidationItem = record
  public
    Control: TWinControl;
    OrigColor: TColor;
    Checked: Boolean;
    procedure Init;
    constructor Create(aControl: TWinControl);
  end;

  TValidation = class
  private
    FDPMEngine: TDPMEngine;
    FOutputLabel: TLabel;
    FValidationItems: TArray<TValidationItem>;
    function AddItem(aControl: TWinControl): TValidationItem;
    function GetItemByControl(aControl: TWinControl): TValidationItem;
    procedure CurrentFormDestroy(Sender: TObject);
    procedure RestoreColor(aControl: TWinControl);
    procedure SetChecked(aControl: TWinControl);
    procedure SetColor(aControl: TWinControl; aColor: TColor);
  public
    procedure Assert(const aActive: Boolean; aControl: TWinControl;
      const aValidStatement: Boolean; const aErrMsg: string; var aResult: Boolean);
    procedure SetOutputLabel(aLabel: TLabel);
    procedure Start(aForm: TForm);
    function ValidatePackageNameUniq(const aPackageID, aPackageName: string;
      const aVisibility: TVisibility): Boolean;
    constructor Create(aDPMEngine: TDPMEngine);
  end;

var
  Validation: TValidation;

implementation

uses
  Apollo_DPM_Consts,
  Vcl.ExtCtrls;

{ TValidation }

function TValidation.AddItem(aControl: TWinControl): TValidationItem;
begin
  Result := TValidationItem.Create(aControl);
  FValidationItems := FValidationItems + [Result];
end;

procedure TValidation.Assert(const aActive: Boolean; aControl: TWinControl;
  const aValidStatement: Boolean; const aErrMsg: string; var aResult: Boolean);
var
  Item: TValidationItem;
begin
  Item := GetItemByControl(aControl);
  if Item.Control = nil then
    Item := AddItem(aControl);

  if not Item.Checked then
    RestoreColor(aControl);

  if (not aActive) or (not aResult) then
    Exit;

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

  SetChecked(aControl);
end;

procedure TValidation.CurrentFormDestroy(Sender: TObject);
begin
  FValidationItems := [];
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

procedure TValidation.SetChecked(aControl: TWinControl);
var
  i: Integer;
begin
  for i := 0 to Length(FValidationItems) - 1 do
    if FValidationItems[i].Control = aControl then
      FValidationItems[i].Checked := True;
end;

procedure TValidation.SetColor(aControl: TWinControl; aColor: TColor);
begin
  if aControl is TLabeledEdit then
    TLabeledEdit(aControl).Color := aColor
  else
  if aControl is TFrame then
    TFrame(aControl).Color := aColor;
end;

procedure TValidation.SetOutputLabel(aLabel: TLabel);
begin
  FOutputLabel := aLabel;
  FOutputLabel.Visible := False;
end;

procedure TValidation.Start(aForm: TForm);
var
  i: Integer;
begin
  aForm.OnDestroy := CurrentFormDestroy;

  for i := 0 to Length(FValidationItems) - 1 do
    FValidationItems[i].Checked := False;
end;

function TValidation.ValidatePackageNameUniq(const aPackageID, aPackageName: string;
  const aVisibility: TVisibility): Boolean;
var
  Package: TPackage;
begin
  Result := True;

  if aVisibility = vPrivate then
  begin
    Package := FDPMEngine.GetPrivatePackages.GetByName(aPackageName);

    if Assigned(Package) and (Package.ID <> aPackageID) then
      Exit(False);
  end;
end;

{ TValidationItem }

constructor TValidationItem.Create(aControl: TWinControl);
begin
  Control := aControl;

  if aControl is TLabeledEdit then
    OrigColor := TLabeledEdit(aControl).Color
  else
  if aControl is TFrame then
    OrigColor := TFrame(aControl).Color;
end;

procedure TValidationItem.Init;
begin
  Control := nil;
  OrigColor := clWindow;
  Checked := False;
end;

end.
