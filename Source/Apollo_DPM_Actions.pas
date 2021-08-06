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

  TInstall = class;
  TInstallClass = class of TInstall;

  TInstall = class abstract(TDPMAction)
  strict private
    FVersion: TVersion;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
  protected
    FInitialPackage: TInitialPackage;
    function GetContentPath(aPackage: TPackage): string; virtual;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; virtual;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion; const aIsDirect: Boolean = False): TPackageHandle;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); virtual;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); virtual;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; virtual;
    class function GetClass(const aPackageType: TPackageType): TInstallClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage; aVersion: TVersion);
  end;

  TInstallCodeSource = class(TInstall)
  private
    function ProcessRequiredDependencies(const aCaption: string;
      aRequiredDependencies: TDependentPackageList): TPackageHandles;
    procedure AddUnitsToProject(aInitialPackage: TInitialPackage);
  protected
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; override;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
    procedure ProcessUninstallHandles(aPackageHandles: TPackageHandles); override;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; override;
  end;

  TInstallBplSource = class(TInstall)
  private
    function FindXmlNode(aNode: IXMLNode; const aNodeName: string): IXMLNode;
    function MakeBPL(const aProjectFileName, aPackagePath: string): string;
  protected
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
  end;

  TInstallBplBinary = class(TInstall)
  protected
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
  end;

  TInstallProjectTemplate = class(TInstall)
  private
    FProjectPath: string;
  protected
    function GetContentPath(aPackage: TPackage): string; override;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
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

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_GitHubAPI,
  System.Classes,
  System.NetEncoding,
  System.SysUtils,
  System.TypInfo,
  Xml.XMLDoc;

{ TInstall }

procedure TInstall.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
begin
  AddPackageFiles(aInitialPackage, aVersion);
end;

class function TInstall.Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
  aVersion: TVersion): Boolean;
begin
  Result :=
    Assigned(aVersion) and
    not aPackage.IsInstalled;
end;

constructor TInstall.Create(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion);
begin
  FDPMEngine := aDPMEngine;
  FInitialPackage := aPackage;
  FVersion := aVersion;
end;

