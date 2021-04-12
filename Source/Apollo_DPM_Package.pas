unit Apollo_DPM_Package;

interface

uses
  Apollo_DPM_Version,
  System.Generics.Collections,
  System.JSON;

type
  TVisibility = (vPrivate, vPublic);

  TPackageType = (ptCodeSource, ptBplSource, ptBplBinary, ptProjectTemplate);

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
    procedure AddStringArrToJSON(aJSONObj: TJSONObject; aStrArr: TArray<string>; const aKey: string);
    procedure Init; virtual;
    procedure SetJSON(aJSONObj: TJSONObject); virtual;
  public
    function GetJSONString: string;
    function SearchMatched(const aSearch: string): Boolean;
    procedure Assign(aPackage: TPackage); virtual;
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

  TPackageClass = class of TPackage;

  TPathMove = record
    Destination: string;
    Source: string;
  end;

  TFilterListType = (fltNone, fltBlack, fltWhite);
  TAddingUnitsOption = (auAll, auSpecified, auNothing);

  TDependentPackage = class;

  TInitialPackage = class(TPackage)
  private
    FAddingUnitRefs: TArray<string>;
    FAddingUnitsOption: TAddingUnitsOption;
    FAddSearchPath: Boolean;
    FBinaryFileRefs: TArray<string>;
    FDependentPackage: TDependentPackage;
    FFilterList: TArray<string>;
    FFilterListType: TFilterListType;
    FPathMoves: TArray<TPathMove>;
    FProjectFileRefs: TArray<string>;
    function AllowByBlackList(const aPath: string): Boolean;
    function AllowByWhiteList(const aPath: string): Boolean;
  protected
    function GetJSON: TJSONObject; override;
    procedure Init; override;
    procedure SetJSON(aJSONObj: TJSONObject); override;
  public
    function AllowPath(const aPath: string): Boolean;
    function ApplyPathMoves(const aPath: string): string;
    function IsInstalled: Boolean;
    constructor Create; overload;
    property AddingUnitRefs: TArray<string> read FAddingUnitRefs write FAddingUnitRefs;
    property AddingUnitsOption: TAddingUnitsOption read FAddingUnitsOption write FAddingUnitsOption;
    property AddSearchPath: Boolean read FAddSearchPath write FAddSearchPath;
    property BinaryFileRefs: TArray<string> read FBinaryFileRefs write FBinaryFileRefs;
    property DependentPackage: TDependentPackage read FDependentPackage write FDependentPackage;
    property FilterList: TArray<string> read FFilterList write FFilterList;
    property FilterListType: TFilterListType read FFilterListType write FFilterListType;
    property PathMoves: TArray<TPathMove> read FPathMoves write FPathMoves;
    property ProjectFileRefs: TArray<string> read FProjectFileRefs write FProjectFileRefs;
  end;

  TDependentPackage = class(TPackage)
  private
    FBplFileRefs: TArray<string>;
    FIsDirect: Boolean;
    FVersion: TVersion;
  protected
    function GetJSON: TJSONObject; override;
    procedure SetJSON(aJSONObj: TJSONObject); override;
  public
    constructor Create(const aJSONString: string;
      aVersionCacheSyncFunc: TVersionCacheSyncFunc); reintroduce;
    constructor CreateByInitial(aInitialPackage: TInitialPackage;
     const aOwnes: Boolean = True);
    property BplFileRefs: TArray<string> read FBplFileRefs write FBplFileRefs;
    property IsDirect: Boolean read FIsDirect write FIsDirect;
    property Version: TVersion read FVersion write FVersion;
  end;

  TDependentPackageList = class(TObjectList<TDependentPackage>)
  public
    function GetByID(const aID: string): TDependentPackage;
    function GetDirectPackages: TArray<TDependentPackage>;
    function GetJSONString: string;
    function IsUsingDependenceExceptOwner(const aID, aOwnerID: string): Boolean;
    procedure RemoveByID(const aID: string);
    constructor Create; overload;
    constructor Create(const aJSONString: string;
      aVersionCacheSyncFunc: TVersionCacheSyncFunc); overload;
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
    procedure SetDependentPackageRef(aDependentPackageList: TDependentPackageList);
    constructor Create(const aPrivatePackageFiles: TArray<TPrivatePackageFile>); reintroduce;
  end;

