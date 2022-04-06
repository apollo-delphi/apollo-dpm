unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  Apollo_DPM_Settings,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.SysUtils,
  ToolsAPI, {must be used in this unit only}
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FAreActionsLocked: Boolean;
    FGHAPI: TGHAPI;
    FIDEPackages: TDependentPackageList;
    FPrivatePackages: TPrivatePackageList;
    FSettings: TSettings;
    FUIActionsLockProc: TUIActionsLockProc;
    FUIActionsUnlockProc: TUIActionsUnlockProc;
    FUIGetFolderFunc: TUIGetFolderFunc;
    FUINotifyProc: TUINotifyProc;
    FVersionCacheList: TVersionCacheList;
    function GetApolloMenuItem: TMenuItem;
    function GetDependentPackage(aPackage: TPackage): TDependentPackage;
    function GetIDEMainMenu: TMainMenu;
    function GetPrivatePackagesFolderPath: string;
    function GetSettingsPath: string;
    function GetVersionCacheList: TVersionCacheList;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function SaveAsPrivatePackage(aPackage: TInitialPackage): string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure ApplySettings;
    procedure BuildMenu;
    procedure DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
      aResult: TDependentPackageList); overload;
    procedure DPMClosed;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure DPMOpened;
    procedure FreeVersionCacheList;
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure LockActions;
    procedure SavePackageList(const aPath: string; aPackageList: TDependentPackageList);
    procedure UnlockActions;
    function GetProjectGroup: IOTAProjectGroup;
  public
    function AreVersionsLoaded(const aPackageID: string): Boolean; //move to private
    function AllowAction(const aFrameActionType: TFrameActionType;
      aPackage: TPackage; aVersion: TVersion): Boolean;
    function DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
    function GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    function LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
    function ShowConflictForm(const aCaption: string; aVersionConflicts: TVersionConflicts): TVersionConflicts;
    procedure AddNewPrivatePackage(aPackage: TInitialPackage);
    procedure ApplyAndSaveSettings;
    procedure OpenProject(const aProjectPath: string);
    procedure ShowFirstModule;
    procedure UpdatePrivatePackage(aPackage: TPrivatePackage);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
    constructor Create;
    destructor Destroy; override;
    property GetFolder: TUIGetFolderFunc read FUIGetFolderFunc;
    property GHAPI: TGHAPI read FGHAPI;
    property Settings: TSettings read FSettings;
    procedure AddFileToActiveProject(const aFilePath: string);
    procedure ResetDependentPackage(aDependentPackage: TDependentPackage);
    procedure SaveActiveProject;
    procedure SavePackages;
    property AreActionsLocked: Boolean read FAreActionsLocked;

  private
    FProjectPackages: TDependentPackageList;
    FTestMode: Boolean;
    function Packages_GetDependentPackageList(var aPackageList: TDependentPackageList; const aPackageListPath: string): TDependentPackageList;
    function Path_GetIDEPackages: string;
    procedure FreePackageLists;
  public
    function Action_Add(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
    function Action_Install(aPackage: TPackage): TPackageHandles;
    function Action_Uninstall(aPackage: TPackage): TPackageHandles;
    function Action_Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
    function Bpl_Install(const aBplPath: string): Boolean;
    function Bpl_IsInstalled(const aBplPath: string): Boolean;
    function Bpl_Uninstall(const aBplPath: string): Boolean;
    function Console_Run(const aCommand: string): string;
    function Directory_Delete(const aPath: string): Boolean;
    function Directory_DeleteIfEmpty(const aPath: string): Boolean;
    function Directory_Exists(const aPath: string): Boolean;
    function Files_Get(const aDirectoryPath, aNamePattern: string): TArray<string>;
    function File_Delete(const aPath: string): Boolean;
    function File_Exists(const aPath: string): Boolean;
    function File_GetExtension(const aPath: string): string;
    function File_GetName(const aPath: string): string;
    function File_GetText(const aPath: string): string;
    function File_Move(const aSource, aDestination: string): Boolean;
    function Packages_AddCopyToIDE(aDependentPackage: TDependentPackage): TDependentPackageList;
    function Packages_GetIDE: TDependentPackageList;
    function Packages_GetPrivate: TPrivatePackageList;
    function Packages_GetProject: TDependentPackageList;
    function Package_FindInitial(const aPackageID: string): TInitialPackage;
    function Package_LoadDependencies(aDependentPackage: TDependentPackage): TDependentPackageList; overload;
    function Package_LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList; overload;
    function Path_Combine(const aPath1, aPath2: string): string;
    function Path_GetActiveProject: string;
    function Path_GetEnviroment(const aVarName: string): string;
    function Path_GetPackage(aPackage: TPackage): string;
    function Path_GetProjectPackages: string;
    function Path_GetVendors(const aPackageType: TPackageType): string;
    function ProjectActive_Contains(const aFilePath: string): Boolean;
    function ProjectActive_RemoveFile(const aFilePath: string): IOTAProject;
    function Project_GetActive: IOTAProject;
    function Project_GetDPM(const aMayReturnNil: Boolean = False): IOTAProject;
    function Project_GetTest: IOTAProject;
    function Project_IsOpened: Boolean;
    function Project_SetActive(aProject: IOTAProject): IOTAProject;
    function Versions_SyncCache(const aPackageID: string; aVersion: TVersion; const aLoadedFromRepo: Boolean): TVersion;
    property NotifyUI: TUINotifyProc read FUINotifyProc;
    property TestMode: Boolean read FTestMode write FTestMode;
  end;

implementation

uses
  Apollo_DPM_Actions,
  Apollo_DPM_ConflictForm,
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Pipes,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils, {must be used in this unit only}
  System.NetEncoding,
  System.Types,
  Vcl.Controls;

{ TDPMEngine }

function TDPMEngine.ProjectActive_Contains(const aFilePath: string): Boolean;
begin
  Result := GetActiveProject.FindModuleInfo(aFilePath) <> nil;
end;

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

  Package := TPrivatePackage.Create(File_GetText(Path));
  Package.FilePath := Path;

  Packages_GetPrivate.Add(Package);
end;

procedure TDPMEngine.AddFileToActiveProject(const aFilePath: string);
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.AddFile(aFilePath, True);
    end
  );
