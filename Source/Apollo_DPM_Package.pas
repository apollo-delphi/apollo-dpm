unit Apollo_DPM_Package;

interface

uses
  Apollo_DPM_Version,
  System.Generics.Collections,
  System.JSON;

type
  TVisibility = (vPrivate, vPublic);

  TPackageType = (ptSource);

  TPackage = class abstract
  private
    FDescription: string;
    FID: string;
    FJSON: TJSONObject;
    FName: string;
    FPackageType: TPackageType;
    FRepoName: string;
    FRepoOwner: string;
    FVisibility: TVisibility;
    function GetID: string;
    procedure FreeJSON;
  protected
    function GetJSON: TJSONObject; virtual;
    procedure Init; virtual;
    procedure SetJSON(aJSONObj: TJSONObject); virtual;
  public
    function GetJSONString: string;
    procedure Assign(aPackage: TPackage); virtual;
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    destructor Destroy; override;
    property Description: string read FDescription write FDescription;
    property ID: string read GetID write FID;
    property Name: string read FName write FName;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property RepoName: string read FRepoName write FRepoName;
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    property Visibility: TVisibility read FVisibility write FVisibility;
  end;

  TFilterListType = (fltNone, fltBlack, fltWhite);

  TPathMove = record
    Destination: string;
    Source: string;
  end;

  TDependentPackage = class;

  TInitialPackage = class(TPackage)
  private
    FDependentPackage: TDependentPackage;
    FFilterList: TArray<string>;
    FFilterListType: TFilterListType;
    FPathMoves: TArray<TPathMove>;
    function AllowByBlackList(const aPath: string): Boolean;
    function AllowByWhiteList(const aPath: string): Boolean;
  protected
    function GetJSON: TJSONObject; override;
    procedure Init; override;
    procedure SetJSON(aJSONObj: TJSONObject); override;
  public
    function AllowPath(const aPath: string): Boolean;
    function ApplyPathMoves(const aPath: string): string;
    property DependentPackage: TDependentPackage read FDependentPackage write FDependentPackage;
    property FilterList: TArray<string> read FFilterList write FFilterList;
    property FilterListType: TFilterListType read FFilterListType write FFilterListType;
    property PathMoves: TArray<TPathMove> read FPathMoves write FPathMoves;
  end;

  TDependentPackage = class(TPackage)
  private
    FVersion: TVersion;
  protected
    function GetJSON: TJSONObject; override;
    procedure SetJSON(aJSONObj: TJSONObject); override;
  public
    constructor Create(aInitialPackage: TInitialPackage); overload;
    property Version: TVersion read FVersion write FVersion;
  end;

  TDependentPackageList = class(TObjectList<TDependentPackage>)
 public
    function GetByID(const aID: string): TDependentPackage;
    function GetJSONString: string;
    constructor Create; reintroduce; overload;
    constructor Create(const aJSONString: string); reintroduce; overload;
  end;

  TPrivatePackage = class(TInitialPackage)
  private
    FFilePath: string;
  public
    property FilePath: string read FFilePath write FFilePath;
  end;

  TPrivatePackageFile = record
    JSONString: string;
    Path: string;
  end;

  TPrivatePackageList = class(TObjectList<TPrivatePackage>)
  public
    function GetByID(const aID: string): TPrivatePackage;
    function GetByName(const aPackageName: string): TPrivatePackage;
    constructor Create(const aPrivatePackageFiles: TArray<TPrivatePackageFile>); reintroduce;
  end;

  {TPackageList = class(TObjectList<TPackage>)
  public
    function GetByID(const aID: string): TPackage;
    function GetByName(const aPackageName: string): TPackage;
    function GetJSONString: string;
    procedure RemoveByID(const aID: string);
    procedure SyncToExternal(aPackage: TPackage);
  end;}

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

  cKeyFilterListType = 'filterListType';
  cKeyFilterList = 'filterList';
  cKeyPathMoves = 'pathMoves';
  cKeySource = 'source';
  cKeyDestination = 'destination';

{ TPackage }

