unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FGHAPI: TGHAPI;
    FPrivatePackages: TPackageList;
    FProjectPackages: TPackageList;
    FUINotifyProc: TUINotifyProc;
    function AddPackageFiles(aPackage: TPackage): TArray<string>;
    function DefineVersion(aPackage: TPackage; const aVersion: TVersion): TVersion;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetPackagePath(aPackage: TPackage): string;
    function GetProjectPackagesPath: string;
    function GetPrivatePackagesFolderPath: string;
    function GetVendorsPath: string;
    function IsProjectOpened: Boolean;
    function SaveContent(const aPackagePath, aSourcePath, aContent: string): string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure BuildMenu;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure FreePackageLists;
    procedure LoadRepoTree(aPackage: TPackage);
    procedure SavePackage(aPackage: TPackage);
    procedure SavePackages(aPackageList: TPackageList);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    function AllowAction(const aFrameActionType: TFrameActionType;
      aPackage: TPackage): Boolean;
    function GetPrivatePackages: TPackageList;
    function GetProjectPackages: TPackageList;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    procedure AddNewPrivatePackage(aPackage: TPackage);
    procedure InstallPackage(aPackage: TPackage; const aVersion: TVersion);
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure UpdatePrivatePackage(aPackage: TPackage);
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

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TPackage);
begin
  SavePackage(aPackage);
  GetPrivatePackages.Add(aPackage);
end;

function TDPMEngine.AddPackageFiles(aPackage: TPackage): TArray<string>;
var
  Blob: TBlob;
  NodePath: string;
  TreeNode: TTreeNode;
begin
  Result := [];

  for TreeNode in aPackage.RepoTree do
  begin
    if TreeNode.FileType <> 'blob' then
      Continue;

    if aPackage.AllowPath(TreeNode.Path) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

      NodePath := aPackage.ApplyPathMoves(TreeNode.Path);
      SaveContent(GetPackagePath(aPackage), NodePath, Blob.Content);
    end;
  end;
end;

function TDPMEngine.AllowAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage): Boolean;
begin
  Result := False;
  case aFrameActionType of
    fatInstall:
      Result := IsProjectOpened
                and aPackage.Version.IsEmpty;

    fatUninstall:
      Result := not aPackage.Version.IsEmpty;

    fatEditPackage:
      Result := aPackage.PackageSide = psInitial;
  end;
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

function TDPMEngine.DefineVersion(aPackage: TPackage; const aVersion: TVersion): TVersion;
begin
  if not aVersion.SHA.IsEmpty then
    Exit(aVersion);

  if aVersion.Name = cStrLatestVersionOrCommit then
  begin
    LoadRepoVersions(aPackage);
    if Length(aPackage.Versions) > 0 then
      Exit(aPackage.Versions[0]);
  end;

  Result.Name := '';
  Result.SHA := FGHAPI.GetMasterBranchSHA(aPackage.RepoOwner, aPackage.RepoName);
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;
  FreePackageLists;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
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

function TDPMEngine.GetPrivatePackages: TPackageList;
var
  FileArr: TArray<string>;
  FileItem: string;
  Package: TPackage;
  PackageFileData: TPackageFileData;
  PackageFileDataArr: TArray<TPackageFileData>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesFolderPath) then
    begin
      FileArr := TDirectory.GetFiles(GetPrivatePackagesFolderPath, '*.json');
      PackageFileDataArr := [];
      for FileItem in FileArr do
      begin
        PackageFileData.FilePath := FileItem;
        PackageFileData.JSONString := TFile.ReadAllText(FileItem, TEncoding.ANSI);

        PackageFileDataArr := PackageFileDataArr + [PackageFileData];
      end;

      if Length(PackageFileDataArr) > 0 then
        FPrivatePackages := TPackageList.Create(PackageFileDataArr);

      for Package in FPrivatePackages do
        GetProjectPackages.SyncToExternal(Package);
    end;
  end;

  if FPrivatePackages = nil then
    FPrivatePackages := TPackageList.Create(True);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesFolderPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesFolderPath);
end;

function TDPMEngine.GetProjectPackages: TPackageList;
var
  sJSON: string;
begin
  if not Assigned(FProjectPackages) then
  begin
    if TFile.Exists(GetProjectPackagesPath) then
    begin
      sJSON := TFile.ReadAllText(GetProjectPackagesPath, TEncoding.ANSI);
      FProjectPackages := TPackageList.Create(sJSON);
    end
    else
      FProjectPackages := TPackageList.Create;
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

function TDPMEngine.GetVendorsPath: string;
begin
  Result := TPath.Combine(TDirectory.GetParent(GetActiveProjectPath), 'Vendors');
end;

procedure TDPMEngine.InstallPackage(aPackage: TPackage; const aVersion: TVersion);
var
  Version: TVersion;
begin
  FUINotifyProc(Format(#13#10 + 'Installing %s...', [aPackage.Name]));

  Version := DefineVersion(aPackage, aVersion);
  aPackage.Version := Version;
  LoadRepoTree(aPackage);

  AddPackageFiles(aPackage);
  GetProjectPackages.Add(TPackage.Create(aPackage));
  SavePackages(GetProjectPackages);

  FUINotifyProc('Success');
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
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

procedure TDPMEngine.LoadRepoTree(aPackage: TPackage);
begin
  aPackage.RepoTree := FGHAPI.GetRepoTree(aPackage.RepoOwner, aPackage.RepoName,
    aPackage.Version.SHA);
end;

procedure TDPMEngine.LoadRepoVersions(aPackage: TPackage);
var
  Tag:  TTag;
  Tags: TArray<TTag>;
  Version: TVersion;
begin
  if aPackage.AreVersionsLoaded then
    Exit;

  Tags := FGHAPI.GetRepoTags(aPackage.RepoOwner, aPackage.RepoName);

  for Tag in Tags do
  begin
    Version.Name := Tag.Name;
    Version.SHA := Tag.SHA;

    aPackage.AddVersion(Version);
  end;

  aPackage.AreVersionsLoaded := True;
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

procedure TDPMEngine.SavePackage(aPackage: TPackage);
var
  Bytes: TBytes;
  Path: string;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Path := TPath.Combine(GetPrivatePackagesFolderPath, aPackage.Name + '.json');

  WriteFile(Path, Bytes);
  aPackage.FilePath := Path;
end;

procedure TDPMEngine.SavePackages(aPackageList: TPackageList);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackageList.GetJSONString);

  WriteFile(GetProjectPackagesPath, Bytes);
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPackage);
begin
  TFile.Delete(aPackage.FilePath);
  SavePackage(aPackage);
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