end;

function TDPMEngine.AllowAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion): Boolean;
var
  DependentPackage: TDependentPackage;
  InitialPackage: TInitialPackage;
begin
  Result := False;

  if aPackage is TInitialPackage then
  begin
    InitialPackage := aPackage as TInitialPackage;

    case aFrameActionType of
      fatAdd:
        Result := TAdd.GetClass(InitialPackage.PackageType).Allowed(Self, InitialPackage, aVersion);

      fatUpdate:
        Result := TUpdate.GetClass(InitialPackage.PackageType).Allowed(Self, InitialPackage.DependentPackage, aVersion);

      fatUninstall:
        Result := TUninstall.GetClass(InitialPackage.PackageType).Allowed(Self, InitialPackage.DependentPackage, aVersion);

      fatInstall:
        Result := False;

      fatEditPackage:
        Result := True;
    end;
  end
  else
  if aPackage is TDependentPackage then
  begin
    DependentPackage := aPackage as TDependentPackage;

    case aFrameActionType of
      fatAdd:
        Result := False;

      fatUpdate:
        Result := TUpdate.GetClass(DependentPackage.PackageType).Allowed(Self, DependentPackage, aVersion);

      fatUninstall:
        Result := TUninstall.GetClass(DependentPackage.PackageType).Allowed(Self, DependentPackage, aVersion);

      fatInstall:
        Result := TInstall.GetClass(DependentPackage.PackageType).Allowed(DependentPackage);

      fatEditPackage:
        Result := False;
    end;
  end;
end;

