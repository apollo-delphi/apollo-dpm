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
    RemoveTime: TDateTime;
    SHA: string;
    function CreateJSON(const aIsRemoved: Boolean): TJSONObject;
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
    FHistory: TArray<TVersion>;
    FInstalledVersion: TVersion;
    FMoves: TArray<TMove>;
    FName: string;
    FOwner: string;
    FPackageType: TPackageType;
    FRepo: string;
    FVersions: TArray<TVersion>;
    function CheckBlackList(const aPath: string): Boolean;
    function CheckWhiteList(const aPath: string): Boolean;
    procedure Init;
    procedure SetInstalledVersion(aVersion: TVersion);
  public
    function AllowPath(const aPath: string): Boolean;
    function ApplyMoves(const aNodePath: string): string;
    function CreateJSON: TJSONObject;
    function VersionsContain(const aVersion: TVersion): Boolean;
    procedure AddToHistory(const aVersion: TVersion);
    procedure Assign(aPackage: TPackage);
    procedure DeleteFromHistory(const aVersion: TVersion);
    constructor Create(aJSONPackage: TJSONObject); overload;
    constructor Create(aPackage: TPackage); overload;
    property Description: string read FDescription write FDescription;
    property Filters: TArray<string> read FFilters write FFilters;
    property FilterType: TFilterType read FFilterType write FFilterType;
    property History: TArray<TVersion> read FHistory;
    property InstalledVersion: TVersion read FInstalledVersion write SetInstalledVersion;
    property Moves: TArray<TMove> read FMoves write FMoves;
    property Name: string read FName write FName;
    property Owner: string read FOwner write FOwner;
    property PackageType: TPackageType read FPackageType write FPackageType;
    property Repo: string read FRepo write FRepo;
    property Versions: TArray<TVersion> read FVersions write FVersions;
  end;

  TPackageList = class(TObjectList<TPackage>)
  private
    function GetByName(const aPackageName: string): TPackage;
  public
    procedure SyncToSidePackage(aSidePackage: TPackage);
    procedure SyncFromSidePackage(aSidePackage: TPackage);
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

  FilterType := aPackage.FilterType;
  Filters := aPackage.Filters;
  Moves := aPackage.Moves;
end;

constructor TPackage.Create(aJSONPackage: TJSONObject);
var
  FilterType: Integer;
  iPackageType: Integer;
  jsnFilter: TJSONValue;
  jsnFilters: TJSONArray;
  jsnHistory: TJSONArray;
  jsnHistoryItem: TJSONValue;
  jsnHistoryVersion: TJSONObject;
  jsnInstalled: TJSONObject;
  jsnMove: TJSONValue;
  jsnMoves: TJSONArray;
  Move: TMove;
  Version: TVersion;
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
          FInstalledVersion.InstallTime := (jsnInstalled.GetValue('time') as TJSONNumber).AsDouble;
        end;

      if aJSONPackage.TryGetValue('history', jsnHistory) then
        begin
          for jsnHistoryItem in jsnHistory do
            begin
              jsnHistoryVersion := jsnHistoryItem as TJSONObject;

              Version.Init;
              Version.Name := jsnHistoryVersion.GetValue('name').Value;
              Version.SHA := jsnHistoryVersion.GetValue('sha').Value;
              Version.RemoveTime := (jsnHistoryVersion.GetValue('time') as TJSONNumber).AsDouble;

              AddToHistory(Version);
            end;
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
  jsnInstallHistory: TJSONArray;
  jsnMove: TJSONObject;
  jsnMoves: TJSONArray;
  jsnVersion: TJSONObject;
  Move: TMove;
  sFilter: string;
  Version: TVersion;
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

  if not InstalledVersion.IsEmpty then
    begin
      jsnVersion := InstalledVersion.CreateJSON(False);

      Result.AddPair('installed', jsnVersion);
    end;

  if Length(History) > 0 then
    begin
      jsnInstallHistory := TJSONArray.Create;
      for Version in History do
        begin
          jsnVersion := Version.CreateJSON(True);
          jsnInstallHistory.AddElement(jsnVersion);
        end;
      Result.AddPair('history', jsnInstallHistory);
    end;
end;

procedure TPackage.DeleteFromHistory(const aVersion: TVersion);
var
  i: Integer;
begin
  for i := 0 to Length(FHistory) - 1 do
    if FHistory[i].SHA = aVersion.SHA then
      begin
        Delete(FHistory, i, 1);
        Break;
      end;
  for i := 0 to Length(FVersions) - 1 do
    if FVersions[i].SHA = aVersion.SHA then
      begin
        Delete(FVersions, i, 1);
        Break;
      end;
end;

procedure TPackage.Init;
begin
  FVersions := [];
  FHistory := [];
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

procedure TPackage.SetInstalledVersion(aVersion: TVersion);
begin
  if not aVersion.IsEmpty then
    begin
      FInstalledVersion := aVersion;
      FVersions := FVersions + [InstalledVersion];
    end;
end;

function TPackage.VersionsContain(const aVersion: TVersion): Boolean;
var
  Version: TVersion;
begin
  Result := False;

  for Version in Versions do
    if Version.SHA = aVersion.SHA then
      Exit(True);
end;

procedure TPackage.AddToHistory(const aVersion: TVersion);
begin
  FHistory := FHistory + [aVersion];
  FVersions := FVersions + [aVersion];
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

function TVersion.CreateJSON(const aIsRemoved: Boolean): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('name', Name);
  Result.AddPair('sha', SHA);

  if aIsRemoved then
    Result.AddPair('time', TJSONNumber.Create(RemoveTime))
  else
    Result.AddPair('time', TJSONNumber.Create(InstallTime));
end;

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
  RemoveTime := 0;
end;

function TVersion.IsEmpty: Boolean;
begin
  Result := Name.IsEmpty and SHA.IsEmpty;
end;

{ TPackageList }

function TPackageList.GetByName(const aPackageName: string): TPackage;
var
  Package: TPackage;
begin
  Result := nil;

  for Package in Self do
    if Package.Name = aPackageName then
      Exit(Package);
end;

procedure TPackageList.SyncFromSidePackage(aSidePackage: TPackage);
var
  aPackage: TPackage;
begin
  aPackage := GetByName(aSidePackage.Name);
  if not Assigned(aPackage) then
    begin
      aPackage := TPackage.Create(aSidePackage);
      Add(aPackage);
    end;

  aPackage.FInstalledVersion := aSidePackage.FInstalledVersion;
  aPackage.FHistory := aSidePackage.FHistory;
end;

procedure TPackageList.SyncToSidePackage(aSidePackage: TPackage);
var
  aPackage: TPackage;
  aVersion: TVersion;
begin
  for aPackage in Self do
    if aPackage.Name = aSidePackage.Name then
      begin
        for aVersion in aPackage.History do
          aSidePackage.AddToHistory(aVersion);

        aSidePackage.InstalledVersion := aPackage.InstalledVersion;
      end;
end;

end.
