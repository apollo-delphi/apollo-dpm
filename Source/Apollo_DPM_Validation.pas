unit Apollo_DPM_Validation;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

type
  TValidation = class
  private
    FDPMEngine: TDPMEngine;
  public
    function ValidatePackageName(const aValue: string; const aVisibility: TVisibility;
      out aErrorMsg: string): Boolean;
    constructor Create(aDPMEngine: TDPMEngine);
  end;

var
  Validation: TValidation;

implementation

uses
  Apollo_DPM_Consts;

{ TValidation }

constructor TValidation.Create(aDPMEngine: TDPMEngine);
begin
  FDPMEngine := aDPMEngine;
end;

function TValidation.ValidatePackageName(const aValue: string;
  const aVisibility: TVisibility; out aErrorMsg: string): Boolean;
begin
  Result := True;
  aErrorMsg := '';

  if aValue = '' then
  begin
    aErrorMsg := cStrTheFieldCannotBeEmpty;
    Exit(False);
  end;

  if aVisibility = vPrivate then
  begin
    if FDPMEngine.GetPrivatePackages.GetByName(aValue) <> nil then
    begin
      aErrorMsg := cStrAPackageWithThisNameAlreadyExists;
      Exit(False);
    end;
  end;
end;

end.
