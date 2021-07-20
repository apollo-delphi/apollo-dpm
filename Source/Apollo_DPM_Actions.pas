unit Apollo_DPM_Actions;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version;

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

  TInstall = class;
  TInstallClass = class of TInstall;

  TInstall = class abstract(TDPMAction)
  strict private
    FInitialPackage: TInitialPackage;
    FVersion: TVersion;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
  protected
    function GetContentPath(aPackage: TPackage): string; virtual; abstract;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; virtual;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion; const aIsDirect: Boolean = False): TPackageHandle;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles;
    function ProcessRequiredDependencies(const aCaption: string;
      aRequiredDependencies: TDependentPackageList): TPackageHandles;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); virtual;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; virtual;
    class function GetClass(const aPackageType: TPackageType): TInstallClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage; aVersion: TVersion);
  end;

  TInstallCodeSource = class(TInstall)
  private
    procedure AddUnitsToProject(aInitialPackage: TInitialPackage);
  protected
    function GetContentPath(aPackage: TPackage): string; override;
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
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; override;
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
  public
    class function GetClass(const aPackageType: TPackageType): TUpdateClass;
    function Run: TPackageHandles;
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TDependentPackage; aVersion: TVersion);
  end;

  TUpdateCodeSource = class(TUpdate)
  end;

implementation

