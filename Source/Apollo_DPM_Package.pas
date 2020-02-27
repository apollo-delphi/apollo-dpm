unit Apollo_DPM_Package;

interface

uses
  System.Generics.Collections,
  System.JSON;

type
  TVersion = record
  private
    function GetDispalayName: string;
  public
    InstallTime: TDateTime;
    Name: string;
    SHA: string;
    function IsEmpty: Boolean;
    procedure Init;
    property DisplayName: string read GetDispalayName;
  end;

  TMove = record
  public
    Destination: string;
    Source: string;
  end;

  TFilterType = (ftNone, ftWhiteList, ftBlackList);

  TPackageType = (ptSource, ptTemplate);

  TPackage = class
  private
    FDescription: string;
    FFilters: TArray<string>;
    FFilterType: TFilterType;
    FInstallHistory: TArray<TVersion>;
    FInstalledVersion: TVersion;
    FMoves: TArray<TMove>;
    FName: string;
    FOwner: string;
    FPackageType: TPackageType;
    FRepo: string;
    FVersions: TArray<TVersion>;
    function CheckBlackList(const aPath: string): Boolean;
    function CheckWhiteList(const aPath: string): Boolean;
    function GetVersion(const aName: string): TVersion;
    function GetVersions: TArray<TVersion>;
    procedure Init;
  public
    function AllowPath(const aPath: string): Boolean;
    function ApplyMoves(const aNodePath: string): string;
    function CreateJSON: TJSONObject;
    procedure Assign(aPackage: TPackage);
    constructor Create(aJSONPackage: TJSONObject); overload;
    constructor Create(aPackage: TPackage); overload;
    property Description: string read FDescription write FDescription;
    property Filters: TArray<string> read FFilters write FFilters;
    property FilterType: TFilterType read FFilterType write FFilterType;
    property InstallHistory: TArray<TVersion> read FInstallHistory;
    property InstalledVersion: TVersion read FInstalledVersion write FInstalledVersion;
    property Moves: TArray<TMove> read FMoves write FMoves;
    property Name: string read FName write FName;
    property Owner: string read FOwner write FOwner;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property Repo: string read FRepo write FRepo;
    property Version[const aName: string]: TVersion read GetVersion;
    property Versions: TArray<TVersion> read GetVersions write FVersions;
  end;

  TPackageList = class(TObjectList<TPackage>)
  private
    function GetByName(const aPackageName: string): TPackage;
  public
    function ContainsWithName(const aPackageName: string): Boolean;
    procedure RemoveWithName(const aPackageName: string);
  end;

implementation

uses
  System.SysUtils;

{ TPackage }

function TPackage.ApplyMoves(const aNodePath: string): string;
var
  Move: TMove;
