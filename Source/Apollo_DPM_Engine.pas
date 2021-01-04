unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FGHAPI: TGHAPI;
    FPrivatePackages: TPrivatePackageList;
    FProjectPackages: TDependentPackageList;
    FUINotifyProc: TUINotifyProc;
    FVersionCacheList: TVersionCacheList;
    function DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetInitialPackage(aDependentPackage: TDependentPackage): TInitialPackage;
    function GetPackagePath(aPackage: TPackage): string;
    function GetProjectPackagesPath: string;
    function GetPrivatePackagesFolderPath: string;
    function GetVendorsPath: string;
    function GetVersionCacheList: TVersionCacheList;
    function GetTextFromFile(const aPath: string): string;
    function IsProjectOpened: Boolean;
    function LoadDependencies(aPackage: TPackage; aVersion: TVersion): TDependentPackageList;
    function LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
    function SaveAsPrivatePackage(aPackage: TInitialPackage): string;
    function SaveContent(const aPackagePath, aSourcePath, aContent: string): string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
    procedure BuildMenu;
    procedure DeletePackagePath(aPackage: TPackage);
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion);
    procedure DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
      aResult: TDependentPackageList);
    procedure DPMMenuItemClick(Sender: TObject);
    procedure FreePackageLists;
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure SaveProjectPackages;
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    function AreVersionsLoaded(const aPackageID: string): Boolean;
    function AllowAction(const aFrameActionType: TFrameActionType;
      aPackage: TPackage): Boolean;
    function GetPrivatePackages: TPrivatePackageList;
    function GetProjectPackages: TDependentPackageList;
    function GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
    function Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    procedure AddNewPrivatePackage(aPackage: TInitialPackage);
    procedure Uninstall(aPackage: TPackage);
    procedure UpdatePrivatePackage(aPackage: TPrivatePackage);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils,
  System.NetEncoding;

{ TDPMEngine }

procedure TDPMEngine.AddApolloMenuItem;
var
  ApolloItem: TMenuItem;
begin
  ApolloItem := TMenuItem.Create(nil);
  ApolloItem.Name := cApolloMenuItemName;
  ApolloItem.Caption := cApolloMenuItemCaption;

  GetIDEMainMenu.Items.Insert(GetIDEMainMenu.Items.Count - 1, ApolloItem);
end;

procedure TDPMEngine.AddDPMMenuItem;
var
  DPMMenuItem: TMenuItem;
begin
  DPMMenuItem := TMenuItem.Create(nil);
  DPMMenuItem.Caption := cDPMMenuItemCaption;
  DPMMenuItem.OnClick := DPMMenuItemClick;

  GetApolloMenuItem.Add(DPMMenuItem);
end;

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TInitialPackage);
var
  Package: TPrivatePackage;
  Path: string;
begin
  Path := SaveAsPrivatePackage(aPackage);

  Package := TPrivatePackage.Create(GetTextFromFile(Path));
  Package.FilePath := Path;

  GetPrivatePackages.Add(Package);
end;

procedure TDPMEngine.AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
var
  Blob: TBlob;
  NodePath: string;
  TreeNode: TTreeNode;
begin
  for TreeNode in aVersion.RepoTree do
  begin
    if TreeNode.FileType <> 'blob' then
      Continue;

    if aInitialPackage.AllowPath(TreeNode.Path) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

      NodePath := aInitialPackage.ApplyPathMoves(TreeNode.Path);
      SaveContent(GetPackagePath(aInitialPackage), NodePath, Blob.Content);
    end;
  end;
end;

function TDPMEngine.AllowAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage): Boolean;
begin
  Result := False;

  if aPackage is TInitialPackage then
    case aFrameActionType of
      fatInstall:
        Result := IsProjectOpened
              and (not Assigned((aPackage as TInitialPackage).DependentPackage));

      fatUninstall:
        begin
          Result := IsProjectOpened
                and Assigned((aPackage as TInitialPackage).DependentPackage);
        end;

      fatEditPackage:
        Result := True;
    end
  else
  if aPackage is TDependentPackage then
    case aFrameActionType of
      fatInstall:
        Result := False;

      fatUninstall:
        begin
          Result := IsProjectOpened;
        end;

      fatEditPackage:
        Result := False;
    end;