uses
  Apollo_DPM_GitHubAPI,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.SysUtils,
  System.TypInfo;

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
    aDPMEngine.IsProjectOpened and
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
    ptBplSource, ptBplBinary: Result := TInstall;
    ptProjectTemplate: Result := TInstallProjectTemplate;
  else
    raise Exception.CreateFmt('TInstall..GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TInstall.GetDependencyHandles(aVersion: TVersion): TPackageHandles;
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

function TInstall.GetInstallPackageHandle(aDependentPackage: TDependentPackage;
  aVersion: TVersion; const aIsDirect: Boolean = False): TPackageHandle;
var
  InitialPackage: TInitialPackage;
  NeedToFree: Boolean;
begin
  NeedToFree := False;

  InitialPackage := FDPMEngine.GetInitialPackage(aDependentPackage);

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

function TInstall.ProcessRequiredDependencies(const aCaption: string;
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

function TInstall.Run: TPackageHandles;
var
  PackageHandle: TPackageHandle;
  UninstallCodeSource: TUninstallCodeSource;
  Version: TVersion;
begin
  FDPMEngine.NotifyUI(Format(#13#10'installing %s... ', [FInitialPackage.Name]));
  try
    Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
    Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}, False{NeedToFree})];

    FDPMEngine.NotifyUI(Format('version %s', [Version.DisplayName]));

    Result := Result + GetDependencyHandles(Version);

    UninstallCodeSource := TUninstallCodeSource.Create(FDPMEngine, nil);
    try
      for PackageHandle in Result do
        if PackageHandle.PackageAction = paUninstall then
          UninstallCodeSource.DoUninstall(PackageHandle.Package as TDependentPackage);
    finally
      UninstallCodeSource.Free;
    end;

    for PackageHandle in Result do
      if PackageHandle.PackageAction = paInstall then
        DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

    if FDPMEngine.IsProjectOpened then
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
    Result := TPath.Combine(Result, RepoPathPart);
end;

function TInstall.SaveContent(const aPackagePath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
begin
  Result := TPath.Combine(aPackagePath, RepoPathToFilePath(aRepoPath));
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
    Extension := TPath.GetExtension(FileItem).ToLower;
    if (Extension = '.dproj') or (Extension = '.groupproj') then
    begin
      FDPMEngine.NotifyUI(Format('Opening project %s', [TPath.GetFileName(FileItem)]));

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

function TInstallProjectTemplate.GetDependencyHandles(aVersion: TVersion): TPackageHandles;
begin
  Result := [];
end;

{ TInstallCodeSource }

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
    if TPath.GetExtension(FileItem).ToLower <> '.pas' then
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

function TInstallCodeSource.GetContentPath(aPackage: TPackage): string;
begin
  Result := FDPMEngine.GetPackagePath(aPackage);
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
  Result := aDPMEngine.IsProjectOpened and
    Assigned(aPackage) and
    Assigned(aVersion) and
    (aPackage.Version.SHA = aVersion.SHA);

           {Result :=
            Assigned(aVersion) and
            InitialPackage.IsInstalled and
            (InitialPackage.DependentPackage.Version.SHA = aVersion.SHA) and
            (((InitialPackage.DependentPackage.PackageType in [ptCodeSource]) and IsProjectOpened) or
             (InitialPackage.DependentPackage.PackageType in [ptBplSource, ptBplBinary])
            );}

        {Result :=
          (((DependentPackage.PackageType in [ptCodeSource]) and IsProjectOpened) or
           (DependentPackage.PackageType in [ptBplSource, ptBplBinary])
          ) and
          Assigned(aVersion) and
          (DependentPackage.Version.SHA = aVersion.SHA);  }
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
  Path := FDPMEngine.GetPackagePath(aPackage);
  if Path.IsEmpty then
    Exit;

  FDPMEngine.NotifyUI('deleting ' + Path);

  TDirectory.Delete(Path, True);

  if Length(TDirectory.GetDirectories(FDPMEngine.Path_GetVendors, '*', TSearchOption.soTopDirectoryOnly)) = 0 then
    TDirectory.Delete(FDPMEngine.Path_GetVendors);
end;

procedure TUninstall.DoUninstall(aDependentPackage: TDependentPackage);
//var
//  BplFile: string;
//  InitialPackage: TInitialPackage;
//  PackageID: string;
begin
  DeletePackagePath(aDependentPackage);

  {PackageID := aDependentPackage.ID;

  if aDependentPackage.PackageType = ptBplSource then
  begin
    for BplFile in aDependentPackage.BplFileRefs do
    begin
      UninstallBpl(BplFile);
      TFile.Delete(BplFile);
    end;

    GetIDEPackages.RemoveByID(PackageID);
  end;

  GetProjectPackages.RemoveByID(PackageID); }  //raise Exception.Create('Error Message');
end;

class function TUninstall.GetClass(
  const aPackageType: TPackageType): TUninstallClass;
begin
  case aPackageType of
    ptCodeSource: Result := TUninstallCodeSource;
    ptBplSource: Result := TUninstall;
    ptProjectTemplate: Result := TUninstall;
  else
    raise Exception.CreateFmt('TUninstall.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TUninstall.Run: TPackageHandles;
var
  Dependencies: TDependentPackageList;
  Dependency: TDependentPackage;
  PackageHandle: TPackageHandle;
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
      DoUninstall(PackageHandle.Package as TDependentPackage);

    if FDPMEngine.IsProjectOpened then
      FDPMEngine.SaveActiveProject;

    FDPMEngine.SavePackages;

    FDPMEngine.NotifyUI('succeeded');
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('uninstallation failed');
      raise;
    end;
  end;
end;

{ TUninstallCodeSource }

procedure TUninstallCodeSource.DoUninstall(
  aDependentPackage: TDependentPackage);
var
  PackageID: string;
begin
  RemoveUnitsFromProject(aDependentPackage);

  inherited;

  PackageID := aDependentPackage.ID;
  FDPMEngine.ResetDependentPackage(aDependentPackage);

  FDPMEngine.Packages_GetProject.RemoveByID(PackageID);
end;

procedure TUninstallCodeSource.RemoveUnitsFromProject(
  aDependentPackage: TDependentPackage);
var
  FileItem: string;
  Files: TArray<string>;
begin
  Files := FDPMEngine.Files_Get(FDPMEngine.GetPackagePath(aDependentPackage), '*');

  for FileItem in Files do
    if FDPMEngine.ProjectActive_Contains(FileItem) then
    begin
      FDPMEngine.NotifyUI(Format('removing from project %s', [FileItem]));
      FDPMEngine.ProjectActive_RemoveFile(FileItem);
    end;
end;

{ TUpdate }

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
    ptBplSource: Result := TUpdate;
    ptProjectTemplate: Result := TUpdate;
  else
    raise Exception.CreateFmt('TUpdate.GetClass: unknown PackageType %s',
      [GetEnumName(TypeInfo(TPackageType), Ord(aPackageType))]);
  end;
end;

function TUpdate.Run: TPackageHandles;
var
  InstallCodeSource: TInstallCodeSource;
  InstalledDependencies: TDependentPackageList;
  InstalledDependency: TDependentPackage;
  PackageHandle: TPackageHandle;
  RequiredDependencies: TDependentPackageList;
  RequiredDependency: TDependentPackage;
  UninstallCodeSource: TUninstallCodeSource;
begin
  FDPMEngine.NotifyUI(Format(#13#10 + 'updating %s', [FDependentPackage.Name]));
  FDPMEngine.NotifyUI(Format('from %s to %s ', [FDependentPackage.Version.DisplayName, FVersion.DisplayName]));
  try
    UninstallCodeSource := TUninstallCodeSource.Create(FDPMEngine, nil);
    InstallCodeSource := TInstallCodeSource.Create(FDPMEngine, nil, nil);
    try
      Result := [TPackageHandle.CreateUninstallHandle(FDependentPackage)];
      Result := Result + [InstallCodeSource.GetInstallPackageHandle(FDependentPackage, FVersion, True{aIsDirect})];

      InstalledDependencies := FDPMEngine.Package_LoadDependencies(FDependentPackage);
      RequiredDependencies := FDPMEngine.Package_LoadDependencies(Result.GetFirstInstallPackage, FVersion);
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
        InstalledDependencies.Free;
        RequiredDependencies.Free;
      end;

      for PackageHandle in Result do
        if PackageHandle.PackageAction = paUninstall then
          UninstallCodeSource.DoUninstall(PackageHandle.Package as TDependentPackage);

      for PackageHandle in Result do
        if PackageHandle.PackageAction = paInstall then
          InstallCodeSource.DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

      if FDPMEngine.IsProjectOpened then
        FDPMEngine.SaveActiveProject;

      Result := InstallCodeSource.PostProcessPackageHandles(Result);
      FDPMEngine.SavePackages;

      FDPMEngine.NotifyUI('succeeded');
    finally
      UninstallCodeSource.Free;
      InstallCodeSource.Free;
    end;
  except
    on E: Exception do
    begin
      FDPMEngine.NotifyUI(E.Message);
      FDPMEngine.NotifyUI('updating failed');
      raise;
    end;
  end;
end;

end.