function TDPMEngine.AreVersionsLoaded(const aPackageID: string): Boolean;
begin
  Result := GetVersionCacheList.ContainsLoadedPackageID(aPackageID);
end;

procedure TDPMEngine.OpenProject(const aProjectPath: string);
var
  ModuleServices: IOTAModuleServices;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  ModuleServices.OpenModule(aProjectPath);
end;

function TDPMEngine.Bpl_Install(const aBplPath: string): Boolean;
var
  PackageServices: IOTAPackageServices;
begin
  TThread.Synchronize(nil, procedure
    begin
      PackageServices := BorlandIDEServices as IOTAPackageServices;
      try
        PackageServices.InstallPackage(aBplPath);
      except
        on E: Exception do
        begin
          if E.Message.Contains(cStrNotDesignTimePackage) then
            NotifyUI(Format('%s is not design time package, continue..', [File_GetName(aBplPath)]))
          else
            raise;
        end;
      end;
    end
  );
  Result := True;
end;

function TDPMEngine.Bpl_IsInstalled(const aBplPath: string): Boolean;
var
  i: Integer;
  PackageServices: IOTAPackageServices;
begin
  Result := False;

  PackageServices := BorlandIDEServices as IOTAPackageServices;
  for i := 0 to PackageServices.PackageCount - 1 do
    if PackageServices.Package[i].FileName = aBplPath then
      Exit(True);
end;

function TDPMEngine.Bpl_Uninstall(const aBplPath: string): Boolean;
var
  PackageServices: IOTAPackageServices;
begin
  TThread.Synchronize(nil, procedure
    begin
      PackageServices := BorlandIDEServices as IOTAPackageServices;
      PackageServices.UninstallPackage(aBplPath);
    end
  );
  Result := True;
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

function TDPMEngine.Project_GetTest: IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
  i: Integer;
begin
  ProjectGroup := GetProjectGroup;

  for i := 0 to ProjectGroup.ProjectCount - 1 do
    if ProjectGroup.Projects[i].FileName.EndsWith('DPMTestProject.dproj') then
      Exit(ProjectGroup.Projects[i]);

  raise Exception.Create('Test project DPMTestProject.dproj is not in the project group!');
end;

function TDPMEngine.DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
var
  Versions: TArray<TVersion>;
begin
  if not aVersion.SHA.IsEmpty then
    Exit(aVersion);

  Versions := GetVersions(aPackage);
  if Length(Versions) > 0 then
    Exit(Versions[0])
  else
    raise Exception.Create('No versions was found!');
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;
  FreeVersionCacheList;
  DPMClosed;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

function TDPMEngine.Directory_Delete(const aPath: string): Boolean;
begin
  TDirectory.Delete(aPath, True);
  Result := True;
end;

function TDPMEngine.Directory_DeleteIfEmpty(const aPath: string): Boolean;
begin
  Result := False;
  if (Length(TDirectory.GetDirectories(aPath, '*', TSearchOption.soTopDirectoryOnly)) = 0) and
     (Length(Files_Get(aPath, '*')) = 0)
  then
  begin
    TDirectory.Delete(aPath);
    Result := True;
  end;
end;

function TDPMEngine.Directory_Exists(const aPath: string): Boolean;
begin
  Result := TDirectory.Exists(aPath);
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
  aVersion.RepoTree := LoadRepoTree(aDependentPackage, aVersion);
  aVersion.Dependencies := [];

  for TreeNode in aVersion.RepoTree do
    if TreeNode.Path.EndsWith(cPathProjectPackages) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);
      sJSON := TNetEncoding.Base64.Decode(Blob.Content);

      PackageList := TDependentPackageList.Create(sJSON, Versions_SyncCache);
      try
        for i := PackageList.Count - 1 downto 0 do
        begin
          aVersion.Dependencies := aVersion.Dependencies + [PackageList[i].ID];

          if PackageList[i].IsDirect then
          begin
            Package := PackageList.ExtractAt(i);
            aResult.Add(Package);

            DoLoadDependencies(Package, Package.Version, aResult);
          end;
        end;
      finally
        PackageList.Free;
      end;
    end;
