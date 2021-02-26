unit Apollo_DPM_Actions;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version;

type
  TDPMAction = class abstract
  private
    function RepoPathToFilePath(const aRepoPath: string): string;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
  protected
    FDPMEngine: TDPMEngine;
    function GetContentPath: string; virtual; abstract;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); virtual;
    procedure DoUninstall(aDependentPackage: TDependentPackage);
  public
    function Run: TPackageHandles; virtual; abstract;
  end;

  TInstall = class abstract(TDPMAction)
  private
    FInitialPackage: TInitialPackage;
    FVersion: TVersion;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion): TPackageHandle;
    function ProcessRequiredDependencies(const aCaption: string;
      aRequiredDependencies: TDependentPackageList): TPackageHandles;
  protected
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; virtual;
  public
    function Run: TPackageHandles; override;
    constructor Create(aDPMEngine: TDPMEngine; aInitialPackage: TInitialPackage; aVersion: TVersion);
  end;

  TInstallCodeSource = class(TInstall)
  end;

  TInstallProjectTemplate = class(TInstall)
  private
    FProjectPath: string;
  protected
    function GetContentPath: string; override;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; override;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
  end;

implementation

uses
  Apollo_DPM_GitHubAPI,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.SysUtils;

{ TInstall }

constructor TInstall.Create(aDPMEngine: TDPMEngine;
  aInitialPackage: TInitialPackage; aVersion: TVersion);
begin
  FDPMEngine := aDPMEngine;
  FInitialPackage := aInitialPackage;
  FVersion := aVersion;
end;

function TInstall.GetDependencyHandles(aVersion: TVersion): TPackageHandles;
var
  RequiredDependencies: TDependentPackageList;
begin
  RequiredDependencies := FDPMEngine.LoadDependencies(FInitialPackage, aVersion);
  try
    Result := Result + ProcessRequiredDependencies(Format('Package %s version conflict', [FInitialPackage.Name]),
      RequiredDependencies);
  finally
    RequiredDependencies.Free;
  end;
end;

function TInstall.GetInstallPackageHandle(aDependentPackage: TDependentPackage;
  aVersion: TVersion): TPackageHandle;
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
  Result := TPackageHandle.CreateInstallHandle(InitialPackage, aVersion, False{IsDirect}, NeedToFree);
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
    InstalledDependency := FDPMEngine.GetProjectPackages.GetByID(RequiredDependency.ID);

    if Assigned(InstalledDependency) and
      (InstalledDependency.Version.SHA <> RequiredDependency.Version.SHA)
    then
        VersionConflicts := VersionConflicts + [
          TVersionConflict.Create(RequiredDependency, RequiredDependency.Version, InstalledDependency.Version)]
    else
      Result := Result + [GetInstallPackageHandle(RequiredDependency, RequiredDependency.Version)];
  end;

  if Length(VersionConflicts) > 0 then
  begin
    VersionConflicts := FDPMEngine.ShowConflictForm(aCaption, VersionConflicts);

    for VersionConflict in VersionConflicts do
    begin
      if VersionConflict.Selection = VersionConflict.RequiredVersion then
      begin
        InstalledDependency := FDPMEngine.GetProjectPackages.GetByID(VersionConflict.DependentPackage.ID);
        Result := Result + [TPackageHandle.CreateUninstallHandle(InstalledDependency)];

        Result := Result + [GetInstallPackageHandle(VersionConflict.DependentPackage, VersionConflict.Selection)];
      end;
    end;
  end;
end;

function TInstall.Run: TPackageHandles;
var
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
  Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}, False{NeedToFree})];

  FDPMEngine.NotifyUI(Format(#13#10'installing %s %s', [FInitialPackage.Name, Version.DisplayName]));

  Result := Result + GetDependencyHandles(Version);

  for PackageHandle in Result do
    if PackageHandle.PackageAction = paUninstall then
      DoUninstall(PackageHandle.Package as TDependentPackage);

  for PackageHandle in Result do
    if PackageHandle.PackageAction = paInstall then
      DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

  {if IsProjectOpened then
    SaveActiveProject;

  SavePackages;
  Result := PostProcessPackageHandles(Result); }

  FDPMEngine.NotifyUI('succeeded');

  {try
    Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
    Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}{, False{NeedToFree}{)];

    FUINotifyProc(Format(#13#10'installing %s %s', [aInitialPackage.Name, Version.DisplayName]));

    RequiredDependencies := LoadDependencies(aInitialPackage, Version);
    try
      Result := Result + ProcessRequiredDependencies(Format('Package %s version conflict', [aInitialPackage.Name]),
        RequiredDependencies);
    finally
      RequiredDependencies.Free;
    end;

    try
      for PackageHandle in Result do
        if PackageHandle.PackageAction = paUninstall then
          DoUninstall(PackageHandle.Package as TDependentPackage);

      for PackageHandle in Result do
        if PackageHandle.PackageAction = paInstall then
          DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

      if IsProjectOpened then
        SaveActiveProject;

      FUINotifyProc('succeeded');
    except
      on E: Exception do
      begin
        FUINotifyProc(E.Message);
        FUINotifyProc('installation failed');
      end;
    end;
  finally
    SavePackages;
    Result := PostProcessPackageHandles(Result);
  end;}
end;

{ TDPMAction }

procedure TDPMAction.AddPackageFiles(aInitialPackage: TInitialPackage;
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
      SaveContent(GetContentPath, NodePath, Blob.Content);
    end;
  end;
end;

procedure TDPMAction.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
begin
  AddPackageFiles(aInitialPackage, aVersion);
end;

procedure TDPMAction.DoUninstall(aDependentPackage: TDependentPackage);
begin

end;

function TDPMAction.RepoPathToFilePath(const aRepoPath: string): string;
var
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := '';
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := TPath.Combine(Result, RepoPathPart);
end;

function TDPMAction.SaveContent(const aPackagePath, aRepoPath,
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

procedure TInstallProjectTemplate.DoInstall(aInitialPackage: TInitialPackage;
  aVersion: TVersion; const aIsDirect: Boolean);
var
  Extension: string;
  Files: TArray<string>;
  FileItem: string;
begin
  inherited;

  Files := FDPMEngine.GetFiles(GetContentPath, '*');

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

function TInstallProjectTemplate.GetContentPath: string;
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

end.
