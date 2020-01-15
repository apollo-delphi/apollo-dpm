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

  TRemove = record
  public
    Destination: string;
    Source: string;
  end;

  TPackage = class
  private
    FDescription: string;
    FIgnores: TArray<string>;
    FInstalledVersion: TVersion;
    FName: string;
    FOwner: string;
    FRemoves: TArray<TRemove>;
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
    property Ignores: TArray<string> read FIgnores;
    property InstalledVersion: TVersion read FInstalledVersion write FInstalledVersion;
    property Name: string read FName write FName;
    property Owner: string read FOwner write FOwner;
    property Removes: TArray<TRemove> read FRemoves;
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
  jsnIgnore: TJSONValue;
  jsnIgnores: TJSONArray;
  jsnInstalled: TJSONObject;
  jsnRemoves: TJSONArray;
  jsnRemove: TJSONValue;
  Remove: TRemove;
begin
  Init;

  if aJSONPackage <> nil then
    begin
      if aJSONPackage.GetValue('repo') = nil then
        Exit;

      Description := aJSONPackage.GetValue('description').Value;
      Name := aJSONPackage.GetValue('name').Value;
      Owner := aJSONPackage.GetValue('owner').Value;
      Repo := aJSONPackage.GetValue('repo').Value;

      if aJSONPackage.TryGetValue('ignores', jsnIgnores) then
        for jsnIgnore in jsnIgnores do
          FIgnores := FIgnores + [jsnIgnore.Value];

      if aJSONPackage.TryGetValue('removes', jsnRemoves) then
        for jsnRemove in jsnRemoves do
          begin
            Remove.Source := (jsnRemove as TJSONObject).GetValue('source').Value;
            Remove.Destination := (jsnRemove as TJSONObject).GetValue('destination').Value;
            FRemoves := FRemoves + [Remove];
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
  jsnInstalledVersion: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('description', Description);
  Result.AddPair('name', Name);
  Result.AddPair('owner', Owner);
  Result.AddPair('repo', Repo);

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
  FRemoves := [];
  FIgnores := [];
  FInstalledVersion.Init;
end;

function TPackage.IsIgnorePath(const aPath: string): Boolean;
var
  IgnorePath: string;
begin
  Result := False;

  for IgnorePath in FIgnores do
    if IgnorePath = aPath then
      Exit(True);
end;

{ TVersion }

procedure TVersion.Init;
begin
  Name := '';
  SHA := '';
end;

end.
