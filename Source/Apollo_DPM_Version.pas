unit Apollo_DPM_Version;

interface

uses
  Apollo_DPM_GitHubAPI,
  System.JSON,
  System.Generics.Collections;

type
  TVersion = class
  private
    FName: string;
    FRepoTree: TTree;
    FRepoTreeLoaded: Boolean;
    FSHA: string;
    function GetDisplayName: string;
    procedure Init;
  public
    function GetJSON: TJSONObject;
    procedure Assign(aVersion: TVersion);
    constructor Create; overload;
    constructor Create(aJSONObj: TJSONObject); overload;
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
    function AddVersion(const aPackageID: string; aVersion: TVersion): Boolean;
    function ContainsLoadedPackageID(const aPackageID: string): Boolean;
    function GetByPackageID(const aPackageID: string): TArray<TVersion>;
    constructor Create; reintroduce;
  end;

implementation

uses
  System.SysUtils;

const
  cKeyVersionName = 'name';
  cKeyVersionSHA = 'sha';

{ TVersion }

procedure TVersion.Assign(aVersion: TVersion);
begin
  Name := aVersion.Name;
  SHA := aVersion.SHA;
  RepoTree := aVersion.RepoTree;
end;

constructor TVersion.Create(aJSONObj: TJSONObject);
begin
  Init;

  Name := aJSONObj.GetValue(cKeyVersionName).Value;
  SHA := aJSONObj.GetValue(cKeyVersionSHA).Value;
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
begin
  Result := TJSONObject.Create;

  Result.AddPair(cKeyVersionName, Name);
  Result.AddPair(cKeyVersionSHA, SHA);
end;

procedure TVersion.Init;
begin
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

function TVersionCacheList.AddVersion(const aPackageID: string;
  aVersion: TVersion): Boolean;
begin
  if not ContainsSHA(aVersion.SHA) then
  begin
    Add(TVersionCache.Create(aPackageID, aVersion));
    Result := True;
  end
  else
    Result := False;
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