class function TInstall.GetClass(const aPackageType: TPackageType): TInstallClass;
begin
  case aPackageType of
    ptCodeSource: Result := TInstallCodeSource;
    ptBplSource: Result := TInstallBplSource;
    ptBplBinary: Result := TInstall;
    ptProjectTemplate: Result := TInstallProjectTemplate;
  else
    raise Exception.CreateFmt('TInstall.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TInstall.GetContentPath(aPackage: TPackage): string;
begin
  Result := FDPMEngine.Path_GetPackage(aPackage);
end;

function TInstall.GetDependencyHandles(aVersion: TVersion): TPackageHandles;
begin
  Result := [];
end;

function TInstall.GetInstallPackageHandle(aDependentPackage: TDependentPackage;
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

function TInstall.PostProcessPackageHandles(
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

procedure TInstall.ProcessUninstallHandles(aPackageHandles: TPackageHandles);
begin
end;

function TInstall.Run: TPackageHandles;
var
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  FDPMEngine.NotifyUI(Format(#13#10'installing %s... ', [FInitialPackage.Name]));
  try
    Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
    Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}, False{NeedToFree})];

    FDPMEngine.NotifyUI(Format('version %s', [Version.DisplayName]));

    Result := Result + GetDependencyHandles(Version);

    ProcessUninstallHandles(Result);

    for PackageHandle in Result do
      if PackageHandle.PackageAction = paInstall then
        DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

    if FDPMEngine.Project_IsOpened then
      FDPMEngine.SaveActiveProject;

    FDPMEngine.SavePackages;
    Result := PostProcessPackageHandles(Result);

    FDPMEngine.NotifyUI('succeeded');
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('installation failed');
    end;
  end;
end;

procedure TInstall.AddPackageFiles(aInitialPackage: TInitialPackage;
  aVersion: TVersion);
var
  Blob: TBlob;
  NodePath: string;
  TreeNode: TTreeNode;
begin
  aVersion.RepoTree := FDPMEngine.LoadRepoTree(aInitialPackage, aVersion);

  for TreeNode in aVersion.RepoTree do
  begin
    if TreeNode.FileType <> 'blob' then
      Continue;

    if aInitialPackage.AllowPath(TreeNode.Path) then
    begin
      Blob := FDPMEngine.GHAPI.GetRepoBlob(TreeNode.URL);

      NodePath := aInitialPackage.ApplyPathMoves(TreeNode.Path);
      SaveContent(GetContentPath(aInitialPackage), NodePath, Blob.Content);
    end;
  end;
end;

function TInstall.RepoPathToFilePath(const aRepoPath: string): string;
var
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := '';
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := FDPMEngine.Path_Combine(Result, RepoPathPart);
end;

function TInstall.SaveContent(const aPackagePath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
begin
  Result := FDPMEngine.Path_Combine(aPackagePath, RepoPathToFilePath(aRepoPath));
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  FDPMEngine.NotifyUI('writing ' + Result);
  FDPMEngine.WriteFile(Result, Bytes);
end;

{ TInstallProjectTemplate }

class function TInstallProjectTemplate.Allowed(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion): Boolean;
begin
  Result := True;
end;

procedure TInstallProjectTemplate.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
var
  Extension: string;
  Files: TArray<string>;
  FileItem: string;
begin
  inherited;

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

function TInstallProjectTemplate.GetContentPath(aPackage: TPackage): string;
begin
  if FProjectPath.IsEmpty then
  begin
    FProjectPath := FDPMEngine.GetFolder;
    if FProjectPath.IsEmpty then
      Abort;
  end;

  Result := FProjectPath;
end;

{ TInstallCodeSource }

function TInstallCodeSource.ProcessRequiredDependencies(const aCaption: string;
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

class function TInstallCodeSource.Allowed(aDPMEngine: TDPMEngine;
  aPackage: TInitialPackage; aVersion: TVersion): Boolean;
begin
  Result := inherited Allowed(aDPMEngine, aPackage, aVersion)
    and aDPMEngine.Project_IsOpened;
end;

procedure TInstallCodeSource.AddUnitsToProject(aInitialPackage: TInitialPackage);
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

procedure TInstallCodeSource.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage);
  DependentPackage.Version := aVersion;
  DependentPackage.IsDirect := aIsDirect;

  AddUnitsToProject(aInitialPackage);

        //n:=GetActiveProject.ProjectOptions.GetOptionNames;
        //s:=GetActiveProject.ProjectOptions.Values['SrcDir'];
        //AddSearchPath;

  FDPMEngine.Packages_GetProject.Add(DependentPackage);
end;

function TInstallCodeSource.GetDependencyHandles(
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

procedure TInstallCodeSource.ProcessUninstallHandles(
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

{ TInstallBplBinary }

procedure TInstallBplBinary.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
begin
  inherited;
  {if aInitialPackage.PackageType = ptBplSource then
  begin
    BplPaths := [];
    for ProjectFileName in aInitialPackage.ProjectFileRefs do
    begin
      BplPath := MakeBPL(ProjectFileName, GetPackagePath(aInitialPackage));
      DependentPackage.BplFileRefs := DependentPackage.BplFileRefs + [BplPath];
    end;

    for BplPath in DependentPackage.BplFileRefs do
      InstallBpl(BplPath);

    GetIDEPackages.Add(TDependentPackage.Create(DependentPackage.GetJSONString,
      SyncVersionCache));}
end;

{ TUninstall }

class function TUninstall.Allowed(aDPMEngine: TDPMEngine; aPackage: TDependentPackage;
  aVersion: TVersion): Boolean;
begin
  Result := Assigned(aPackage);
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
  if Path.IsEmpty then
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
  Install: TInstall;
begin
  FDPMEngine.NotifyUI(Format(#13#10 + 'updating %s', [FDependentPackage.Name]));
  FDPMEngine.NotifyUI(Format('from %s to %s ', [FDependentPackage.Version.DisplayName, FVersion.DisplayName]));
  try
    Install := TInstall.Create(FDPMEngine, nil, nil);
    try
      Result := [TPackageHandle.CreateUninstallHandle(FDependentPackage)];
      Result := Result + [Install.GetInstallPackageHandle(FDependentPackage, FVersion, True{aIsDirect})];

      Result := Result + GetDependencyHandles(Result.GetFirstInstallPackage);

      ProcessUninstallHandles(Result);
      ProcessInstallHandles(Result);

      if FDPMEngine.Project_IsOpened then
        FDPMEngine.SaveActiveProject;

      Result := Install.PostProcessPackageHandles(Result);
      FDPMEngine.SavePackages;

      FDPMEngine.NotifyUI('succeeded');
    finally
      Install.Free;
    end;
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('updating failed');
    end;
  end;
end;

{ TInstallBplSource }

procedure TInstallBplSource.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
var
  BplPath: string;
  DependentPackage: TDependentPackage;
  ProjectFileName: string;
begin
  inherited;

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage);
  DependentPackage.Version := aVersion;
  DependentPackage.IsDirect := aIsDirect;

  for ProjectFileName in aInitialPackage.ProjectFileRefs do
  begin
    BplPath := MakeBPL(ProjectFileName, FDPMEngine.Path_GetPackage(aInitialPackage));
    DependentPackage.BplFileRefs := DependentPackage.BplFileRefs + [BplPath];
  end;

  for BplPath in DependentPackage.BplFileRefs do
  begin
    FDPMEngine.NotifyUI(Format('installing %s', [FDPMEngine.File_GetName(BplPath)]));
    FDPMEngine.Bpl_Install(BplPath);
  end;

  if FDPMEngine.Project_IsOpened then
    FDPMEngine.Packages_GetProject.Add(DependentPackage);

  FDPMEngine.Packages_AddCopyToIDE(DependentPackage);
end;

function TInstallBplSource.FindXmlNode(aNode: IXMLNode;
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

function TInstallBplSource.MakeBPL(const aProjectFileName,
  aPackagePath: string): string;
var
  ConsoleOutput: string;
  FileItem: string;
  Files: TArray<string>;
  FrameworkDir: string;
  MSBuildPath: string;
  OutputFile: string;
  OutputPath: string;
  ProjectFilePath: string;
  RsVarsPath: string;
  StringList: TStringList;
  XmlFile: IXMLDocument;
  XmlNode: IXMLNode;
begin
  FDPMEngine.NotifyUI(Format('compiling %s', [aProjectFileName]));

  ProjectFilePath := '';
  Files := FDPMEngine.Files_Get(aPackagePath, '*');
  for FileItem in Files do
    if FileItem.EndsWith(aProjectFileName) then
    begin
      ProjectFilePath := FileItem;
      Break;
    end;

  if ProjectFilePath.IsEmpty then
    raise Exception.CreateFmt('compiling bpl: %s was not found.', [aProjectFileName]);

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
  ConsoleOutput := FDPMEngine.Console_Run(Format('%s "%s" /t:Make', [MSBuildPath, ProjectFilePath]));

  //FUINotifyProc(ConsoleOutput);

  XmlFile := LoadXMLDocument(ProjectFilePath);

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
  InstallCodeSource: TInstallCodeSource;
  InstalledDependencies: TDependentPackageList;
  InstalledDependency: TDependentPackage;
  RequiredDependencies: TDependentPackageList;
  RequiredDependency: TDependentPackage;
begin
  InstallCodeSource := TInstallCodeSource.Create(FDPMEngine, nil, nil);
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

    Result := Result + InstallCodeSource.ProcessRequiredDependencies(Format('Updating package %s version conflict', [FDependentPackage.Name]),
      RequiredDependencies);
  finally
    InstallCodeSource.Free;
    InstalledDependencies.Free;
    RequiredDependencies.Free;
  end;
end;

procedure TUpdateCodeSource.ProcessInstallHandles(
  aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
  InstallCodeSource: TInstallCodeSource;
begin
  InstallCodeSource := TInstallCodeSource.Create(FDPMEngine, nil, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paInstall then
        InstallCodeSource.DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);
  finally
    InstallCodeSource.Free;
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
  PackageHandle: TPackageHandle;
  InstallBplSource: TInstallBplSource;
begin
  InstallBplSource := TInstallBplSource.Create(FDPMEngine, nil, nil);
  try
    for PackageHandle in aPackageHandles do
      if PackageHandle.PackageAction = paInstall then
        InstallBplSource.DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);
  finally
    InstallBplSource.Free;
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

end.