end;

function TDPMEngine.AreVersionsLoaded(const aPackageID: string): Boolean;
begin
  Result := GetVersionCacheList.ContainsLoadedPackageID(aPackageID);
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create;
begin
  FGHAPI := TGHAPI.Create;

  BuildMenu;

  Validation := TValidation.Create(Self);
end;

function TDPMEngine.DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
var
  Versions: TArray<TVersion>;
begin
  if not aVersion.SHA.IsEmpty then
    Exit(aVersion);

  if aVersion.Name = cStrLatestVersionOrCommit then
  begin
    Versions := GetVersions(aPackage);
    if Length(Versions) > 0 then
      Exit(Versions[0]);
  end;

  Result := TVersion.Create;
  Result.Name := '';
  Result.SHA := FGHAPI.GetMasterBranchSHA(aPackage.RepoOwner, aPackage.RepoName);
end;

procedure TDPMEngine.DeletePackagePath(aPackage: TPackage);
begin
  TDirectory.Delete(GetPackagePath(aPackage), True);

  if Length(TDirectory.GetDirectories(GetVendorsPath, '*', TSearchOption.soTopDirectoryOnly)) = 0 then
    TDirectory.Delete(GetVendorsPath);
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;
  FreePackageLists;

  if Assigned(FVersionCacheList) then
    FreeAndNil(FVersionCacheList);

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

procedure TDPMEngine.DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion);
var
  DependentPackage: TDependentPackage;
begin
  FUINotifyProc(Format(#13#10 + 'Installing %s %s', [aInitialPackage.Name, aVersion.DisplayName]));

  DependentPackage := TDependentPackage.Create(aInitialPackage);
  DependentPackage.Version := aVersion;

  if not GetVersionCacheList.AddVersion(DependentPackage.ID, aVersion) then
    raise Exception.Create('Version already installed!');

  AddPackageFiles(aInitialPackage, aVersion);

  GetProjectPackages.Add(DependentPackage);
end;

procedure TDPMEngine.DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
  aResult: TDependentPackageList);
var
  Blob: TBlob;
  i: Integer;
  Package: TDependentPackage;
  PackageList: TDependentPackageList;
  sJSON: string;
  TreeNode: TTreeNode;
begin
  if Length(aVersion.RepoTree) = 0 then
    aVersion.RepoTree := LoadRepoTree(aDependentPackage, aVersion);

  for TreeNode in aVersion.RepoTree do
    if TreeNode.Path.EndsWith(cProjectPackagesPath) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);
      sJSON := TNetEncoding.Base64.Decode(Blob.Content);

      PackageList := TDependentPackageList.Create(sJSON);
      try
        for i := PackageList.Count - 1 downto 0 do
        begin
          Package := PackageList.ExtractAt(i);
          aResult.Add(Package);

          DoLoadDependencies(Package, Package.Version, aResult);
        end;
      finally
        PackageList.Free;
      end;
    end;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    FUINotifyProc := DPMForm.NotifyObserver;
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
    FreePackageLists;
  end;
end;

function TDPMEngine.GetInitialPackage(
  aDependentPackage: TDependentPackage): TInitialPackage;
begin
  Result := GetPrivatePackages.GetByID(aDependentPackage.ID);

  if Assigned(Result) then
    Exit(Result);

  Result := TInitialPackage.Create;
  Result.Assign(aDependentPackage);
end;

procedure TDPMEngine.FreePackageLists;
begin
  if Assigned(FPrivatePackages) then
    FreeAndNil(FPrivatePackages);
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);
end;

function TDPMEngine.GetActiveProject: IOTAProject;
var
  i: Integer;
  Module: IOTAModule;
  ModuleServices: IOTAModuleServices;
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;
begin
  Result := nil;

  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  for i := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Module := ModuleServices.Modules[i];
    if Supports(Module, IOTAProjectGroup, ProjectGroup) then
      Exit(ProjectGroup.ActiveProject)
    else
    if Supports(Module, IOTAProject, Project) then
      Exit(Project);
  end;
end;

function TDPMEngine.GetActiveProjectPath: string;
begin
  Result := TDirectory.GetParent(GetActiveProject.FileName);
end;

