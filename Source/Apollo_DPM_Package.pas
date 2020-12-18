unit Apollo_DPM_Package;

interface

uses
  Apollo_DPM_Adjustment,
  Apollo_DPM_GitHubAPI,
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
    FAdjustment: TAdjustment;
    FAreVersionsLoaded: Boolean;
    FDescription: string;
    FFilePath: string;
    FID: string;
    FName: string;
    FPackageType: TPackageType;
    FRepoName: string;
    FRepoOwner: string;
    FRepoTree: TTree;
    FVersions: TArray<TVersion>;
    FVisibility: TVisibility;
    function GetID: string;
    procedure Init;
  public
    function GetJSONString: string;
    procedure AddVersion(const aVersion: TVersion);
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    destructor Destroy; override;
    property Adjustment: TAdjustment read FAdjustment;
    property AreVersionsLoaded: Boolean read FAreVersionsLoaded write FAreVersionsLoaded;
    property Description: string read FDescription write FDescription;
    property FilePath: string read FFilePath write FFilePath;
    property ID: string read GetID write FID;
    property Name: string read FName write FName;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property RepoName: string read FRepoName write FRepoName;
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    property RepoTree: TTree read FRepoTree write FRepoTree;
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

const
  cKeyId = 'id';
  cKeyName = 'name';
  cKeyDescription = 'description';
  cKeyRepoOwner = 'repoOwner';
  cKeyRepoName = 'repoName';
  cKeyPackageType = 'packageType';
  cKeyAdjustment = 'adjustment';

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
      ID := jsnObj.GetValue(cKeyId).Value;
      Name := jsnObj.GetValue(cKeyName).Value;
      Description := jsnObj.GetValue(cKeyDescription).Value;
      RepoOwner := jsnObj.GetValue(cKeyRepoOwner).Value;
      RepoName := jsnObj.GetValue(cKeyRepoName).Value;

      if jsnObj.TryGetValue<Integer>(cKeyPackageType, iPackageType) then
        PackageType := TPackageType(iPackageType);

      FAdjustment.SetJSON(jsnObj.GetValue(cKeyAdjustment) as TJSONObject);
    finally
      jsnObj.Free;
    end;
  except
    on E : Exception do
      raise Exception.CreateFmt('Creation package from JSON error: %s', [E.Message]);
  end;
end;

destructor TPackage.Destroy;
begin
  FAdjustment.Free;
  inherited;
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
    jsnObj.AddPair(cKeyId, ID);
    jsnObj.AddPair(cKeyName, Name);
    jsnObj.AddPair(cKeyDescription, Description);
    jsnObj.AddPair(cKeyRepoOwner, RepoOwner);
    jsnObj.AddPair(cKeyRepoName, RepoName);

    jsnObj.AddPair(cKeyPackageType, TJSONNumber.Create(Ord(PackageType)));

    jsnObj.AddPair(cKeyAdjustment, FAdjustment.GetJSON);

    Result := jsnObj.ToJSON;
  finally
    jsnObj.Free;
  end;
end;

procedure TPackage.Init;
begin
  FAdjustment := TAdjustment.Create;
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
