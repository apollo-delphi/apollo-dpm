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
    function GetDisplayName: string;
    function GetJSON: TJSONObject;
    function IsEmpty: Boolean;
    procedure Init;
    constructor Create(aJSONObj: TJSONObject);
  end;

  TVersionsHelper = record helper for TArray<TVersion>
    function Contain(const aVersion: TVersion): Boolean;
    function Count: Integer;
  end;

  TVisibility = (vPrivate, vPublic);

  TPackageSide = (psInitial, psDependent);

  TPackageType = (ptSource);

  TPackage = class
  private
    FAdjustment: TAdjustment;
    FAreVersionsLoaded: Boolean;
    FDescription: string;
    FFilePath: string;
    FID: string;
    FName: string;
    FPackageSide: TPackageSide;
    FPackageType: TPackageType;
    FRepoName: string;
    FRepoOwner: string;
    FRepoTree: TTree;
    FVersion: TVersion;
    FVersions: TArray<TVersion>;
    FVisibility: TVisibility;
    function AllowByBlackList(const aPath: string): Boolean;
    function AllowByWhiteList(const aPath: string): Boolean;
    function GetID: string;
    procedure Init;
    procedure SetVersion(const aVersion: TVersion);
  public
    function AllowPath(const aPath: string): Boolean;
    function ApplyPathMoves(const aPath: string): string;
    function GetJSON: TJSONObject;
    function GetJSONString: string;
    procedure AddVersion(const aVersion: TVersion);
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    constructor Create(aPackage: TPackage); overload;
    destructor Destroy; override;
    property Adjustment: TAdjustment read FAdjustment;
    property AreVersionsLoaded: Boolean read FAreVersionsLoaded write FAreVersionsLoaded;
    property Description: string read FDescription write FDescription;
    property FilePath: string read FFilePath write FFilePath;
    property ID: string read GetID write FID;
    property Name: string read FName write FName;
    property PackageSide: TPackageSide read FPackageSide;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property RepoName: string read FRepoName write FRepoName;
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    property RepoTree: TTree read FRepoTree write FRepoTree;
    property Version: TVersion read FVersion write SetVersion;
    property Versions: TArray<TVersion> read FVersions;
    property Visibility: TVisibility read FVisibility write FVisibility;
  end;

  TPackageFileData = record
    FilePath: string;
    JSONString: string;
  end;

  TPackageList = class(TObjectList<TPackage>)
  public
    function GetByID(const aID: string): TPackage;
    function GetByName(const aPackageName: string): TPackage;
    function GetJSONString: string;
    procedure SyncToExternal(aPackage: TPackage);
    constructor Create(const aPackageFileDataArr: TArray<TPackageFileData>); overload;
    constructor Create(const aJSONString: string); overload;
  end;

implementation

uses
  System.SysUtils;

const
  cKeyAdjustment = 'adjustment';
  cKeyDescription = 'description';
  cKeyId = 'id';
  cKeyName = 'name';
  cKeyRepoOwner = 'repoOwner';
  cKeyRepoName = 'repoName';
  cKeyPackageType = 'packageType';
  cKeyVersion = 'version';
  cKeyVersionName = 'name';
  cKeyVersionSHA = 'sha';

{ TPackage }

procedure TPackage.AddVersion(const aVersion: TVersion);
begin
  if not FVersions.Contain(aVersion) then
    FVersions := FVersions + [aVersion];
end;

function TPackage.AllowByBlackList(const aPath: string): Boolean;
var
  FilteItem: string;
begin
  Result := True;

  for FilteItem in Adjustment.FilterList do
    if aPath.StartsWith(FilteItem) then
      Exit(False);
end;

function TPackage.AllowByWhiteList(const aPath: string): Boolean;
var
  FilteItem: string;
begin
  Result := False;

  for FilteItem in Adjustment.FilterList do
    if aPath.StartsWith(FilteItem) then
      Exit(True);
end;

function TPackage.AllowPath(const aPath: string): Boolean;
begin
  Result := True;

  case Adjustment.FilterListType of
    fltBlack: Result := AllowByBlackList(aPath);
    fltWhite: Result := AllowByWhiteList(aPath);
  end;
end;

function TPackage.ApplyPathMoves(const aPath: string): string;
var
  PathMove: TPathMove;