function TDPMEngine.GetApolloMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;

  for MenuItem in GetIDEMainMenu.Items do
    if MenuItem.Name = cApolloMenuItemName then
      Exit(MenuItem);
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.GetPackagePath(aPackage: TPackage): string;
begin
  Result := TPath.Combine(GetVendorsPath, aPackage.Name);
end;

function TDPMEngine.GetPrivatePackages: TPrivatePackageList;
var
  DependentPackage: TDependentPackage;
  FileArr: TArray<string>;
  FileItem: string;
  PrivatePackage: TPrivatePackage;
  PrivatePackageFile: TPrivatePackageFile;
  PrivatePackageFiles: TArray<TPrivatePackageFile>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesFolderPath) then
    begin
      FileArr := TDirectory.GetFiles(GetPrivatePackagesFolderPath, '*.json');
      PrivatePackageFiles := [];
      for FileItem in FileArr do
      begin
        PrivatePackageFile.Path := FileItem;
        PrivatePackageFile.JSONString := GetTextFromFile(FileItem);

        PrivatePackageFiles := PrivatePackageFiles + [PrivatePackageFile];
      end;

      if Length(PrivatePackageFiles) > 0 then
        FPrivatePackages := TPrivatePackageList.Create(PrivatePackageFiles);

      for PrivatePackage in FPrivatePackages do
      begin
        DependentPackage := GetProjectPackages.GetByID(PrivatePackage.ID);
        if Assigned(DependentPackage) then
          PrivatePackage.DependentPackage := DependentPackage;
      end;
    end;
  end;

  if not Assigned(FPrivatePackages) then
    FPrivatePackages := TPrivatePackageList.Create([]);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesFolderPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesFolderPath);
end;

function TDPMEngine.GetProjectPackages: TDependentPackageList;
var
  DependentPackage: TDependentPackage;
  sJSON: string;
begin
  if not Assigned(FProjectPackages) then
  begin
    if TFile.Exists(GetProjectPackagesPath) then
    begin
      sJSON := TFile.ReadAllText(GetProjectPackagesPath, TEncoding.ANSI);
      FProjectPackages := TDependentPackageList.Create(sJSON);

      for DependentPackage in FProjectPackages do
        GetVersionCacheList.AddVersion(DependentPackage.ID, DependentPackage.Version);
    end
    else
      FProjectPackages := TDependentPackageList.Create;
  end;

  Result := FProjectPackages;
end;

function TDPMEngine.GetProjectPackagesPath: string;
begin
  if IsProjectOpened then
    Result := TPath.Combine(GetActiveProjectPath, cProjectPackagesPath)
  else
    Result := '';
end;

function TDPMEngine.GetTextFromFile(const aPath: string): string;
begin
  Result := TFile.ReadAllText(aPath, TEncoding.ANSI);
end;

function TDPMEngine.GetVendorsPath: string;
begin
  Result := TPath.Combine(TDirectory.GetParent(GetActiveProjectPath), 'Vendors');
end;

function TDPMEngine.GetVersionCacheList: TVersionCacheList;
begin
  if not Assigned(FVersionCacheList) then
    FVersionCacheList := TVersionCacheList.Create;

  Result := FVersionCacheList;
end;

function TDPMEngine.GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
begin
  if (not aCachedOnly) and (not AreVersionsLoaded(aPackage.ID)) then
    LoadRepoVersions(aPackage);

  Result := GetVersionCacheList.GetByPackageID(aPackage.ID);
end;

function TDPMEngine.Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
var
  Dependencies: TDependentPackageList;
  Dependency: TDependentPackage;
  DependencyInitialPackage: TInitialPackage;
  DependencyVersion: TVersion;
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  Version := DefineVersion(aInitialPackage, aVersion);
  Result := [TPackageHandle.Create(paInstall, aInitialPackage, Version)];

  Dependencies := LoadDependencies(aInitialPackage, Version);
  try
    for Dependency in Dependencies do
    begin
      DependencyInitialPackage := GetInitialPackage(Dependency);

      DependencyVersion := TVersion.Create;
      DependencyVersion.Assign(Dependency.Version);

      Result := Result + [TPackageHandle.Create(paInstall, DependencyInitialPackage, DependencyVersion)];
    end;
  finally
    Dependencies.Free;
  end;

  for PackageHandle in Result do
  begin
    DoInstall(PackageHandle.InitialPackage, PackageHandle.Version);
  end;

  SaveProjectPackages;

  FUINotifyProc('Success');
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.LoadDependencies(aPackage: TPackage; aVersion: TVersion): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
begin
  Result := TDependentPackageList.Create;

  DependentPackage := TDependentPackage.Create;
  try
    DependentPackage.Assign(aPackage);

    DoLoadDependencies(DependentPackage, aVersion, Result);
  finally
    DependentPackage.Free;
  end;