end;

procedure TDPMEngine.DPMClosed;
begin
  FreePackageLists;

  if Assigned(FSettings) then
    FreeAndNil(FSettings);
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    DPMOpened;
    FUIActionsLockProc := DPMForm.LockActions;
    FUIActionsUnlockProc := DPMForm.UnlockActions;
    FUINotifyProc := DPMForm.NotifyObserver;
    FUIGetFolderFunc := DPMForm.GetFolder;
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
    DPMClosed;
  end;
end;

procedure TDPMEngine.DPMOpened;
begin
  if TFile.Exists(GetSettingsPath) then
    FSettings := TSettings.Create(File_GetText(GetSettingsPath))
  else
    FSettings := TSettings.Create;

  ApplySettings;
end;

procedure TDPMEngine.FreePackageLists;
begin
  if Assigned(FPrivatePackages) then
    FreeAndNil(FPrivatePackages);
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);
  if Assigned(FIDEPackages) then
    FreeAndNil(FIDEPackages);
end;

procedure TDPMEngine.FreeVersionCacheList;
begin
  if Assigned(FVersionCacheList) then
    FreeAndNil(FVersionCacheList);
end;

function TDPMEngine.Project_GetActive: IOTAProject;
begin
  Result := GetActiveProject;
end;

function TDPMEngine.Path_Combine(const aPath1, aPath2: string): string;
begin
  Result := TPath.Combine(aPath1, aPath2);
end;

function TDPMEngine.Path_GetActiveProject: string;
begin
  Result := TDirectory.GetParent(GetActiveProject.FileName);
end;

function TDPMEngine.Path_GetEnviroment(const aVarName: string): string;
begin
  Result := (BorlandIDEServices as IOTAServices).ExpandRootMacro(aVarName);
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

function TDPMEngine.GetDependentPackage(aPackage: TPackage): TDependentPackage;
begin
  if aPackage is TDependentPackage then
    Result := aPackage as TDependentPackage
  else
  if aPackage is TInitialPackage then
    Result := (aPackage as TInitialPackage).DependentPackage
  else
    raise Exception.Create('unknown package type');
end;

function TDPMEngine.Project_GetDPM(const aMayReturnNil: Boolean = False): IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
  i: Integer;
begin
  ProjectGroup := GetProjectGroup;

  if Assigned(ProjectGroup) then
    for i := 0 to ProjectGroup.ProjectCount - 1 do
      if ProjectGroup.Projects[i].FileName.EndsWith('Apollo_DPM.dproj') then
        Exit(ProjectGroup.Projects[i]);

  if aMayReturnNil then
    Result := nil
  else
    raise Exception.Create('Project Apollo_DPM.dproj is not in the project group!');
end;

function TDPMEngine.Files_Get(const aDirectoryPath, aNamePattern: string): TArray<string>;
var
  Files: TStringDynArray;
  i: Integer;
begin
  Files := TDirectory.GetFiles(aDirectoryPath, aNamePattern, TSearchOption.soAllDirectories);
  Result := [];
  for i := 0 to Length(Files) - 1 do
    Result := Result + [Files[i]];
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.Path_GetIDEPackages: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathIDEPackages);
end;

function TDPMEngine.Path_GetPackage(aPackage: TPackage): string;
begin
  Result := TPath.Combine(Path_GetVendors(aPackage.PackageType), aPackage.Name);
end;

function TDPMEngine.Packages_AddCopyToIDE(
  aDependentPackage: TDependentPackage): TDependentPackageList;
begin
  Packages_GetIDE.Add(TDependentPackage.Create(aDependentPackage.GetJSONString,
    Versions_SyncCache));

  Result := Packages_GetIDE;
end;

function TDPMEngine.Packages_GetDependentPackageList(var aPackageList: TDependentPackageList;
  const aPackageListPath: string): TDependentPackageList;