procedure TPackage.SetJSON(aJSONObj: TJSONObject);
begin
  ID := aJSONObj.GetValue(cKeyId).Value;
  Name := aJSONObj.GetValue(cKeyName).Value;
  Description := aJSONObj.GetValue(cKeyDescription).Value;
  RepoOwner := aJSONObj.GetValue(cKeyRepoOwner).Value;
  RepoName := aJSONObj.GetValue(cKeyRepoName).Value;
  PackageType := TPackageType(aJSONObj.GetValue<Integer>(cKeyPackageType));
end;

constructor TPackage.Create(const aJSONString: string);
var
  jsnObj: TJSONObject;
begin
  Init;

  try
    jsnObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
    try
      SetJSON(jsnObj);
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
  FreeJSON;

  inherited;
end;

procedure TPackage.Assign(aPackage: TPackage);
begin
  ID := aPackage.ID;
  Name := aPackage.Name;
  Description := aPackage.Description;
  RepoOwner := aPackage.RepoOwner;
  RepoName := aPackage.RepoName;
end;

constructor TPackage.Create;
begin
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

function TPackage.GetJSON: TJSONObject;
begin
  FreeJSON;

  FJSON := TJSONObject.Create;
  FJSON.Owned := False;
  Result := FJSON;

  Result.AddPair(cKeyId, ID);
  Result.AddPair(cKeyName, Name);
  Result.AddPair(cKeyDescription, Description);
  Result.AddPair(cKeyRepoOwner, RepoOwner);
  Result.AddPair(cKeyRepoName, RepoName);
  Result.AddPair(cKeyPackageType, TJSONNumber.Create(Ord(PackageType)));
end;

function TPackage.GetJSONString: string;
begin
  Result := GetJSON.ToJSON
end;

procedure TPackage.Init;
begin
  FVisibility := vPrivate;
end;

procedure TPackage.FreeJSON;
begin
  if Assigned(FJSON) then
    FreeAndNil(FJSON);
end;


{ TInitialPackage }

function TInitialPackage.AllowByBlackList(const aPath: string): Boolean;
var
  FilterItem: string;
begin
  Result := True;

  for FilterItem in FFilterList do
    if aPath.StartsWith(FilterItem) then
      Exit(False);
end;

function TInitialPackage.AllowByWhiteList(const aPath: string): Boolean;
var
  FilteItem: string;
begin
  Result := False;

  for FilteItem in FFilterList do
    if aPath.StartsWith(FilteItem) then
      Exit(True);
end;

function TInitialPackage.AllowPath(const aPath: string): Boolean;
begin
  Result := True;

  case FFilterListType of
    fltBlack: Result := AllowByBlackList(aPath);
    fltWhite: Result := AllowByWhiteList(aPath);
  end;
end;

function TInitialPackage.ApplyPathMoves(const aPath: string): string;
var
  PathMove: TPathMove;
