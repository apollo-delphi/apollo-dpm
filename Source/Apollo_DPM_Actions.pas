unit Apollo_DPM_Actions;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  Xml.XMLIntf;

type
  TDPMAction = class abstract
  protected
    FDPMEngine: TDPMEngine;
    FTestMode: Boolean;
  public
    property TestMode: Boolean read FTestMode write FTestMode;
  end;

  TUninstall = class;
  TUninstallClass = class of TUninstall;

  TUninstall = class abstract(TDPMAction)
  private
    FDependentPackage: TDependentPackage;
    procedure DeletePackagePath(aPackage: TPackage);
  protected
    procedure DoUninstall(aDependentPackage: TDependentPackage); virtual;
    procedure RemovePackageFromLists(const aPackageID: string; aDependentPackage: TDependentPackage); virtual;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TDependentPackage;
      aVersion: TVersion): Boolean;
    class function GetClass(const aPackageType: TPackageType): TUninstallClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage);
  end;

  TUninstallCodeSource = class(TUninstall)
  private
    procedure RemoveUnitsFromProject(aDependentPackage: TDependentPackage);
  protected
    procedure DoUninstall(aDependentPackage: TDependentPackage); override;
  end;

  TUninstallBplSource = class(TUninstall)
  protected
    procedure DoUninstall(aDependentPackage: TDependentPackage); override;
    procedure RemovePackageFromLists(const aPackageID: string; aDependentPackage: TDependentPackage); override;
  end;

  TUninstallBplBinary = class(TUninstallBplSource)
  end;

  TInstall = class;
  TInstallClass = class of TInstall;

  TInstall = class(TDPMAction)
  strict private
    FDependentPackage: TDependentPackage;
    procedure AddPackageFiles(aPackage: TDependentPackage);
    procedure SaveContent(aPackage: TPackage; const aRelativeFilePath, aContent: string);
  protected
    function GetContentPath(aPackage: TPackage): string; virtual;
    procedure DoInstall(aPackage: TDependentPackage);
  public
    class function Allowed(aPackage: TDependentPackage): Boolean;
    class function GetClass(const aPackageType: TPackageType): TInstallClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage);
  end;

  TAdd = class;
  TAddClass = class of TAdd;

  TAdd = class abstract(TInstall)
  strict private
    FVersion: TVersion;
    procedure DefineRoutes(aDependentPackage: TDependentPackage; aInitialPackage: TInitialPackage; aVersion: TVersion);
  private
    FInitialPackage: TInitialPackage;
  protected
    function DoAdd(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage; virtual;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; virtual;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion; const aIsDirect: Boolean = False): TPackageHandle;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles; virtual;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); virtual;
    procedure SavePackages; virtual;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; virtual;
    class function GetClass(const aPackageType: TPackageType): TAddClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage; aVersion: TVersion);
  end;

  TAddCodeSource = class(TAdd)
  private
    function ProcessRequiredDependencies(const aCaption: string;
      aRequiredDependencies: TDependentPackageList): TPackageHandles;
    procedure AddUnitsToProject(aInitialPackage: TInitialPackage);
  protected
    function DoAdd(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage; override;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; override;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); override;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; override;
  end;

  TInstallBplCustomFunc = reference to function(const aFilePath: string): string;

  TAddBplCommon = class(TAdd)
  protected
    procedure DoBplInstall(aInitialPackage: TInitialPackage;
      aDependentPackage: TDependentPackage; const aFileRefs: TArray<string>;
      aCustomFunc: TInstallBplCustomFunc);
  end;

  TAddBplSource = class(TAddBplCommon)
  private
    function FindXmlNode(aNode: IXMLNode; const aNodeName: string): IXMLNode;
    function MakeBPL(const aProjectFilePath: string): string;
  protected
    function DoAdd(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage; override;
  end;

  TAddBplBinary = class(TAddBplCommon)
  protected
    function DoAdd(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage; override;
  end;

  TAddProjectTemplate = class(TAdd)
  private
    FProjectPath: string;
  protected
    function DoAdd(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage; override;
    function GetContentPath(aPackage: TPackage): string; override;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles; override;
    procedure SavePackages; override;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; override;
  end;

  TUpdate = class;
  TUpdateClass = class of TUpdate;

  TUpdate = class(TDPMAction)
  private
    FDependentPackage: TDependentPackage;
    FVersion: TVersion;
  protected
    function GetDependencyHandles(aInitialPackage: TInitialPackage): TPackageHandles; virtual;
    procedure ProcessInstallHandles(aPackageHandles: TPackageHandles); virtual; abstract;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); virtual; abstract;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TDependentPackage;
      aVersion: TVersion): Boolean; virtual;
    class function GetClass(const aPackageType: TPackageType): TUpdateClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage; aVersion: TVersion);
  end;

  TUpdateCodeSource = class(TUpdate)
  protected
    function GetDependencyHandles(aInitialPackage: TInitialPackage): TPackageHandles; override;
    procedure ProcessInstallHandles(aPackageHandles: TPackageHandles); override;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); override;
  end;

  TUpdateBplSource = class(TUpdate)
  protected
    procedure ProcessInstallHandles(aPackageHandles: TPackageHandles); override;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); override;
  end;

  TUpdateBplBinary = class(TUpdate)
  protected
    procedure ProcessInstallHandles(aPackageHandles: TPackageHandles); override;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_GitHubAPI,
  System.Classes,
  System.NetEncoding,
  System.SysUtils,
  System.TypInfo,
  Xml.XMLDoc;