var
  Package: TDependentPackage;
  PackagePath: string;
  sJSON: string;
begin
  if not Assigned(aPackageList) then
  begin
    if TFile.Exists(aPackageListPath) then
    begin
      sJSON := TFile.ReadAllText(aPackageListPath, TEncoding.ANSI);
      aPackageList := TDependentPackageList.Create(sJSON, Versions_SyncCache);

      for Package in aPackageList do
      begin
        PackagePath := Path_GetPackage(Package);
        if Directory_Exists(PackagePath) then
          Package.Installed := True
        else
          Package.Installed := False;
      end;
    end
    else
      aPackageList := TDependentPackageList.Create;
  end;

  Result := aPackageList;
end;

function TDPMEngine.Packages_GetIDE: TDependentPackageList;
begin
  Result := Packages_GetDependentPackageList(FIDEPackages, Path_GetIDEPackages);
end;

function TDPMEngine.Packages_GetPrivate: TPrivatePackageList;
var
  FileArr: TArray<string>;
  FileItem: string;
  PrivatePackageFile: TPrivatePackageFile;
  PrivatePackageFiles: TArray<TPrivatePackageFile>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesFolderPath) then
    begin
      FileArr := Files_Get(GetPrivatePackagesFolderPath, '*.json');
      PrivatePackageFiles := [];
      for FileItem in FileArr do
      begin
        PrivatePackageFile.Path := FileItem;
        PrivatePackageFile.JSONString := File_GetText(FileItem);

        PrivatePackageFiles := PrivatePackageFiles + [PrivatePackageFile];
      end;

      if Length(PrivatePackageFiles) > 0 then
        FPrivatePackages := TPrivatePackageList.Create(PrivatePackageFiles);

      FPrivatePackages.SetDependentPackageRef(Packages_GetProject);
      FPrivatePackages.SetDependentPackageRef(Packages_GetIDE);
    end;
  end;

  if not Assigned(FPrivatePackages) then
    FPrivatePackages := TPrivatePackageList.Create([]);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesFolderPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathPrivatePackagesFolder);
end;

function TDPMEngine.GetProjectGroup: IOTAProjectGroup;
var
  ModuleServices: IOTAModuleServices;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Result := ModuleServices.MainProjectGroup;
end;

function TDPMEngine.Packages_GetProject: TDependentPackageList;
begin
  Result := Packages_GetDependentPackageList(FProjectPackages, Path_GetProjectPackages);
end;

function TDPMEngine.Path_GetProjectPackages: string;
begin
  if Project_IsOpened then
    Result := TPath.Combine(Path_GetActiveProject, cPathProjectPackages)
  else
    Result := '';
end;

function TDPMEngine.GetSettingsPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathSettings);
end;

function TDPMEngine.File_Delete(const aPath: string): Boolean;
begin
  TFile.Delete(aPath);
  Result := True;
end;

function TDPMEngine.File_Exists(const aPath: string): Boolean;
begin
  Result := TFile.Exists(aPath);
end;

function TDPMEngine.File_GetExtension(const aPath: string): string;
begin
  Result := TPath.GetExtension(aPath);
end;

function TDPMEngine.File_GetName(const aPath: string): string;
begin
  Result := TPath.GetFileName(aPath);
end;

function TDPMEngine.File_GetText(const aPath: string): string;
begin
  Result := TFile.ReadAllText(aPath, TEncoding.ANSI);
end;

function TDPMEngine.File_Move(const aSource, aDestination: string): Boolean;
begin
  TFile.Move(aSource, aDestination);
  Result := True;
end;

function TDPMEngine.Path_GetVendors(const aPackageType: TPackageType): string;
begin
  case aPackageType of
    ptCodeSource:
      begin
        if not Project_IsOpened then
          raise Exception.Create('TDPMEngine.Path_GetVendors: ptCodeSource must have opened project!');

        Result := TPath.Combine(TDirectory.GetParent(Path_GetActiveProject), cPathProjectVendorsFolder);
      end;
    ptBplSource, ptBplBinary: Result := TPath.Combine(TPath.GetPublicPath, cPathBplVendorsFolder);
  else
    raise Exception.Create('TDPMEngine.Path_GetVendors: Path is not specified for this package type!');
  end;
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

