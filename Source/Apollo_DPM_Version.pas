unit Apollo_DPM_Version;

interface

uses
  Apollo_DPM_GitHubAPI,
  System.JSON,
  System.Generics.Collections;

type
  TVersion = class
  private
    FDependencies: TArray<string>;
    FName: string;
    FRepoTree: TTree;
    FRepoTreeLoaded: Boolean;
    FSHA: string;
    function GetDisplayName: string;
    procedure Init;
  public
    function ContainsDependency(const ID: string): Boolean;
    function GetJSON: TJSONObject;
    procedure Assign(aVersion: TVersion);
    constructor Create; overload;
    constructor Create(aJSONObj: TJSONObject); overload;
    property Dependencies: TArray<string> read FDependencies write FDependencies;
    property DisplayName: string read GetDisplayName;
    property Name: string read FName write FName;
    property RepoTree: TTree read FRepoTree write FRepoTree;
    property RepoTreeLoaded: Boolean read FRepoTreeLoaded write FRepoTreeLoaded;
    property SHA: string read FSHA write FSHA;
  end;

  TVersionCache = class
  private
    FPackageID: string;
    FVersion: TVersion;
  public
    constructor Create(const aPackageID: string; aVersion: TVersion);
    destructor Destroy; override;
    property Version: TVersion read FVersion;
  end;

  TVersionCacheList = class(TObjectList<TVersionCache>)
  private
    FLoadedPackageIDs: TArray<string>;
    function ContainsSHA(const aSHA: string): Boolean;
    function GetBySHA(const aSHA: string): TVersion;
  public
    procedure AddLoadedPackageID(const aPackageID: string);
    function ContainsLoadedPackageID(const aPackageID: string): Boolean;
    function GetByPackageID(const aPackageID: string): TArray<TVersion>;
    function SyncVersion(const aPackageID: string; aVersion: TVersion): TVersion;
    constructor Create; reintroduce;
  end;

  TVersionCacheSyncFunc = function(const aPackageID: string; aVersion: TVersion): TVersion of object;

implementation

uses
  Apollo_DPM_Consts,
  System.SysUtils;

{ TVersion }

procedure TVersion.Assign(aVersion: TVersion);
begin
  Name := aVersion.Name;
  SHA := aVersion.SHA;
  RepoTree := aVersion.RepoTree;
end;

function TVersion.ContainsDependency(const ID: string): Boolean;
var
  Dependency: string;
begin
  Result := False;

  for Dependency in Dependencies do
    if Dependency = ID then
      Exit(True);
end;

constructor TVersion.Create(aJSONObj: TJSONObject);
var
  jsnDependencies: TJSONArray;
  jsnDependency: TJSONValue;
begin
  Init;

  Name := aJSONObj.GetValue(cKeyVersionName).Value;
  SHA := aJSONObj.GetValue(cKeyVersionSHA).Value;

  if aJSONObj.TryGetValue(cKeyDependencies, jsnDependencies) then
    for jsnDependency in jsnDependencies do
      Dependencies := Dependencies + [jsnDependency.Value];
end;

constructor TVersion.Create;
begin
  Init;
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
var
  Dependency: string;
  jsnDependencies: TJSONArray;
begin
  Result := TJSONObject.Create;

  Result.AddPair(cKeyVersionName, Name);
  Result.AddPair(cKeyVersionSHA, SHA);

  if Length(Dependencies) > 0 then
  begin
    jsnDependencies := TJSONArray.Create;
    for Dependency in Dependencies do
      jsnDependencies.Add(Dependency);

    Result.AddPair(cKeyDependencies, jsnDependencies);
  end;
end;

procedure TVersion.Init;
begin
  FDependencies := [];
  FRepoTree := [];
  FRepoTreeLoaded := False;
end;

{ TVersionCache }

constructor TVersionCache.Create(const aPackageID: string; aVersion: TVersion);
begin
  FPackageID := aPackageID;
  FVersion := aVersion;
end;

destructor TVersionCache.Destroy;
begin
  FVersion.Free;

  inherited;
end;

{ TVersionCacheList }

procedure TVersionCacheList.AddLoadedPackageID(const aPackageID: string);
begin
  if not ContainsLoadedPackageID(aPackageID) then
    FLoadedPackageIDs := FLoadedPackageIDs + [aPackageID];
end;

function TVersionCacheList.SyncVersion(const aPackageID: string;
  aVersion: TVersion): TVersion;
begin
  if ContainsSHA(aVersion.SHA) then
  begin
    Result := GetBySHA(aVersion.SHA);
    FreeAndNil(aVersion);
  end
  else
  begin
    Result := aVersion;
    Add(TVersionCache.Create(aPackageID, aVersion));
  end;
end;

function TVersionCacheList.ContainsLoadedPackageID(const aPackageID: string): Boolean;
var
  PackageID: string;
begin
  Result := False;

  for PackageID in FLoadedPackageIDs do
    if PackageID = aPackageID then
      Exit(True);
end;

function TVersionCacheList.ContainsSHA(const aSHA: string): Boolean;
begin
  Result := GetBySHA(aSHA) <> nil;
end;

constructor TVersionCacheList.Create;
begin
  inherited Create(True);
  FLoadedPackageIDs := [];
end;

function TVersionCacheList.GetByPackageID(
  const aPackageID: string): TArray<TVersion>;
var
  VersionCache: TVersionCache;
begin
  Result := [];

  for VersionCache in Self do
    if VersionCache.FPackageID = aPackageID then
      Result := Result + [VersionCache.Version];
end;

function TVersionCacheList.GetBySHA(const aSHA: string): TVersion;
var
  VersionCache: TVersionCache;
begin
  Result := nil;

  for VersionCache in Self do
    if VersionCache.Version.SHA = aSHA then
      Exit(VersionCache.Version);
end;

end.
