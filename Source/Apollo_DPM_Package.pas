unit Apollo_DPM_Package;

interface

uses
  System.JSON;

type
  TVisibility = (vPrivate, vPublic);

  TPackageType = (ptSource);

  TPackage = class
  private
    FName: string;
    FPackageType: TPackageType;
    FVisibility: TVisibility;
    procedure Init;
  public
    function CreateJSON: TJSONObject;
    constructor Create;
    property Name: string read FName write FName;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property Visibility: TVisibility read FVisibility write FVisibility;
  end;

implementation

{ TPackage }

constructor TPackage.Create;
begin
  Init;
end;

function TPackage.CreateJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('name', Name);
  Result.AddPair('packageType', TJSONNumber.Create(Ord(PackageType)));
end;

procedure TPackage.Init;
begin
  FVisibility := vPrivate;
end;

end.