function TDPMEngine.Action_Add(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
var
  Action: TAdd;
begin
  LockActions;
  Action := TAdd.GetClass(aInitialPackage.PackageType).Create(Self, aInitialPackage, aVersion);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

function TDPMEngine.Project_IsOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.Package_FindInitial(const aPackageID: string): TInitialPackage;
begin
  Result := Packages_GetPrivate.GetByID(aPackageID);

  if Assigned(Result) then
    Exit(Result);
end;

function TDPMEngine.Package_LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
begin
  Result := TDependentPackageList.Create;

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage, False);
  try
    DoLoadDependencies(DependentPackage, aVersion, Result);
  finally
    FreeAndNil(DependentPackage);
  end;
end;

function TDPMEngine.Package_LoadDependencies(
  aDependentPackage: TDependentPackage): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
  ID: string;
begin
  Result := TDependentPackageList.Create(False);

  for ID in aDependentPackage.Version.Dependencies do
  begin
    DependentPackage := Packages_GetProject.GetByID(ID);

    if Assigned(DependentPackage) then
      Result.Add(DependentPackage);
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
    SHA := FGHAPI.GetMasterBranch(URLWords[1], URLWords[2]).SHA;
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

  procedure CreateVersion(const aTag: TTag);
  var
    Version: TVersion;
  begin
    Version := TVersion.Create;
    Version.Assign(aTag);

    Versions_SyncCache(aPackage.ID, Version, True{aLoadedFromRepo});
  end;

var
  Tag:  TTag;
  Tags: TArray<TTag>;
begin
  Tags := FGHAPI.GetRepoTags(aPackage.RepoOwner, aPackage.RepoName);

  for Tag in Tags do
    CreateVersion(Tag);

  Tag := FGHAPI.GetMasterBranch(aPackage.RepoOwner, aPackage.RepoName);
  CreateVersion(Tag);
end;

procedure TDPMEngine.LockActions;
begin
  FAreActionsLocked := True;
  FUIActionsLockProc;
end;

function TDPMEngine.ProjectActive_RemoveFile(const aFilePath: string): IOTAProject;
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.RemoveFile(aFilePath);
    end
  );
  Result := GetActiveProject;
end;

function TDPMEngine.RepoPathToFilePath(const aRepoPath: string): string;
var
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := '';
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := TPath.Combine(Result, RepoPathPart);
end;

procedure TDPMEngine.ResetDependentPackage(
  aDependentPackage: TDependentPackage);
var
  InitialPackage: TInitialPackage;
begin
  InitialPackage := Package_FindInitial(aDependentPackage.ID);
  if Assigned(InitialPackage) then
    InitialPackage.DependentPackage := nil;
end;

function TDPMEngine.Console_Run(const aCommand: string): string;
begin
  try
    Result := RunCommandPrompt(aCommand);
  except
    on E: Exception do
      raise Exception.CreateFmt('RunConsole: %s '#13#10'%s', [aCommand, E.Message]);
  end;
end;

procedure TDPMEngine.SaveActiveProject;
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.Save(False, True);
    end
  );
end;

function TDPMEngine.SaveAsPrivatePackage(aPackage: TInitialPackage): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Result := TPath.Combine(GetPrivatePackagesFolderPath, aPackage.Name + '.json');

  WriteFile(Result, Bytes);
end;