end;

function TDPMEngine.LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName,
  aError: string): Boolean;
var
  RepoURL: string;
  SHA: string;
  URLWords: TArray<string>;
begin
  Result := False;
  RepoURL := aRepoURL;
  aRepoOwner := '';
  aRepoName := '';
  aError := '';

  if RepoURL.Contains('://') then
    RepoURL := RepoURL.Substring(RepoURL.IndexOf('://') + 3, RepoURL.Length);
  URLWords := RepoURL.Split(['/']);

  if (not (Length(URLWords) >= 3)) or
   ((Length(URLWords) > 0) and (URLWords[0].ToLower <> 'github.com'))
  then
  begin
    aError := cStrTheGitHubRepositoryUrlIsInvalid;
    Exit;
  end;

  try
    SHA := FGHAPI.GetMasterBranchSHA(URLWords[1], URLWords[2]);
  except
    aError := cStrCantLoadTheRepositoryURL;
    Exit;
  end;

  if SHA.IsEmpty then
    Exit;

  Result := True;
  aRepoOwner := URLWords[1];
  aRepoName := URLWords[2];
end;

function TDPMEngine.LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
begin
  if aVersion.RepoTreeLoaded then
    Exit(aVersion.RepoTree);

  Result := FGHAPI.GetRepoTree(aPackage.RepoOwner, aPackage.RepoName,
    aVersion.SHA);

  aVersion.RepoTreeLoaded := True;
end;

procedure TDPMEngine.LoadRepoVersions(aPackage: TPackage);
var
  Tag:  TTag;
  Tags: TArray<TTag>;
  Version: TVersion;
begin
  Tags := FGHAPI.GetRepoTags(aPackage.RepoOwner, aPackage.RepoName);

  for Tag in Tags do
  begin
    Version := TVersion.Create;

    Version.Name := Tag.Name;
    Version.SHA := Tag.SHA;

    if not GetVersionCacheList.AddVersion(aPackage.ID, Version) then
      Version.Free;
  end;

  GetVersionCacheList.AddLoadedPackageID(aPackage.ID);
end;

function TDPMEngine.SaveAsPrivatePackage(aPackage: TInitialPackage): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Result := TPath.Combine(GetPrivatePackagesFolderPath, aPackage.Name + '.json');

  WriteFile(Result, Bytes);
end;

function TDPMEngine.SaveContent(const aPackagePath, aSourcePath,
  aContent: string): string;
var
  Bytes: TBytes;
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := aPackagePath;
  RepoPathParts := aSourcePath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := Result + '\' + RepoPathPart;

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  WriteFile(Result, Bytes);

  FUINotifyProc('Writing ' + Result);
end;

procedure TDPMEngine.SaveProjectPackages;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(GetProjectPackages.GetJSONString);

  WriteFile(GetProjectPackagesPath, Bytes);
end;

procedure TDPMEngine.Uninstall(aPackage: TPackage);
begin
  FUINotifyProc(Format(#13#10 + 'Uninstalling %s...', [aPackage.Name]));

  DeletePackagePath(aPackage);

  //aPackage.Version.Init;
  //GetPrivatePackages.SyncToExternal(aPackage);

  //GetProjectPackages.RemoveByID(aPackage.ID);
  SaveProjectPackages;

  FUINotifyProc('Success');
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPrivatePackage);
begin
  TFile.Delete(aPackage.FilePath);
  aPackage.FilePath := SaveAsPrivatePackage(aPackage);
end;

procedure TDPMEngine.WriteFile(const aPath: string; const aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aPath));

  FS := TFile.Create(aPath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

end.