{ TAdd }

function TAdd.DoAdd(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage;
begin
  Result := TDependentPackage.CreateByInitial(aInitialPackage);
  Result.Version := aVersion;
  Result.IsDirect := aIsDirect;

  DefineRoutes(Result, aInitialPackage, aVersion);
  DoInstall(Result);
end;

class function TAdd.Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
  aVersion: TVersion): Boolean;
begin
  Result :=
    Assigned(aVersion) and
    not aPackage.IsInstalled;
end;

constructor TAdd.Create(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion);
begin
  FDPMEngine := aDPMEngine;
  FInitialPackage := aPackage;
  FVersion := aVersion;
end;

class function TAdd.GetClass(const aPackageType: TPackageType): TAddClass;
begin
  case aPackageType of
    ptCodeSource: Result := TAddCodeSource;
    ptBplSource: Result := TAddBplSource;
    ptBplBinary: Result := TAddBplBinary;
    ptProjectTemplate: Result := TAddProjectTemplate;
  else
    raise Exception.CreateFmt('TAdd.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TAdd.GetDependencyHandles(aVersion: TVersion): TPackageHandles;
begin
  Result := [];
end;

function TAdd.GetInstallPackageHandle(aDependentPackage: TDependentPackage;
  aVersion: TVersion; const aIsDirect: Boolean = False): TPackageHandle;
var
  InitialPackage: TInitialPackage;
  NeedToFree: Boolean;
begin
  NeedToFree := False;

  InitialPackage := FDPMEngine.Package_FindInitial(aDependentPackage.ID);

  if not Assigned(InitialPackage) then
  begin
    InitialPackage := TInitialPackage.Create;
    InitialPackage.Assign(aDependentPackage);
    NeedToFree := True;
  end;
  Result := TPackageHandle.CreateInstallHandle(InitialPackage, aVersion, aIsDirect, NeedToFree);
end;

function TAdd.PostProcessPackageHandles(
  const aPackageHandles: TPackageHandles): TPackageHandles;
var
  i: Integer;
  PackageHandle: TPackageHandle;
begin
  Result := [];

  for i := High(aPackageHandles) downto 0 do
  begin
    PackageHandle := aPackageHandles[i];

    if PackageHandle.NeedToFree then
      PackageHandle.Package.Free;
    PackageHandle.Package := nil;

    if (PackageHandle.PackageAction = paUninstall) and
       aPackageHandles.ContainsInstallHandle(PackageHandle.PackageID)
    then
      //do nothing
    else
      Result := Result + [PackageHandle];
  end;
end;

procedure TAdd.ProcessUninstallHandles(aPackageHandles: TPackageHandles);
begin
end;

function TAdd.Run: TPackageHandles;
var
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  FDPMEngine.NotifyUI(Format(#13#10'adding %s... ', [FInitialPackage.Name]));
  try
    Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
    Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}, False{NeedToFree})];

    FDPMEngine.NotifyUI(Format('version %s', [Version.DisplayName]));

    Result := Result + GetDependencyHandles(Version);

    ProcessUninstallHandles(Result);

    for PackageHandle in Result do
      if PackageHandle.PackageAction = paInstall then
        DoAdd(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

    if FDPMEngine.Project_IsOpened then
      FDPMEngine.SaveActiveProject;

    SavePackages;
    Result := PostProcessPackageHandles(Result);

    FDPMEngine.NotifyUI('succeeded');
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('addition failed');
    end;
  end;
end;

procedure TAdd.DefineRoutes(aDependentPackage: TDependentPackage;
  aInitialPackage: TInitialPackage; aVersion: TVersion);
var
  NodePath: string;
  RelativeFilePath: string;
  TreeNode: TTreeNode;
begin
  aVersion.RepoTree := FDPMEngine.LoadRepoTree(aInitialPackage, aVersion);

  for TreeNode in aVersion.RepoTree do
  begin
    if TreeNode.FileType <> 'blob' then
      Continue;

    if aInitialPackage.AllowPath(TreeNode.Path) then
    begin
      NodePath := aInitialPackage.ApplyPathMoves(TreeNode.Path);
      RelativeFilePath := RepoPathToFilePath(NodePath);

      aDependentPackage.AddRoute(TreeNode.URL, RelativeFilePath);
    end;
  end;
end;

function TAdd.RepoPathToFilePath(const aRepoPath: string): string;
var
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := '';
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := FDPMEngine.Path_Combine(Result, RepoPathPart);
end;

procedure TAdd.SavePackages;
begin
  FDPMEngine.SavePackages;
end;

{ TAddProjectTemplate }

class function TAddProjectTemplate.Allowed(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion): Boolean;
begin
  Result := True;
end;

function TAddProjectTemplate.DoAdd(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage;
var
  Extension: string;
  Files: TArray<string>;
  FileItem: string;
begin
  Result := inherited DoAdd(aInitialPackage, aVersion, aIsDirect);
  aInitialPackage.DependentPackage := nil;
  FreeAndNil(Result);

  Files := FDPMEngine.Files_Get(GetContentPath(aInitialPackage), '*');

  for FileItem in Files do
  begin
    Extension := FDPMEngine.File_GetExtension(FileItem).ToLower;
    if (Extension = '.dproj') or (Extension = '.groupproj') then
    begin
      FDPMEngine.NotifyUI(Format('Opening project %s', [FDPMEngine.File_GetName(FileItem)]));

      TThread.Synchronize(nil, procedure()
        begin
          FDPMEngine.OpenProject(FileItem);
          FDPMEngine.ShowFirstModule;
        end
      );
      Break;
    end;
  end;
end;

function TAddProjectTemplate.GetContentPath(aPackage: TPackage): string;
begin
  if FProjectPath.IsEmpty then
  begin
    FProjectPath := FDPMEngine.GetFolder;
    if FProjectPath.IsEmpty then
      Abort;
  end;

  Result := FProjectPath;
end;

function TAddProjectTemplate.PostProcessPackageHandles(
  const aPackageHandles: TPackageHandles): TPackageHandles;
begin
  Result := [];
end;

procedure TAddProjectTemplate.SavePackages;
begin
end;

{ TAddCodeSource }

function TAddCodeSource.ProcessRequiredDependencies(const aCaption: string;
  aRequiredDependencies: TDependentPackageList): TPackageHandles;
var
  InstalledDependency: TDependentPackage;
  RequiredDependency: TDependentPackage;
  VersionConflict: TVersionConflict;
  VersionConflicts: TVersionConflicts;
begin
  Result := [];
  VersionConflicts := [];

  for RequiredDependency in aRequiredDependencies do
  begin
    InstalledDependency := FDPMEngine.Packages_GetProject.GetByID(RequiredDependency.ID);

    if Assigned(InstalledDependency) then
    begin
      if InstalledDependency.Version.SHA <> RequiredDependency.Version.SHA then
        VersionConflicts := VersionConflicts + [
          TVersionConflict.Create(RequiredDependency, RequiredDependency.Version, InstalledDependency.Version)];
    end
    else
      Result := Result + [GetInstallPackageHandle(RequiredDependency, RequiredDependency.Version)];
  end;

  if Length(VersionConflicts) > 0 then
  begin
    if not TestMode then
      VersionConflicts := FDPMEngine.ShowConflictForm(aCaption, VersionConflicts);

    for VersionConflict in VersionConflicts do
    begin
      if (VersionConflict.Selection = VersionConflict.RequiredVersion) or TestMode then
      begin
        InstalledDependency := FDPMEngine.Packages_GetProject.GetByID(VersionConflict.DependentPackage.ID);
        Result := Result + [TPackageHandle.CreateUninstallHandle(InstalledDependency)];

        Result := Result + [GetInstallPackageHandle(VersionConflict.DependentPackage, VersionConflict.RequiredVersion)];
      end;
    end;
  end;
end;

class function TAddCodeSource.Allowed(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion): Boolean;
begin
  Result := inherited Allowed(aDPMEngine, aPackage, aVersion)
    and aDPMEngine.Project_IsOpened;
end;

procedure TAddCodeSource.AddUnitsToProject(aInitialPackage: TInitialPackage);
var
  Allow: Boolean;
  FileItem: string;
  Files: TArray<string>;
  FileUnitPath: string;
  RepoUnitPath: string;
begin
  Files := FDPMEngine.Files_Get(GetContentPath(aInitialPackage), '*');

  for FileItem in Files do
  begin
    if FDPMEngine.File_GetExtension(FileItem).ToLower <> '.pas' then
      Continue;

    Allow := False;
    case aInitialPackage.AddingUnitsOption of
      auAll: Allow := True;
      auNothing: Allow := False;
      auSpecified:
        begin
          for RepoUnitPath in aInitialPackage.AddingUnitRefs do
          begin
            FileUnitPath := RepoPathToFilePath((aInitialPackage.ApplyPathMoves(RepoUnitPath)));

            if FileItem.EndsWith(FileUnitPath) then
            begin
              Allow := True;
              Break;
            end;
          end;
        end;
    end;

    if Allow then
    begin
      FDPMEngine.NotifyUI(Format('adding to project %s', [FileItem]));
      FDPMEngine.AddFileToActiveProject(FileItem);
    end;
  end;
end;

function TAddCodeSource.DoAdd(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage;
begin
  Result := inherited DoAdd(aInitialPackage, aVersion, aIsDirect);

  AddUnitsToProject(aInitialPackage);

        //n:=GetActiveProject.ProjectOptions.GetOptionNames;
        //s:=GetActiveProject.ProjectOptions.Values['SrcDir'];
        //AddSearchPath;

  FDPMEngine.Packages_GetProject.Add(Result);
end;

function TAddCodeSource.GetDependencyHandles(
  aVersion: TVersion): TPackageHandles;
var
  RequiredDependencies: TDependentPackageList;
begin
  RequiredDependencies := FDPMEngine.Package_LoadDependencies(FInitialPackage, aVersion);
  try
    Result := ProcessRequiredDependencies(Format('Package %s version conflict', [FInitialPackage.Name]),
      RequiredDependencies);
  finally
    RequiredDependencies.Free;
  end;
end;

procedure TAddCodeSource.ProcessUninstallHandles(
  aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
  UninstallCodeSource: TUninstallCodeSource;
begin
  UninstallCodeSource := TUninstallCodeSource.Create(FDPMEngine, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paUninstall then
        UninstallCodeSource.DoUninstall(PackageHandle.Package as TDependentPackage);
  finally
    UninstallCodeSource.Free;
  end;
end;

{ TAddBplBinary }

function TAddBplBinary.DoAdd(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage;
begin
  Result := inherited DoAdd(aInitialPackage, aVersion, aIsDirect);

  DoBplInstall(aInitialPackage, Result, aInitialPackage.BinaryFileRefs,
    function(const aFilePath: string): string
    var
      FileName: string;
    begin
      FileName := FDPMEngine.File_GetName(aFilePath);
      Result := FDPMEngine.Path_Combine(FDPMEngine.Path_GetEnviroment('$(BDSCOMMONDIR)\Bpl'), FileName);

      FDPMEngine.NotifyUI(Format('coping %s to %s', [FileName, Result]));
      FDPMEngine.File_Move(aFilePath, Result);
    end
  );
end;

{ TUninstall }

class function TUninstall.Allowed(aDPMEngine: TDPMEngine; aPackage: TDependentPackage;
  aVersion: TVersion): Boolean;
begin
  Result := Assigned(aPackage) and aPackage.Installed;
end;

constructor TUninstall.Create(aDPMEngine: TDPMEngine;
  aPackage: TDependentPackage);
begin
  FDPMEngine := aDPMEngine;
  FDependentPackage := aPackage;
end;

procedure TUninstall.DeletePackagePath(aPackage: TPackage);
var
  Path: string;
begin
  Path := FDPMEngine.Path_GetPackage(aPackage);
  if (Path.IsEmpty) or not FDPMEngine.Directory_Exists(Path) then
    Exit;

  FDPMEngine.NotifyUI('deleting ' + Path);

  FDPMEngine.Directory_Delete(Path);
  FDPMEngine.Directory_DeleteIfEmpty(FDPMEngine.Path_GetVendors(aPackage.PackageType));
end;

procedure TUninstall.DoUninstall(aDependentPackage: TDependentPackage);
begin
  DeletePackagePath(aDependentPackage);
end;

class function TUninstall.GetClass(
  const aPackageType: TPackageType): TUninstallClass;
begin
  case aPackageType of
    ptCodeSource: Result := TUninstallCodeSource;
    ptBplSource: Result := TUninstallBplSource;
    ptBplBinary: Result := TUninstallBplBinary;
    ptProjectTemplate: Result := TUninstall;
  else
    raise Exception.CreateFmt('TUninstall.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

procedure TUninstall.RemovePackageFromLists(const aPackageID: string;
  aDependentPackage: TDependentPackage);
begin
  FDPMEngine.ResetDependentPackage(aDependentPackage);

  if FDPMEngine.Project_IsOpened then
    FDPMEngine.Packages_GetProject.RemoveByID(aPackageID);
end;

function TUninstall.Run: TPackageHandles;
var
  Dependencies: TDependentPackageList;
  Dependency: TDependentPackage;
  PackageHandle: TPackageHandle;
  UninstallPackage: TDependentPackage;
begin
  FDPMEngine.NotifyUI(Format(#13#10 + 'uninstalling %s %s', [FDependentPackage.Name,
    FDependentPackage.Version.DisplayName]));
  try
    Result := [TPackageHandle.CreateUninstallHandle(FDependentPackage)];

    Dependencies := FDPMEngine.Package_LoadDependencies(FDependentPackage);
    try
      for Dependency in Dependencies do
        if not Dependency.IsDirect and
           not FDPMEngine.Packages_GetProject.IsUsingDependenceExceptOwner(Dependency.ID, FDependentPackage.ID)
        then
          Result := Result + [TPackageHandle.CreateUninstallHandle(Dependency)];
    finally
      Dependencies.Free;
    end;

    for PackageHandle in Result do
    begin
      UninstallPackage := PackageHandle.Package as TDependentPackage;
      DoUninstall(UninstallPackage);
    end;

    if FDPMEngine.Project_IsOpened then
      FDPMEngine.SaveActiveProject;

    FDPMEngine.SavePackages;

    FDPMEngine.NotifyUI('succeeded');
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('uninstallation failed');
    end;
  end;
end;

{ TUninstallCodeSource }

procedure TUninstallCodeSource.DoUninstall(
  aDependentPackage: TDependentPackage);
begin
  RemoveUnitsFromProject(aDependentPackage);

  inherited;

  RemovePackageFromLists(aDependentPackage.ID, aDependentPackage);
end;

procedure TUninstallCodeSource.RemoveUnitsFromProject(
  aDependentPackage: TDependentPackage);
var
  FileItem: string;
  Files: TArray<string>;
begin
  Files := FDPMEngine.Files_Get(FDPMEngine.Path_GetPackage(aDependentPackage), '*');

  for FileItem in Files do
    if FDPMEngine.ProjectActive_Contains(FileItem) then
    begin
      FDPMEngine.NotifyUI(Format('removing from project %s', [FileItem]));
      FDPMEngine.ProjectActive_RemoveFile(FileItem);
    end;
end;

{ TUpdate }

class function TUpdate.Allowed(aDPMEngine: TDPMEngine;
  aPackage: TDependentPackage; aVersion: TVersion): Boolean;
begin
  Result := Assigned(aPackage) and
    Assigned(aVersion) and
    (aPackage.Version.SHA <> aVersion.SHA);
end;

constructor TUpdate.Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage;
  aVersion: TVersion);
begin
  FDPMEngine := aDPMEngine;
  FDependentPackage := aPackage;
  FVersion := aVersion;
end;

class function TUpdate.GetClass(const aPackageType: TPackageType): TUpdateClass;
begin
  case aPackageType of
    ptCodeSource: Result := TUpdateCodeSource;
    ptBplSource: Result := TUpdateBplSource;
    ptBplBinary: Result := TUpdateBplBinary;
    ptProjectTemplate: Result := TUpdate;
  else
    raise Exception.CreateFmt('TUpdate.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TUpdate.GetDependencyHandles(aInitialPackage: TInitialPackage): TPackageHandles;
begin
  Result := [];
end;

function TUpdate.Run: TPackageHandles;
var
  Add: TAdd;
begin
  FDPMEngine.NotifyUI(Format(#13#10 + 'updating %s', [FDependentPackage.Name]));
  FDPMEngine.NotifyUI(Format('from %s to %s ', [FDependentPackage.Version.DisplayName, FVersion.DisplayName]));
  try
    Add := TAdd.Create(FDPMEngine, nil, nil);
    try
      Result := [TPackageHandle.CreateUninstallHandle(FDependentPackage)];
      Result := Result + [Add.GetInstallPackageHandle(FDependentPackage, FVersion, True{aIsDirect})];

      Result := Result + GetDependencyHandles(Result.GetFirstInstallPackage);

      ProcessUninstallHandles(Result);
      ProcessInstallHandles(Result);

      if FDPMEngine.Project_IsOpened then
        FDPMEngine.SaveActiveProject;

      Result := Add.PostProcessPackageHandles(Result);
      FDPMEngine.SavePackages;

      FDPMEngine.NotifyUI('succeeded');
    finally
      Add.Free;
    end;
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('updating failed');
    end;
  end;
end;

{ TAddBplSource }

function TAddBplSource.DoAdd(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean): TDependentPackage;
begin
  Result := inherited DoAdd(aInitialPackage, aVersion, aIsDirect);

  DoBplInstall(aInitialPackage, Result, aInitialPackage.ProjectFileRefs,
    function(const aFilePath: string): string
    begin
      Result := MakeBPL(aFilePath);
    end
  );
end;

function TAddBplSource.FindXmlNode(aNode: IXMLNode;
  const aNodeName: string): IXMLNode;
var
  i: Integer;
begin
  Result := nil;
  if not Assigned(aNode) then
    Exit;

  if CompareText(aNode.NodeName, aNodeName) = 0 then
    Result := aNode
  else
    if Assigned(aNode.ChildNodes) then
      for i := 0 to aNode.ChildNodes.Count - 1 do
      begin
        Result := FindXmlNode(aNode.ChildNodes[I], aNodeName);
        if Result <> nil then
          Exit;
      end;
end;

function TAddBplSource.MakeBPL(const aProjectFilePath: string): string;
var
  ConsoleOutput: string;
  FrameworkDir: string;
  MSBuildPath: string;
  OutputFile: string;
  OutputPath: string;
  RsVarsPath: string;
  StringList: TStringList;
  XmlFile: IXMLDocument;
  XmlNode: IXMLNode;
begin
  FDPMEngine.NotifyUI(Format('compiling %s', [FDPMEngine.File_GetName(aProjectFilePath)]));

  RsVarsPath := FDPMEngine.Path_Combine(FDPMEngine.Path_GetEnviroment('$(BDSBIN)'), 'rsvars.bat');

  if not FDPMEngine.File_Exists(RsVarsPath) then
    raise Exception.Create('compiling bpl: can`t find rsvars.bat');

  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(RsVarsPath);
    FrameworkDir := StringList.Values['@SET FrameworkDir'];
  finally
    StringList.Free;
  end;

  if FrameworkDir.IsEmpty then
    raise Exception.Create('compiling bpl: can`t find .NET FrameworkDir');

  MSBuildPath := FDPMEngine.Path_Combine(FrameworkDir, 'MSBuild.exe');
  ConsoleOutput := FDPMEngine.Console_Run(Format('%s "%s" /t:Make', [MSBuildPath, aProjectFilePath]));

  //FUINotifyProc(ConsoleOutput);

  XmlFile := LoadXMLDocument(aProjectFilePath);

  XmlNode := FindXmlNode(XmlFile.Node, 'DCC_BplOutput');
  if Assigned(XmlNode) and not XmlNode.Text.IsEmpty then
    OutputPath := XmlNode.Text
  else
    OutputPath := '$(BDSCOMMONDIR)\Bpl';
  OutputPath := FDPMEngine.Path_GetEnviroment(OutputPath);

  OutputFile := FindXmlNode(XmlFile.Node, 'MainSource').Text;
  OutputFile := OutputFile.Remove(OutputFile.LastIndexOf('.'));
  OutputFile := OutputFile + '.bpl';

  Result := FDPMEngine.Path_Combine(OutputPath, OutputFile);
  if not FDPMEngine.File_Exists(Result) then
    raise Exception.CreateFmt('compiling bpl: %s was not found.', [Result]);
end;

{ TUninstallBplSource }

procedure TUninstallBplSource.RemovePackageFromLists(const aPackageID: string;
  aDependentPackage: TDependentPackage);
begin
  inherited;

  FDPMEngine.Packages_GetIDE.RemoveByID(aPackageID);
end;

procedure TUninstallBplSource.DoUninstall(aDependentPackage: TDependentPackage);
var
  BplFile: string;
begin
  inherited;

  for BplFile in aDependentPackage.BplFileRefs do
  begin
    FDPMEngine.NotifyUI(Format('uninstalling %s', [FDPMEngine.File_GetName(BplFile)]));
    FDPMEngine.Bpl_Uninstall(BplFile);

    FDPMEngine.NotifyUI('deleting ' + BplFile);
    FDPMEngine.File_Delete(BplFile);
  end;

  RemovePackageFromLists(aDependentPackage.ID, aDependentPackage);
end;

{ TUpdateCodeSource }

function TUpdateCodeSource.GetDependencyHandles(aInitialPackage: TInitialPackage): TPackageHandles;
var
  AddCodeSource: TAddCodeSource;
  InstalledDependencies: TDependentPackageList;
  InstalledDependency: TDependentPackage;
  RequiredDependencies: TDependentPackageList;
  RequiredDependency: TDependentPackage;
begin
  AddCodeSource := TAddCodeSource.Create(FDPMEngine, nil, nil);
  InstalledDependencies := FDPMEngine.Package_LoadDependencies(FDependentPackage);
  RequiredDependencies := FDPMEngine.Package_LoadDependencies(aInitialPackage, FVersion);
  try
    for InstalledDependency in InstalledDependencies do
    begin
      RequiredDependency := RequiredDependencies.GetByID(InstalledDependency.ID);
      if (not Assigned(RequiredDependency)) and
         (not FDPMEngine.Packages_GetProject.IsUsingDependenceExceptOwner(InstalledDependency.ID, FDependentPackage.ID))
      then
      Result := Result + [TPackageHandle.CreateUninstallHandle(InstalledDependency)];
    end;

    Result := Result + AddCodeSource.ProcessRequiredDependencies(Format('Updating package %s version conflict', [FDependentPackage.Name]),
      RequiredDependencies);
  finally
    AddCodeSource.Free;
    InstalledDependencies.Free;
    RequiredDependencies.Free;
  end;
end;

procedure TUpdateCodeSource.ProcessInstallHandles(
  aPackageHandles: TPackageHandles);
var
  AddCodeSource: TAddCodeSource;
  PackageHandle: TPackageHandle;
begin
  AddCodeSource := TAddCodeSource.Create(FDPMEngine, nil, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paInstall then
        AddCodeSource.DoAdd(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);
  finally
    AddCodeSource.Free;
  end;
end;

procedure TUpdateCodeSource.ProcessUninstallHandles(
  aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
  UninstallCodeSource: TUninstallCodeSource;
begin
  UninstallCodeSource := TUninstallCodeSource.Create(FDPMEngine, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paUninstall then
        UninstallCodeSource.DoUninstall(PackageHandle.Package as TDependentPackage);
  finally
    UninstallCodeSource.Free;
  end;
end;

{ TUpdateBplSource }

procedure TUpdateBplSource.ProcessInstallHandles(
  aPackageHandles: TPackageHandles);
var
  AddBplSource: TAddBplSource;
  PackageHandle: TPackageHandle;
begin
  AddBplSource := TAddBplSource.Create(FDPMEngine, nil, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paInstall then
        AddBplSource.DoAdd(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);
  finally
    AddBplSource.Free;
  end;
end;

procedure TUpdateBplSource.ProcessUninstallHandles(
  aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
  UninstallBplSource: TUninstallBplSource;
begin
  UninstallBplSource := TUninstallBplSource.Create(FDPMEngine, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paUninstall then
        UninstallBplSource.DoUninstall(PackageHandle.Package as TDependentPackage);
  finally
    UninstallBplSource.Free;
  end;
end;

{ TAddBplCommon }

procedure TAddBplCommon.DoBplInstall(aInitialPackage: TInitialPackage;
  aDependentPackage: TDependentPackage; const aFileRefs: TArray<string>;
  aCustomFunc: TInstallBplCustomFunc);
var
  BplPath: string;
  FileName: string;
  FilePath: string;
  Files: TArray<string>;
  FilesItem: string;
  PackagePath: string;
begin
  PackagePath := FDPMEngine.Path_GetPackage(aInitialPackage);
  Files := FDPMEngine.Files_Get(PackagePath, '*');
  for FileName in aFileRefs do
  begin
    FilePath := '';

    for FilesItem in Files do
      if FilesItem.EndsWith(FileName) then
      begin
        FilePath := FilesItem;
        Break;
      end;

    if FilePath.IsEmpty then
      raise Exception.CreateFmt('installing bpl: %s was not found.', [FilePath]);

    BplPath := aCustomFunc(FilePath);

    aDependentPackage.BplFileRefs := aDependentPackage.BplFileRefs + [BplPath];
  end;
  FDPMEngine.Directory_DeleteIfEmpty(PackagePath);
  FDPMEngine.Directory_DeleteIfEmpty(FDPMEngine.Path_GetVendors(aInitialPackage.PackageType));

  for BplPath in aDependentPackage.BplFileRefs do
  begin
    FDPMEngine.NotifyUI(Format('installing %s', [FDPMEngine.File_GetName(BplPath)]));
    FDPMEngine.Bpl_Install(BplPath);
  end;

  if FDPMEngine.Project_IsOpened then
    FDPMEngine.Packages_GetProject.Add(aDependentPackage);

  FDPMEngine.Packages_AddCopyToIDE(aDependentPackage);
end;

{ TUpdateBplBinary }

procedure TUpdateBplBinary.ProcessInstallHandles(
  aPackageHandles: TPackageHandles);
var
  AddBplBinary: TAddBplBinary;
  PackageHandle: TPackageHandle;
begin
  AddBplBinary := TAddBplBinary.Create(FDPMEngine, nil, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paInstall then
        AddBplBinary.DoAdd(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);
  finally
    AddBplBinary.Free;
  end;
end;

procedure TUpdateBplBinary.ProcessUninstallHandles(
  aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
  UninstallBplBinary: TUninstallBplBinary;
begin
  UninstallBplBinary := TUninstallBplBinary.Create(FDPMEngine, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paUninstall then
        UninstallBplBinary.DoUninstall(PackageHandle.Package as TDependentPackage);
  finally
    UninstallBplBinary.Free;
  end;
end;

{ TInstall }

procedure TInstall.AddPackageFiles(aPackage: TDependentPackage);
var
  Blob: TBlob;
  Route: TRoute;
begin
  for Route in aPackage.Routes do
  begin
    Blob := FDPMEngine.GHAPI.GetRepoBlob(Route.Source);
    SaveContent(aPackage, Route.Destination, Blob.Content);
  end;
end;

class function TInstall.Allowed(aPackage: TDependentPackage): Boolean;
begin
  Result := not aPackage.Installed;
end;

constructor TInstall.Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage);
begin
  FDPMEngine := aDPMEngine;
  FDependentPackage := aPackage;
end;

procedure TInstall.DoInstall(aPackage: TDependentPackage);
begin
  AddPackageFiles(aPackage);
  aPackage.Installed := True;
end;

class function TInstall.GetClass(
  const aPackageType: TPackageType): TInstallClass;
begin
  Result := TInstall;
end;

function TInstall.GetContentPath(aPackage: TPackage): string;
begin
  Result := FDPMEngine.Path_GetPackage(aPackage);
end;

function TInstall.Run: TPackageHandles;
begin
  FDPMEngine.NotifyUI(Format(#13#10 + 'installing %s %s', [FDependentPackage.Name,
    FDependentPackage.Version.DisplayName]));
  try
    Result := [TPackageHandle.CreateInstallHandle(FDependentPackage)];
    DoInstall(FDependentPackage);

    FDPMEngine.NotifyUI('succeeded');
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('installation failed');
    end;
  end;
end;

procedure TInstall.SaveContent(aPackage: TPackage; const aRelativeFilePath, aContent: string);
var
  Bytes: TBytes;
  FilePath: string;
begin
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);
  FilePath := FDPMEngine.Path_Combine(GetContentPath(aPackage), aRelativeFilePath);

  FDPMEngine.NotifyUI('writing ' + FilePath);
  FDPMEngine.WriteFile(FilePath, Bytes);
end;

end.