function TDPMEngine.SaveContent(const aPackagePath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
begin
  Result := TPath.Combine(aPackagePath, RepoPathToFilePath(aRepoPath));
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  WriteFile(Result, Bytes);

  FUINotifyProc('writing ' + Result);
end;

procedure TDPMEngine.SavePackageList(const aPath: string;
  aPackageList: TDependentPackageList);
var
  Bytes: TBytes;
begin
  if (aPackageList.Count = 0) and TFile.Exists(aPath) then
    TFile.Delete(aPath)
  else
  begin
    Bytes := TEncoding.ANSI.GetBytes(aPackageList.GetJSONString);
    WriteFile(aPath, Bytes);
  end;
end;

procedure TDPMEngine.SavePackages;
begin
  if Project_IsOpened then
    SavePackageList(Path_GetProjectPackages, Packages_GetProject);

  SavePackageList(Path_GetIDEPackages, Packages_GetIDE);
end;

function TDPMEngine.Project_SetActive(aProject: IOTAProject): IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
begin
  ProjectGroup := GetProjectGroup;

  if ProjectGroup.ActiveProject <> aProject then
  begin
    ProjectGroup.SetActiveProject(aProject);
    FreePackageLists;
  end;

  Result := aProject;
end;

procedure TDPMEngine.ApplyAndSaveSettings;
var
  Bytes: TBytes;
begin
  ApplySettings;

  Bytes := TEncoding.ANSI.GetBytes(FSettings.GetJSONString);
  WriteFile(GetSettingsPath, Bytes);
end;

procedure TDPMEngine.ApplySettings;
begin
  FGHAPI.SetGHPAToken(FSettings.GHPAToken);
end;

function TDPMEngine.ShowConflictForm(const aCaption: string;
  aVersionConflicts: TVersionConflicts): TVersionConflicts;
var
  ConflictForm: TConflictForm;
begin
  Result := [];

  ConflictForm := TConflictForm.Create(aCaption, DPMForm, aVersionConflicts);
  try
    if ConflictForm.ShowModal = mrOK then
      Result := ConflictForm.GetResult
    else
      Abort;
  finally
    ConflictForm.Free;
  end;
end;

procedure TDPMEngine.ShowFirstModule;
var
  i: Integer;
  ProjectModuleInfo: IOTAModuleInfo;
begin
  for i := 0 to GetActiveProject.GetModuleCount - 1 do
  begin
    ProjectModuleInfo := GetActiveProject.GetModule(i) as IOTAModuleInfo;
    if TPath.GetExtension(ProjectModuleInfo.FileName).ToLower = '.pas' then
      begin
        ProjectModuleInfo.OpenModule.Show;
        Break;
      end;
  end;
end;

function TDPMEngine.Action_Install(aPackage: TPackage): TPackageHandles;
var
  Action: TInstall;
  DependentPackage: TDependentPackage;
begin
  LockActions;
  DependentPackage := GetDependentPackage(aPackage);
  Action := TInstall.GetClass(aPackage.PackageType).Create(Self, DependentPackage);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

function TDPMEngine.Action_Uninstall(aPackage: TPackage): TPackageHandles;
var
  Action: TUninstall;
  DependentPackage: TDependentPackage;
begin
  LockActions;
  DependentPackage := GetDependentPackage(aPackage);
  Action := TUninstall.GetClass(DependentPackage.PackageType).Create(Self, DependentPackage);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

procedure TDPMEngine.UnlockActions;
begin
  FUIActionsUnlockProc;
  FAreActionsLocked := False;
end;

function TDPMEngine.Action_Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
var
  Action: TUpdate;
  DependentPackage: TDependentPackage;
begin
  LockActions;
  DependentPackage := GetDependentPackage(aPackage);
  Action := TUpdate.GetClass(DependentPackage.PackageType).Create(Self, DependentPackage, aVersion);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPrivatePackage);
begin
  TFile.Delete(aPackage.FilePath);
  aPackage.FilePath := SaveAsPrivatePackage(aPackage);
end;

function TDPMEngine.Versions_SyncCache(const aPackageID: string; aVersion: TVersion;
  const aLoadedFromRepo: Boolean): TVersion;
begin
  Result := GetVersionCacheList.SyncVersion(aPackageID, aVersion, aLoadedFromRepo);
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