begin
  Result := aNodePath;

  for Move in Moves do
    Result := Result.Replace(Move.Source, Move.Destination);

  Result := Result.Replace('\\', '\', [rfReplaceAll]);
end;

procedure TPackage.Assign(aPackage: TPackage);
begin
  Description := aPackage.Description;
  Name := aPackage.Name;
  Owner := aPackage.Owner;
  Repo := aPackage.Repo;
  PackageType := aPackage.PackageType;

  InstalledVersion := aPackage.InstalledVersion;
end;

constructor TPackage.Create(aJSONPackage: TJSONObject);
var
  FilterType: Integer;
  iPackageType: Integer;
  jsnFilter: TJSONValue;
  jsnFilters: TJSONArray;
  jsnInstalled: TJSONObject;
  jsnMove: TJSONValue;
  jsnMoves: TJSONArray;
  Move: TMove;
begin
  Init;

  if aJSONPackage <> nil then
    begin
      Description := aJSONPackage.GetValue('description').Value;
      Name := aJSONPackage.GetValue('name').Value;
      Owner := aJSONPackage.GetValue('owner').Value;
      Repo := aJSONPackage.GetValue('repo').Value;

      if aJSONPackage.TryGetValue<Integer>('packageType', iPackageType) then
        PackageType := TPackageType(iPackageType);

      if aJSONPackage.TryGetValue<Integer>('filterType', FilterType) then
        FFilterType := TFilterType(FilterType)
      else
        FFilterType := ftNone;

      if aJSONPackage.TryGetValue('filters', jsnFilters) then
        for jsnFilter in jsnFilters do
          FFilters := FFilters + [jsnFilter.Value];

      if aJSONPackage.TryGetValue('moves', jsnMoves) then
        for jsnMove in jsnMoves do
          begin
            Move.Source := (jsnMove as TJSONObject).GetValue('source').Value;
            Move.Destination := (jsnMove as TJSONObject).GetValue('destination').Value;
            FMoves := FMoves + [Move];
          end;

      if aJSONPackage.TryGetValue('installed', jsnInstalled) then
        begin
          FInstalledVersion.Name :=  jsnInstalled.GetValue('name').Value;
          FInstalledVersion.SHA :=  jsnInstalled.GetValue('sha').Value;
        end;
    end;
end;

function TPackage.CheckBlackList(const aPath: string): Boolean;
var
  Filter: string;
begin
  Result := True;

  for Filter in Filters do
    if aPath.StartsWith(Filter) then
      Exit(False);
end;

function TPackage.CheckWhiteList(const aPath: string): Boolean;
var
  Filter: string;
begin
  Result := False;

  for Filter in Filters do
    if aPath.StartsWith(Filter) then
      Exit(True);
end;

constructor TPackage.Create(aPackage: TPackage);
begin
  Init;

  Assign(aPackage);
end;

function TPackage.CreateJSON: TJSONObject;
var
  jsnFilters: TJSONArray;
  jsnInstalledVersion: TJSONObject;
  jsnMove: TJSONObject;
  jsnMoves: TJSONArray;
  Move: TMove;
  sFilter: string;
begin
  Result := TJSONObject.Create;

  Result.AddPair('description', Description);
  Result.AddPair('name', Name);
  Result.AddPair('owner', Owner);
  Result.AddPair('repo', Repo);
  Result.AddPair('packageType', TJSONNumber.Create(Ord(PackageType)));

  if FilterType <> ftNone then
    begin
      Result.AddPair('filterType', TJSONNumber.Create(Ord(FilterType)));

      jsnFilters := TJSONArray.Create;
      for sFilter in Filters do
        jsnFilters.Add(sFilter);

      Result.AddPair('filters', jsnFilters);
    end;

  if Length(Moves) > 0 then
    begin
      jsnMoves := TJSONArray.Create;
      for Move in Moves do
        begin
          jsnMove := TJSONObject.Create;
          jsnMove.AddPair('source', Move.Source);
          jsnMove.AddPair('destination', Move.Destination);

          jsnMoves.AddElement(jsnMove);
        end;
      Result.AddPair('moves', jsnMoves);
    end;

  if not InstalledVersion.Name.IsEmpty then
    begin
      jsnInstalledVersion := TJSONObject.Create;
      jsnInstalledVersion.AddPair('name', InstalledVersion.Name);
      jsnInstalledVersion.AddPair('sha', InstalledVersion.SHA);
      jsnInstalledVersion.AddPair('time', TJSONNumber.Create(InstalledVersion.InstallTime));

      Result.AddPair('installed', jsnInstalledVersion);
    end;
end;

function TPackage.GetVersion(const aName: string): TVersion;
var
  Version: TVersion;
begin
  Result.Init;

  for Version in Versions do
    if Version.Name = aName then
      Exit(Version);
end;

function TPackage.GetVersions: TArray<TVersion>;
begin
  Result := [];

  if not InstalledVersion.IsEmpty then
    Result := Result + [InstalledVersion];
end;

procedure TPackage.Init;
begin
  FVersions := [];
  FInstallHistory := [];
  FMoves := [];
  FFilters := [];
  FFilterType := ftNone;
  FPackageType := ptSource;

  FDescription := '';
  FName := '';
  FOwner := '';
  FRepo := '';

  FInstalledVersion.Init;
end;

function TPackage.AllowPath(const aPath: string): Boolean;
begin
  Result := True;

  case FilterType of
    ftWhiteList: Result := CheckWhiteList(aPath);
    ftBlackList: Result := CheckBlackList(aPath);
  end;
end;

{ TVersion }

function TVersion.GetDispalayName: string;
begin
  Result := '';

  if not Name.IsEmpty then
    Result := Name
  else
  if not SHA.IsEmpty then
    Result := Format('commit %s', [SHA.Substring(0, 7)]);
end;

procedure TVersion.Init;
begin
  Name := '';
  SHA := '';
  InstallTime := 0;
end;

function TVersion.IsEmpty: Boolean;
begin
  Result := Name.IsEmpty and SHA.IsEmpty;
end;

{ TPackageList }

function TPackageList.ContainsWithName(const aPackageName: string): Boolean;
begin
  if GetByName(aPackageName) <> nil then
    Result := True
  else
    Result := False;
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

procedure TPackageList.RemoveWithName(const aPackageName: string);
var
  Package: TPackage;
begin
  Package := GetByName(aPackageName);
  if Assigned(Package) then
    Remove(Package);
end;

end.
