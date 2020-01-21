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
    procedure Init;
  end;

  TMove = record
  public
    Destination: string;
    Source: string;
  end;

  TFilterType = (ftNone, ftWhiteList, ftBlackList);

  TPackage = class
  private
    FDescription: string;
    FFileName: string;
    FFilters: TArray<string>;
    FFilterType: TFilterType;
    FInstalledVersion: TVersion;
    FMoves: TArray<TMove>;
    FName: string;
    FOwner: string;
    FRepo: string;
    FVersions: TArray<TVersion>;
    function GetVersion(const aName: string): TVersion;
    procedure Init;
  public
    function CreateJSON: TJSONObject;
    function IsIgnorePath(const aPath: string): Boolean;
    procedure Assign(aPackage: TPackage);
    constructor Create(aJSONPackage: TJSONObject); overload;
    constructor Create(aPackage: TPackage); overload;
    property Description: string read FDescription write FDescription;
    property FileName: string read FFileName write FFileName;
    property Filters: TArray<string> read FFilters write FFilters;
    property FilterType: TFilterType read FFilterType write FFilterType;
    property InstalledVersion: TVersion read FInstalledVersion write FInstalledVersion;
    property Moves: TArray<TMove> read FMoves write FMoves;
    property Name: string read FName write FName;
    property Owner: string read FOwner write FOwner;
    property Repo: string read FRepo write FRepo;
    property Version[const aName: string]: TVersion read GetVersion;
    property Versions: TArray<TVersion> read FVersions write FVersions;
  end;

  TPackageList = TObjectList<TPackage>;

implementation

uses
  System.SysUtils;

{ TPackage }

procedure TPackage.Assign(aPackage: TPackage);
begin
  Description := aPackage.Description;
  Name := aPackage.Name;
  Owner := aPackage.Owner;
  Repo := aPackage.Repo;
end;

constructor TPackage.Create(aJSONPackage: TJSONObject);
var
  FilterType: Integer;
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

  if not FileName.IsEmpty then
    Result.AddPair('fileName', FileName);

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

procedure TPackage.Init;
begin
  FVersions := [];
  FMoves := [];
  FFilters := [];
  FFilterType := ftNone;

  FDescription := '';
  FFileName := '';
  FName := '';
  FOwner := '';
  FRepo := '';

  FInstalledVersion.Init;
end;

function TPackage.IsIgnorePath(const aPath: string): Boolean;
{var
  IgnorePath: string;}
begin
  {Result := False;

  for IgnorePath in FIgnores do
    if IgnorePath = aPath then
      Exit(True);   }
end;

{ TVersion }

procedure TVersion.Init;
begin
  Name := '';
  SHA := '';
end;

end.