begin
  Result := aPath;

  for PathMove in Adjustment.PathMoves do
    Result := Result.Replace(PathMove.Source, PathMove.Destination);

  Result := Result.Replace('\\', '\', [rfReplaceAll]);
end;

constructor TPackage.Create(aPackage: TPackage);
begin
  Create;
  FPackageSide := psDependent;

  ID := aPackage.ID;
  Name := aPackage.Name;
  Description := aPackage.Description;
  RepoOwner := aPackage.RepoOwner;
  RepoName := aPackage.RepoName;
  Version := aPackage.Version;
end;

function TPackage.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(cKeyId, ID);
  Result.AddPair(cKeyName, Name);
  Result.AddPair(cKeyDescription, Description);
  Result.AddPair(cKeyRepoOwner, RepoOwner);
  Result.AddPair(cKeyRepoName, RepoName);

  Result.AddPair(cKeyPackageType, TJSONNumber.Create(Ord(PackageType)));

  if FPackageSide = psDependent then
    Result.AddPair(cKeyVersion, Version.GetJSON);

  if FPackageSide = psInitial then
    Result.AddPair(cKeyAdjustment, FAdjustment.GetJSON);
end;

constructor TPackage.Create(const aJSONString: string);
var
  iPackageType: Integer;
  jsnAdjustment: TJSONObject;
  jsnObj: TJSONObject;
  jsnVersion: TJSONObject;
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

      if jsnObj.TryGetValue(cKeyVersion, jsnVersion) then
        Version := TVersion.Create(jsnVersion);

      if jsnObj.TryGetValue(cKeyAdjustment, jsnAdjustment) then
        FAdjustment.SetJSON(jsnAdjustment);
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
  jsnObj := GetJSON;
  try
    Result := jsnObj.ToJSON;
  finally
    jsnObj.Free;
  end;
end;

procedure TPackage.Init;
begin
  FAdjustment := TAdjustment.Create;
  FVersion.Init;
  FVersions := [];
  FPackageSide := psInitial;
  FVisibility := vPrivate;
end;

procedure TPackage.SetVersion(const aVersion: TVersion);
begin
  FVersion := aVersion;
  AddVersion(aVersion);
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

constructor TPackageList.Create(const aJSONString: string);
var
  jsnArr: TJSONArray;
  jsnVal: TJSONValue;
  Package: TPackage;
begin
  inherited Create(True);

  jsnArr := TJSONObject.ParseJSONValue(aJSONString) as TJSONArray;
  try
    for jsnVal in jsnArr do
    begin
      Package := TPackage.Create(jsnVal.ToJSON);
      Package.FPackageSide := psDependent;
      Add(Package);
    end;
  finally
    jsnArr.Free;
  end;
end;

function TPackageList.GetByID(const aID: string): TPackage;
var
  Package: TPackage;
begin
  Result := nil;

  for Package in Self do
    if Package.ID = aID then
      Exit(Package);
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

function TPackageList.GetJSONString: string;
var
  jsnArr: TJSONArray;
  Package: TPackage;
begin
  jsnArr := TJSONArray.Create;
  try
    for Package in Self do
      jsnArr.Add(Package.GetJSON);

    Result := jsnArr.ToJSON;
  finally
    jsnArr.Free;
  end;
end;

procedure TPackageList.SyncToExternal(aPackage: TPackage);
var
  Package: TPackage;
begin
  Package := GetByID(aPackage.ID);
  if Package <> nil then
  begin
    aPackage.Version := Package.Version;
  end;
end;

{ TVersion }

constructor TVersion.Create(aJSONObj: TJSONObject);
begin
  Name := aJSONObj.GetValue(cKeyVersionName).Value;
  SHA := aJSONObj.GetValue(cKeyVersionSHA).Value;
end;

function TVersion.GetDisplayName: string;
begin
  Result := '';

  if not Name.IsEmpty then
    Result := Name
  else
  if not SHA.IsEmpty then
    Result := Format('commit %s...', [SHA.Substring(0, 13)]);
end;

function TVersion.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(cKeyVersionName, Name);
  Result.AddPair(cKeyVersionSHA, SHA);
end;

procedure TVersion.Init;
begin
  Name := '';
  SHA := '';
end;

function TVersion.IsEmpty: Boolean;
begin
  Result := Name.IsEmpty and SHA.IsEmpty;
end;

{TVersionsHelper}

function TVersionsHelper.Count: Integer;
begin
  Result := Length(Self);
end;

function TVersionsHelper.Contain(const aVersion: TVersion): Boolean;
var
  Version: TVersion;
begin
  Result := False;

  for Version in Self do
    if Version.SHA = aVersion.SHA then
      Exit(True);
end;

end.