implementation

uses
  Apollo_DPM_Consts,
  System.Hash,
  System.SysUtils;

{ TPackage }

function TPackage.SearchMatched(const aSearch: string): Boolean;
begin
  if aSearch.IsEmpty then
    Exit(True);

  if Name.ToUpper.Contains(aSearch.ToUpper) then
    Result := True
  else
    Result := False;
end;

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

procedure TPackage.AddStringArrToJSON(aJSONObj: TJSONObject;
  aStrArr: TArray<string>; const aKey: string);
var
  jsnArr: TJSONArray;
  Value: string;
begin
  jsnArr := TJSONArray.Create;
  for Value in aStrArr do
    jsnArr.Add(Value);
  aJSONObj.AddPair(aKey, jsnArr)
end;

procedure TPackage.Assign(aPackage: TPackage);
begin
  ID := aPackage.ID;
  Name := aPackage.Name;
  Description := aPackage.Description;
  RepoOwner := aPackage.RepoOwner;
  RepoName := aPackage.RepoName;
  PackageType := aPackage.PackageType;
end;

function TPackage.GetID: string;
begin
  if FID.IsEmpty then
    FID := THashMD5.GetHashString(FRepoOwner + FRepoName).ToUpper;

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
  FilterItem: string;
begin
  Result := False;

  for FilterItem in FFilterList do
    if aPath.StartsWith(FilterItem) then
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

constructor TInitialPackage.Create;
begin
  Init;
end;

procedure TInitialPackage.SetJSON(aJSONObj: TJSONObject);
var
  bValue: Boolean;
  iValue: Integer;
  jsnAddingUnitRefs: TJSONArray;
  jsnPkgFileRefs: TJSONArray;
  jsnPrjFileRefs: TJSONArray;
  jsnFilterList: TJSONArray;
  jsnPathMoves: TJSONArray;
  jsnVal: TJSONValue;
  PathMove: TPathMove;
begin
  inherited;

  if aJSONObj.TryGetValue<Integer>(cKeyFilterListType, iValue) then
    FilterListType := TFilterListType(iValue);

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

  if aJSONObj.TryGetValue(cKeyProjectFileRefs, jsnPrjFileRefs) then
    for jsnVal in jsnPrjFileRefs do
      ProjectFileRefs := ProjectFileRefs + [jsnVal.Value];

  if aJSONObj.TryGetValue(cKeyBinaryFileRefs, jsnPkgFileRefs) then
    for jsnVal in jsnPkgFileRefs do
      BinaryFileRefs := BinaryFileRefs + [jsnVal.Value];

  if aJSONObj.TryGetValue<Integer>(cKeyAddingUnitsOption, iValue) then
    AddingUnitsOption := TAddingUnitsOption(iValue);

  if aJSONObj.TryGetValue<Boolean>(cKeyAddSearchPath, bValue) then
    AddSearchPath := bValue;

  if aJSONObj.TryGetValue(cKeyAddingUnitRefs, jsnAddingUnitRefs) then
    for jsnVal in jsnAddingUnitRefs do
      AddingUnitRefs := AddingUnitRefs + [jsnVal.Value];
end;

function TInitialPackage.GetJSON: TJSONObject;
var
  PathMove: TPathMove;
  jsnPathMove: TJSONObject;
  jsnPathMoves: TJSONArray;
begin
  Result := inherited GetJSON;

  Result.AddPair(cKeyFilterListType, TJSONNumber.Create(Ord(FilterListType)));

  if (FilterListType <> fltNone) and (Length(FilterList) > 0) then
    AddStringArrToJSON(Result, FilterList, cKeyFilterList)
  else
    FilterList := [];

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

  if (PackageType = ptBplSource) and (Length(ProjectFileRefs) > 0) then
    AddStringArrToJSON(Result, ProjectFileRefs, cKeyProjectFileRefs)
  else
    ProjectFileRefs := [];

  if (PackageType = ptBplSource) and (Length(BinaryFileRefs) > 0) then
    AddStringArrToJSON(Result, BinaryFileRefs, cKeyBinaryFileRefs)
  else
    BinaryFileRefs := [];

  if PackageType = ptCodeSource then
  begin
    Result.AddPair(cKeyAddingUnitsOption, TJSONNumber.Create(Ord(AddingUnitsOption)));
    Result.AddPair(cKeyAddSearchPath, TJSONBool.Create(AddSearchPath));

    if AddingUnitsOption = auSpecified then
    begin
      if Length(AddingUnitRefs) > 0 then
        AddStringArrToJSON(Result, AddingUnitRefs, cKeyAddingUnitRefs)
    end
    else
      AddingUnitRefs := [];
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
  FPathMoves := [];
  FAddingUnitsOption := auNothing;
  FAddSearchPath := True;
