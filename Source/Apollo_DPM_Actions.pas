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
    procedure DoUninstall(aDependentPackage: TDependentPackage);
  public
    function Run: TPackageHandles; virtual; abstract;
  end;

  TInstall = class;
  TDPMActionClass = class of TInstall;

  TInstall = class abstract(TDPMAction)
  private
    FInitialPackage: TInitialPackage;
    FVersion: TVersion;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion): TPackageHandle;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles;
    function ProcessRequiredDependencies(const aCaption: string;
      aRequiredDependencies: TDependentPackageList): TPackageHandles;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
  protected
    function GetContentPath: string; virtual; abstract;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; virtual;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); virtual;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; virtual;
    class function GetClass(const aPackageType: TPackageType): TDPMActionClass;
    function Run: TPackageHandles; override;
    constructor Create(aDPMEngine: TDPMEngine; aInitialPackage: TInitialPackage; aVersion: TVersion);
  end;

  TInstallCodeSource = class(TInstall)
  private
    procedure AddUnitsToProject(aInitialPackage: TInitialPackage);
  protected
    function GetContentPath: string; override;
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
    function GetContentPath: string; override;
    function GetDependencyHandles(aVersion: TVersion): TPackageHandles; override;
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion; const aIsDirect: Boolean); override;
  public
    class function Allowed(aDPMEngine: TDPMEngine; aPackage: TInitialPackage;
      aVersion: TVersion): Boolean; override;
  end;

implementation

uses
  Apollo_DPM_GitHubAPI,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.SysUtils;

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
  aInitialPackage: TInitialPackage; aVersion: TVersion);
begin
  FDPMEngine := aDPMEngine;
  FInitialPackage := aInitialPackage;
  FVersion := aVersion;
end;

class function TInstall.GetClass(const aPackageType: TPackageType): TDPMActionClass;
begin
  case aPackageType of
    ptCodeSource: Result := TInstallCodeSource;
    ptBplSource, ptBplBinary: Result := TInstall;
    ptProjectTemplate: Result := TInstallProjectTemplate;
  else
    raise Exception.Create('TInstall.GetClass: unknown PackageType');
  end;
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
  FDPMEngine.NotifyUI(Format(#13#10'installing %s... ', [FInitialPackage.Name]));

  Version := FDPMEngine.DefineVersion(FInitialPackage, FVersion);
  Result := [TPackageHandle.CreateInstallHandle(FInitialPackage, Version, True{IsDirect}, False{NeedToFree})];

  FDPMEngine.NotifyUI(Format('version %s', [Version.DisplayName]));

  Result := Result + GetDependencyHandles(Version);

  for PackageHandle in Result do
    if PackageHandle.PackageAction = paUninstall then
      DoUninstall(PackageHandle.Package as TDependentPackage);

  for PackageHandle in Result do
    if PackageHandle.PackageAction = paInstall then
      DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version, PackageHandle.IsDirect);

  if FDPMEngine.IsProjectOpened then
    FDPMEngine.SaveActiveProject;

  FDPMEngine.SavePackages;
  Result := PostProcessPackageHandles(Result);

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
      SaveContent(GetContentPath, NodePath, Blob.Content);
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

{ TDPMAction }

procedure TDPMAction.DoUninstall(aDependentPackage: TDependentPackage);
begin

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

{ TInstallCodeSource }

procedure TInstallCodeSource.AddUnitsToProject(aInitialPackage: TInitialPackage);
var
  Allow: Boolean;
  FileItem: string;
  Files: TArray<string>;
  FileUnitPath: string;
  RepoUnitPath: string;
begin
  Files := FDPMEngine.GetFiles(GetContentPath, '*');

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

  FDPMEngine.GetProjectPackages.Add(DependentPackage);

  Sleep(10000);
end;

function TInstallCodeSource.GetContentPath: string;
begin
  Result := FDPMEngine.GetPackagePath(FInitialPackage);
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

end.
