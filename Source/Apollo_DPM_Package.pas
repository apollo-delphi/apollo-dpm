unit Apollo_DPM_Package;

interface

uses
  System.Generics.Collections,
  System.JSON;

type
  TVersion = record
  public
    Name: string;
    SHA: string;
  end;

  TVisibility = (vPrivate, vPublic);

  TPackageType = (ptSource);

  TPackage = class
  private
    FAreVersionsLoaded: Boolean;
    FDescription: string;
    FFilePath: string;
    FID: string;
    FName: string;
    FPackageType: TPackageType;
    FRepoName: string;
    FRepoOwner: string;
    FVersions: TArray<TVersion>;
    FVisibility: TVisibility;
    function GetID: string;
    procedure Init;
  public
    function GetJSONString: string;
    procedure AddVersion(const aVersion: TVersion);
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    property AreVersionsLoaded: Boolean read FAreVersionsLoaded write FAreVersionsLoaded;
    property Description: string read FDescription write FDescription;
    property FilePath: string read FFilePath write FFilePath;
    property ID: string read GetID write FID;
    property Name: string read FName write FName;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property RepoName: string read FRepoName write FRepoName;
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    property Versions: TArray<TVersion> read FVersions;
    property Visibility: TVisibility read FVisibility write FVisibility;
  end;

  TPackageFileData = record
    FilePath: string;
    JSONString: string;
  end;

  TPackageList = class(TObjectList<TPackage>)
  public
    function GetByName(const aPackageName: string): TPackage;
    constructor Create(const aPackageFileDataArr: TArray<TPackageFileData>); overload;
  end;

implementation

uses
  System.SysUtils;

{ TPackage }

procedure TPackage.AddVersion(const aVersion: TVersion);
begin
  FVersions := FVersions + [aVersion];
end;

constructor TPackage.Create(const aJSONString: string);
var
  iPackageType: Integer;
  jsnObj: TJSONObject;
begin
  Create;
  try
    jsnObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
    try
      ID := jsnObj.GetValue('id').Value;
      Name := jsnObj.GetValue('name').Value;
      Description := jsnObj.GetValue('description').Value;
      RepoOwner := jsnObj.GetValue('repoOwner').Value;
      RepoName := jsnObj.GetValue('repoName').Value;

      if jsnObj.TryGetValue<Integer>('packageType', iPackageType) then
        PackageType := TPackageType(iPackageType);
    finally
      jsnObj.Free;
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

function TPackage.GetID: string;
var
  GUID: TGUID;
begin
  if FID.IsEmpty then
  begin
    CreateGUID(GUID);
    FID := GUID.ToString;
  end;

  Result := FID;
end;

function TPackage.GetJSONString: string;
var
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.Create;
  try
    jsnObj.AddPair('id', ID);
    jsnObj.AddPair('name', Name);
    jsnObj.AddPair('description', Description);
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
  FVersions := [];
  FVisibility := vPrivate;
end;

{ TPackageList }

constructor TPackageList.Create(const aPackageFileDataArr: TArray<TPackageFileData>);
var
  Package: TPackage;
  PackageFileData: TPackageFileData;
begin
  inherited Create(True);

  for PackageFileData in aPackageFileDataArr do
  begin
    Package := TPackage.Create(PackageFileData.JSONString);
    Package.FilePath := PackageFileData.FilePath;
    Add(Package);
  end;
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