end;

function TInitialPackage.IsInstalled: Boolean;
begin
  Result := Assigned(DependentPackage);
end;

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

procedure TPrivatePackageList.SetDependentPackageRef(
  aDependentPackageList: TDependentPackageList);
var
  DependentPackage: TDependentPackage;
  PrivatePackage: TPrivatePackage;
begin
  for PrivatePackage in Self do
  begin
    DependentPackage := aDependentPackageList.GetByID(PrivatePackage.ID);
    if Assigned(DependentPackage) and not Assigned(PrivatePackage.DependentPackage) then
      PrivatePackage.DependentPackage := DependentPackage;
  end;
end;

{ TDependentPackageList }

constructor TDependentPackageList.Create(const aJSONString: string;
  aVersionCacheSyncFunc: TVersionCacheSyncFunc);
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
      Package := TDependentPackage.Create(jsnVal.ToJSON, aVersionCacheSyncFunc);
      Add(Package);
    end;
  finally
    jsnArr.Free;
  end;
end;

function TDependentPackageList.IsUsingDependenceExceptOwner(const aID, aOwnerID: string): Boolean;
var
  Package: TDependentPackage;
begin
  Result := False;

  for Package in Self do
    if (Package.ID <> aOwnerID) and Package.IsDirect and Package.Version.ContainsDependency(aID) then
      Exit(True);
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

function TDependentPackageList.GetDirectPackages: TArray<TDependentPackage>;
var
 Package: TDependentPackage;
begin
  Result := [];

  for Package in Self do
    if Package.IsDirect then
      Result := Result + [Package];
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

procedure TDependentPackageList.RemoveByID(const aID: string);
var
  Package: TDependentPackage;
begin
  Package := GetByID(aID);

  if Package <> nil then
    Remove(Package);
end;

constructor TDependentPackageList.Create;
begin
  inherited Create(True);
end;

{ TDependentPackage }

constructor TDependentPackage.CreateByInitial(aInitialPackage: TInitialPackage;
  const aOwnes: Boolean = True);
begin
  inherited Create;

  Assign(aInitialPackage);
  if aOwnes then
    aInitialPackage.DependentPackage := Self;
end;

procedure TDependentPackage.SetJSON(aJSONObj: TJSONObject);
var
  bVal: Boolean;
  jsnArr: TJSONArray;
  jsnVal: TJSONValue;
  jsnVersion: TJSONObject;
begin
  inherited;

  jsnVersion := aJSONObj.GetValue(cKeyVersion) as TJSONObject;
  Version := TVersion.Create(jsnVersion);

  if aJSONObj.TryGetValue(cKeyBplFileRef, jsnArr) then
    for jsnVal in jsnArr do
      BplFileRefs := BplFileRefs + [jsnVal.Value];

  if aJSONObj.TryGetValue<Boolean>(cKeyIsDirect, bVal) then
    FIsDirect := bVal;
end;

constructor TDependentPackage.Create(const aJSONString: string;
  aVersionCacheSyncFunc: TVersionCacheSyncFunc);
begin
  inherited Create(aJSONString);
  Version := aVersionCacheSyncFunc(ID, Version);
end;

function TDependentPackage.GetJSON: TJSONObject;
begin
  Result := inherited GetJSON;

  Result.AddPair(cKeyVersion, Version.GetJSON);

  if Length(BplFileRefs) > 0 then
    AddStringArrToJSON(Result, BplFileRefs, cKeyBplFileRef);

  Result.AddPair(cKeyIsDirect, TJSONBool.Create(FIsDirect));
end;

end.