begin
  Result := aPath;

  for PathMove in FPathMoves do
    Result := Result.Replace(PathMove.Source, PathMove.Destination);

  Result := Result.Replace('\\', '\', [rfReplaceAll]);
end;

procedure TInitialPackage.SetJSON(aJSONObj: TJSONObject);
var
  iFilterListType: Integer;
  jsnFilterList: TJSONArray;
  jsnPathMoves: TJSONArray;
  jsnVal: TJSONValue;
  PathMove: TPathMove;
begin
  inherited;

  if aJSONObj.TryGetValue<Integer>(cKeyFilterListType, iFilterListType) then
    FilterListType := TFilterListType(iFilterListType);

  FilterList := [];
  if aJSONObj.TryGetValue(cKeyFilterList, jsnFilterList) then
    for jsnVal in jsnFilterList do
      FilterList := FilterList + [jsnVal.Value];

  PathMoves := [];
  if aJSONObj.TryGetValue(cKeyPathMoves, jsnPathMoves) then
    for jsnVal in jsnPathMoves do
    begin
      PathMove.Source := (jsnVal as TJSONObject).GetValue(cKeySource).Value;
      PathMove.Destination := (jsnVal as TJSONObject).GetValue(cKeyDestination).Value;

      PathMoves := PathMoves + [PathMove];
    end;
end;

function TInitialPackage.GetJSON: TJSONObject;
var
  FilterListItem: string;
  PathMove: TPathMove;
  jsnFilterList: TJSONArray;
  jsnPathMove: TJSONObject;
  jsnPathMoves: TJSONArray;
begin
  Result := inherited GetJSON;

  Result.AddPair(cKeyFilterListType, TJSONNumber.Create(Ord(FilterListType)));

  if Length(FilterList) > 0 then
  begin
    jsnFilterList := TJSONArray.Create;

    for FilterListItem in FilterList do
      jsnFilterList.Add(FilterListItem);

    Result.AddPair(cKeyFilterList, jsnFilterList);
  end;

  if Length(FPathMoves) > 0 then
  begin
    jsnPathMoves := TJSONArray.Create;

    for PathMove in PathMoves do
    begin
      jsnPathMove := TJSONObject.Create;
      jsnPathMove.AddPair(cKeySource, PathMove.Source);
      jsnPathMove.AddPair(cKeyDestination, PathMove.Destination);

      jsnPathMoves.Add(jsnPathMove);
    end;

    Result.AddPair(cKeyPathMoves, jsnPathMoves);
  end;
end;

procedure TInitialPackage.Init;
begin
  inherited;

  FFilterListType := fltBlack;

  FFilterList := [
    '.gitignore',
    'README.md'
  ];
end;

{ TPackageList }

{function TPackageList.GetByID(const aID: string): TPackage;
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

procedure TPackageList.RemoveByID(const aID: string);
var
  Package: TPackage;
begin
  Package := GetByID(aID);

  if Package <> nil then
    Remove(Package);
end; }

{ TPrivatePackageList }

constructor TPrivatePackageList.Create(const aPrivatePackageFiles: TArray<TPrivatePackageFile>);
var
  Package: TPrivatePackage;
  PrivatePackageFile: TPrivatePackageFile;
begin
  inherited Create(True);

  for PrivatePackageFile in aPrivatePackageFiles do
  begin
    Package := TPrivatePackage.Create(PrivatePackageFile.JSONString);
    Package.FilePath := PrivatePackageFile.Path;
    Add(Package);
  end;
end;

function TPrivatePackageList.GetByID(const aID: string): TPrivatePackage;
var
  Package: TPrivatePackage;
begin
  Result := nil;

  for Package in Self do
    if Package.ID = aID then
      Exit(Package);
end;

function TPrivatePackageList.GetByName(const aPackageName: string): TPrivatePackage;
var
  Package: TPrivatePackage;
begin
  Result := nil;

  for Package in Self do
    if Package.Name = aPackageName then
      Exit(Package);
end;

{ TDependentPackageList }

constructor TDependentPackageList.Create(const aJSONString: string);
var
  jsnArr: TJSONArray;
  jsnVal: TJSONValue;
  Package: TDependentPackage;
begin
  inherited Create(True);

  jsnArr := TJSONObject.ParseJSONValue(aJSONString) as TJSONArray;
  try
    for jsnVal in jsnArr do
    begin
      Package := TDependentPackage.Create(jsnVal.ToJSON);
      Add(Package);
    end;
  finally
    jsnArr.Free;
  end;
end;

function TDependentPackageList.GetByID(const aID: string): TDependentPackage;
var
  Package: TDependentPackage;
begin
  Result := nil;

  for Package in Self do
    if Package.ID = aID then
      Exit(Package);
end;

function TDependentPackageList.GetJSONString: string;
var
  jsnArr: TJSONArray;
  Package: TDependentPackage;
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

constructor TDependentPackageList.Create;
begin
  inherited Create(True);
end;

{ TDependentPackage }

constructor TDependentPackage.Create(aInitialPackage: TInitialPackage);
begin
  inherited Create;

  Assign(aInitialPackage);
  aInitialPackage.DependentPackage := Self;
end;

procedure TDependentPackage.SetJSON(aJSONObj: TJSONObject);
var
  jsnVersion: TJSONObject;
begin
  inherited;

  jsnVersion := aJSONObj.GetValue(cKeyVersion) as TJSONObject;
  Version := TVersion.Create(jsnVersion);
end;

function TDependentPackage.GetJSON: TJSONObject;
begin
  Result := inherited GetJSON;

  Result.AddPair(cKeyVersion, Version.GetJSON);
end;

end.
