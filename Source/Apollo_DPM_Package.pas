unit Apollo_DPM_Package;

interface

uses
  System.Generics.Collections,
  System.JSON;

type
  TVisibility = (vPrivate, vPublic);

  TPackageType = (ptSource);

  TPackage = class
  private
    FName: string;
    FPackageType: TPackageType;
    FRepoName: string;
    FRepoOwner: string;
    FVisibility: TVisibility;
    procedure Init;
  public
    function GetJSONString: string;
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    property Name: string read FName write FName;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property RepoName: string read FRepoName write FRepoName;
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    property Visibility: TVisibility read FVisibility write FVisibility;
  end;

  TPackageList = class(TObjectList<TPackage>)
  public
    function GetByName(const aPackageName: string): TPackage;
    constructor Create(const aJSONStrings: TArray<string>); overload;
  end;

implementation

uses
  System.SysUtils;

{ TPackage }

constructor TPackage.Create(const aJSONString: string);
var
  iPackageType: Integer;
  jsnPackage: TJSONObject;
begin
  Create;
  try
    jsnPackage := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
    try
      Name := jsnPackage.GetValue('name').Value;
      RepoOwner := jsnPackage.GetValue('repoOwner').Value;
      RepoName := jsnPackage.GetValue('repoName').Value;

      if jsnPackage.TryGetValue<Integer>('packageType', iPackageType) then
        PackageType := TPackageType(iPackageType);
    finally
      jsnPackage.Free;
    end;
  except
    on E : Exception do
      raise Exception.CreateFmt('Creation package from JSON error: %s', [E.Message]);
  end;
end;

constructor TPackage.Create;
begin
  inherited;
  Init;
end;

function TPackage.GetJSONString: string;
var
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.Create;
  try
    jsnObj.AddPair('name', Name);
    jsnObj.AddPair('repoOwner', RepoOwner);
    jsnObj.AddPair('repoName', RepoName);

    jsnObj.AddPair('packageType', TJSONNumber.Create(Ord(PackageType)));

    Result := jsnObj.ToJSON;
  finally
    jsnObj.Free;
  end;
end;

procedure TPackage.Init;
begin
  FVisibility := vPrivate;
end;

{ TPackageList }

constructor TPackageList.Create(const aJSONStrings: TArray<string>);
var
  sJSON: string;
begin
  inherited Create(True);

  for sJSON in aJSONStrings do
    Add(TPackage.Create(sJSON));
end;

function TPackageList.GetByName(const aPackageName: string): TPackage;
var
  Package: TPackage;
begin
  Result := nil;

  for Package in Self do
    if Package.Name = aPackageName then
      Exit(Package);
end;

end.
